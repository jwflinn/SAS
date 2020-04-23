/* ************** */
/* Accessing Data */
/* ************** */
%let path=~/ECRB94/data;
libname tsa "&path";

options VALIDVARNAME=V7;
proc import datafile="&path/TSAClaims2002_2017.csv" out=tsa.claims DBMS=CSV replace;
	guessingrows=max;
run;

/* ************** */
/* Exploring Data */
/* ************** */
proc print data=tsa.claims(obs=20);
run;

proc contents data=tsa.claims varnum;
run;

proc freq data=tsa.claims;
	table Claim_Type Claim_Site Disposition Date_Received Incident_Date;
	format Date_Received Incident_Date year4.;
run;

proc print data=tsa.claims;
	where Date_Received<Incident_Date;
	format Date_Received Incident_Date date9.;
run;

/* ************** */
/* Preparing Data */
/* ************** */
proc sort data=tsa.claims
	out=tsa.claimsNodup noduprecs;
	by _all_;
run;

proc sort data=tsa.claimsNodup;
	by Incident_Date;
run;

data tsa.claims_cleaned;
	set tsa.claimsNodup;
	
	if Claim_Type in (" ", "-") then Claim_Type='Unknown';
	else  Claim_Type=scan(Claim_Type, 1, '/');
	
	if Claim_Site in (" ", "-") then Claim_Site='Unknown';
	
	if Disposition in (" ", "-") then Disposition='Unknown';
	else if Disposition='Closed: Canceled' then Disposition='Closed:Canceled';
	else if Disposition='losed: Contractor Claim' then Disposition='Closed:Contractor Claim';
	
	StateName=propcase(StateName);
	State=upcase(State);
	
	if (Incident_Date=. or Date_Received=. or 
		year(Incident_Date)<2002 or year(Incident_Date)>2017 or
		year(Date_Received)<2002 or year(Date_Received)>2017 or
		Incident_Date>Date_Received) then Date_Issues='Need Review';
	
	drop County City;
	format Close_Amount dollar12.2 Date_Received Incident_Date date9.;
	label Claim_Number="Claim Number"
		  Date_Received="Date Received"	
		  Incident_Date="Incident Date"
		  Airport_Code="Airport Code"
		  Airport_Name="Airport Name"
		  Claim_Type="Claim Type"
		  Claim_Site="Claim Site"
		  Item_Category="Item Category"
		  Close_Amount="Close Amount";
run;

/* ************************** */
/* Analyze Data & Export Data */
/* ************************** */

%let outpath=~/ECRB94/output;
ods pdf file="&outpath/ClaimReports.pdf" style=Sapphire pdftoc=1;
ods noproctitle;

/* Overall Analysis */
/* 1. How many date issues are in the overall data? */
ods proclabel "Overall Date Issues";
title "Overall Date Issues in the Data";
proc freq data=tsa.claims_cleaned;
	table Date_Issues/nopercent nocum missing;
run;
title;

/* 2. How many claims per year of Incident_Date are in the overall data? Be sure to include a plot. */
ods graphics on;
ods proclabel "Overall Claims by Year";
title "Overall Claims by Year";
proc freq data=tsa.claims_cleaned;
	table Incident_Date/nocum nopercent plots=freqplot;
	format Incident_Date year4.;
	where Date_Issues is missing;
run;
title;
ods graphics off;

/* State Analysis */
%let StateN=Hawaii;

/* 1. What are the frequency value of each claim_type, claim_site, and disposition for the selected state? */
ods proclabel "&StateN Claims Overview";
title "&StateN Claim Types, Claim Sites and Disposition";
proc freq data=tsa.claims_cleaned order=freq;
	table Claim_Type Claim_Site Disposition/nocum nopercent;
	where StateName="&StateN" and Date_Issues is missing;
run;
title;

/* 2. What is the mean min max and sum of close_amount for the selected state, rounded to the nearest integer */
ods proclabel "&StateN Close Amount Statistics";
title "Close Amount Statistics for &StateN";
proc means data=tsa.claims_cleaned mean min max sum maxdec=0;
	var Close_Amount;
	where StateName="&StateN" and Date_Issues is missing;
run;
title;

ods pdf close;



