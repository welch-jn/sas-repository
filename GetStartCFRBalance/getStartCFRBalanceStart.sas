%put Begin Get_StartCFR_Balance;

/* -------------------------------------------------------------------- */
/* Get the SAS server host/server name and set variables that are       */
/* dependent on what server we are running on. This can help to make    */
/* transitons (like for upgrades) easier.                               */
/* -------------------------------------------------------------------- */
%let COEenv=Dvlp;
%let HomeSubDir=PandC;
%let HomeSubDir2=Lending\GetStartCFRBalance;

%macro _get_sas_server;
	/* These variables will be set globally by this macro */
	%global SASServer;
	%global HomePath;
	%global PgmsPath;

	/* get the server name from the system environment variable */
	%let SASServer = %sysget(computername);
	%PUT SASServer=&SASServer.;

	/* Depending on which server we are running on, set other variables accordingly */
/*	%if "&SASServer." = "VABSASAPPM04" %then %do;*/
	%if "&SASServer." = "VMPSASAPPP04" %then %do;
		/* This is the 'old' server */
		%PUT This is the 'old' SAS server;
/*	    %let SASServer = VMPSASAPPP03;*/
		%let HomePath=\\&SASServer.\ssas\ActuarialCOE\&COEenv.;
		%let PgmsPath=\\&SASServer.\eJobtracCustOps\programs;
	%end;

	%else %do;
		/* This is the new server */
		%PUT This is the 'new' SAS server;
		%let HomePath=\\&SASServer.\ssas\ActuarialCOE\&COEenv.;
		%let PgmsPath=\\&SASServer.\eJobtracCustOps\programs;
	%end;

	/* Show the results of the variables we defined */
	%PUT HomePath=&HomePath.;
	%PUT PgmsPath=&PgmsPath.;

%mend _get_sas_server;
/* -------------------------------------------------------------------- */
/* Run the macro                                                        */
/* -------------------------------------------------------------------- */
%_get_sas_server;

%INCLUDE "&HomePath.\Programs\Common\SAS_Start.sas";
%INCLUDE "&HomePath.\Programs\Common\SF_Connection.sas";
%INCLUDE "&PgmsPath.\..\Common\DB2_Connection.sas";
/*%INCLUDE "&HomePath.\Programs\Common\DB2_Connection.sas";*/

/*proc pwencode in="xxx";*/
/*run; */

libname IGrp db2 database=dsnp_r
user="&db2user." pass="&db2pass." 
schema= WHSEINTG;

libname IGrp2 db2 database=dsnp_r
user="&db2user." pass="&db2pass." 
schema= WHSE;


/*****************     Other parameters, substitute your own    *************************/
%INCLUDE "&HomePath.\Programs\&HomeSubDir.\&HomeSubDir2.\getStartCFRBalanceMain.sas";


%put End Get_StartCFR_Balance.sas;