/* -------------------------------------------------------------------- */
/* Create Snowflake library                                             */
/* -------------------------------------------------------------------- */
%MakeSFLib(snow,B_CMG_WELCHJ_DB,CI_DP_ERP,R-APP-B-WELCHJ,,,,Load);


/* -------------------------------------------------------------------- */
/* Get CFR balances                                                     */
/* -------------------------------------------------------------------- */
PROC SQL;
	CREATE TABLE WORK.CFRandDCFandPCFBalances as
		SELECT 
			put(&SasDateCurr.,yyq.) as AcctgYearQtr,
/*			'2017Q1',*/
			CUST_CONTR_NR, 
			SETL_PROG_CUST_NM, 
/*			AGREEMENT_PLAN_NR,*/
			AGREEMENT_SETL_NR,
			Sum(DCF_NO_BEG_BAL_AT) AS DCF_NoPayUp, 
			Sum(DCF_PAY_BEG_BAL_AT) AS DCF_PayUp, 
			Sum(PCF_BEG_BAL_AT) AS PCF_Balance, 
			Sum(CFR_BEG_BAL_AT) AS CFR_Balance, 
			RFRSH_DT
		FROM 
		IGRP.SETTLEMENT_ACCRUAL
		WHERE 
		((TRIM(UPPER(PRODUCT_NM_TX))="CREDIT LIFE" Or TRIM(UPPER(PRODUCT_NM_TX))="CREDIT DISABILITY" Or TRIM(UPPER(PRODUCT_NM_TX))="DEBT PROTECTION"
			AND SETL_PROG_CUST_NM Like "%CFR%")
		OR
		(TRIM(UPPER(PRODUCT_NM_TX))="CREDIT LIFE" Or TRIM(UPPER(PRODUCT_NM_TX))="CREDIT DISABILITY")
		)
		GROUP BY CUST_CONTR_NR, AGREEMENT_SETL_NR, SETL_PROG_CUST_NM, RFRSH_DT	
;
QUIT;

/* -------------------------------------------------------------------- */
/* Put the current date in YYYYQ format into a variable                 */
/* -------------------------------------------------------------------- */
%macro ExtractCurrentYrQtr(rownum=1, VarName1=Acctg_Yr_Qtr);
	data _null_;
		set WORK.CFRandDCFandPCFBalances(obs=&rownum. firstobs=&rownum. keep = &VarName1.);	
		call symputx('AcctgYrQtr', &VarName1., "G");
	    stop;
	run;
%mend ExtractCurrentYrQtr;

%ExtractCurrentYrQtr(rownum=1, VarName1=AcctgYearQtr)

%put &AcctgYrQtr.;
%let AcctgYrQtr=%unquote(%str(%'&AcctgYrQtr%'));
%put &AcctgYrQtr.;

/* -------------------------------------------------------------------- */
/* If need to re-run for the same quarter, delete any previous          */
/* entries for the same quarter.                                        */
/*    BE CAREFUL THAT THE NEW CFR BALANCES ARE GOING TO BE CORRECT.     */
/* A clone version of the Snowflake table is used in Dvlp SAS code      */
/* -------------------------------------------------------------------- */
PROC SQL;
/*	%SFConnect(ERP, ANALYTICS_FINANCE_USR_WH_PROD, B_CMG_WELCHJ_DB, CI_DP_ERP, R-APP-B-WELCHJ,,);*/

	%SFConnect(ERP, B_CMG_WELCHJ_DB, CI_DP_ERP, R-APP-B-WELCHJ,,,,Load);
/*		CREATE TABLE WORK.TempData AS*/
/*		     SELECT **/
/*		     FROM CONNECTION to ERP*/
/*			(*/
/*				select distinct met.STATUS*/
/*				from ERPMETRICS_STAGE2 met*/
/**/
/*				;*/
/*			);*/

		execute (
 			delete from "CI_DP_ERP"."CFR_DCF_PCFBALANCES_STAGE_CLONE"
				/*CFR_DCF_PCFBALANCES_STAGE_clone*/
				where ACCTGYEARQTR ILIKE &AcctgYrQtr.
/*				where ACCTGYEARQTR='2018Q4' */
 		 ) by ERP;


	Run;
	%put proc sql syserr=&syserr;

	%PUT &SQLXRC. &SQLXMSG. ; * SQL Server query return code and message;

	DISCONNECT FROM ERP;
Quit;


proc sql;

/*	 This command will copy new CFR balances from the SAS table to the Snowflake table */
/*   A clone version of the Snowflake table is used in DVLP SAS code                   */
	insert into snow.CFR_DCF_PCFBALANCES_STAGE_CLONE
		select * from work.CFRandDCFandPCFBalances; 

quit;

