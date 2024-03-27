
DATA FINAL_DATASET;
SET final.FINAL_DATASET;

	months_after_orig_dlq_30d = intck('month', mdy(substr(put(dt_first_pi,$6.),5,2),1, substr(put(dt_first_pi,$6.),1,4)), mdy(substr(put(dlq_ever30_period,$6.),5,2),1, substr(put(dlq_ever30_period,$6.),1,4)));
	months_after_orig_dlq_60d = intck('month', mdy(substr(put(dt_first_pi,$6.),5,2),1, substr(put(dt_first_pi,$6.),1,4)), mdy(substr(put(dlq_ever60_period,$6.),5,2),1, substr(put(dlq_ever60_period,$6.),1,4)));
	months_after_orig_dlq_90d = intck('month', mdy(substr(put(dt_first_pi,$6.),5,2),1, substr(put(dt_first_pi,$6.),1,4)), mdy(substr(put(dlq_everd90_period,$6.),5,2),1, substr(put(dlq_everd90_period,$6.),1,4)));
	months_after_orig_dlq_120d = intck('month', mdy(substr(put(dt_first_pi,$6.),5,2),1, substr(put(dt_first_pi,$6.),1,4)), mdy(substr(put(dlq_everd120_period,$6.),5,2),1, substr(put(dlq_everd120_period,$6.),1,4)));
	months_after_orig_dlq_180d = intck('month', mdy(substr(put(dt_first_pi,$6.),5,2),1, substr(put(dt_first_pi,$6.),1,4)), mdy(substr(put(dlq_everd180_period,$6.),5,2),1, substr(put(dlq_everd180_period,$6.),1,4)));

/* remove modification for loan age */
	loan_age_noMod = intck('month', mdy(substr(put(dt_first_pi,$6.),5,2),1, substr(put(dt_first_pi,$6.),1,4)), mdy(substr(put(last_period,$6.),5,2),1, substr(put(last_period,$6.),1,4)));
/* adjust variable because in some cases only 120DPD or 180DPD is filled in and not 90 DPD */
	months_after_orig_dlq_90d_adj = min(months_after_orig_dlq_90d, months_after_orig_dlq_120d, months_after_orig_dlq_180d);
/* create default-date */
	FORMAT DEFAULT_DATUM date9.;
	IF months_after_orig_dlq_90d_adj = months_after_orig_dlq_90d THEN DEFAULT_DATUM = mdy(substr(put(dlq_everd90_period,$6.),5,2), 1, substr(put(dlq_everd90_period,$6.),1,4));
		ELSE IF months_after_orig_dlq_90d_adj = months_after_orig_dlq_120d THEN DEFAULT_DATUM = mdy(substr(put(dlq_everd120_period,$6.),5,2), 1, substr(put(dlq_everd120_period,$6.),1,4));
		ELSE IF months_after_orig_dlq_90d_adj = months_after_orig_dlq_180d THEN DEFAULT_DATUM = mdy(substr(put(dlq_everd180_period,$6.),5,2), 1, substr(put(dlq_everd180_period,$6.),1,4));

LENGTH KEEP_FLAG $ 50;
/* Open for less than 12 months because of Cut-Off */
	IF dt_first_pi < &START_DATE.
		THEN KEEP_FLAG = '0;Remove first 2 months due to unusual low number of loans';
/* Open for less than 12 months because of Cut-Off */
	ELSE IF dt_first_pi > &END_DATE.
		THEN KEEP_FLAG = '0;Less than 12 months (last 4Q)';
/* Missing Monthly Performance data */
	ELSE IF last_period = .
		THEN KEEP_FLAG = '0;Missing Monthly Performance data';
/* Open for more than 12 months */
	ELSE IF loan_age_noMod >= 12 
		THEN KEEP_FLAG = '1;More than 12 months';
/* Open for less than 12 months but defaulted with Code Zero Balance = 2,3,9,15 */
	ELSE IF loan_age_noMod < 12 AND cd_zero_bal in ('02','03','09','15') 
		THEN KEEP_FLAG = '1;Defaulted with Code Zero Balance';
/* Open for less than 12 months but defaulted and prepaid at same time */
	ELSE IF loan_age_noMod < 12 AND months_after_orig_dlq_90d_adj = last_period AND prepay_count = 1 AND months_after_orig_dlq_90d_adj >= 0 
		THEN KEEP_FLAG = '0;Less than 12 months and defaulted but prepaid at the same time';
/* Open for less than 12 months but defaulted  */
	ELSE IF loan_age_noMod < 12 AND months_after_orig_dlq_90d_adj <= last_period AND months_after_orig_dlq_90d_adj >= 0 
		THEN KEEP_FLAG = '1;Less than 12 months but defaulted';
/* Open for less than 12 months and got pre-paid */
	ELSE IF loan_age_noMod < 12 AND prepay_count = 1 
		THEN KEEP_FLAG = '0;Less than 12 months and prepaid';
/* Data Quality Issue e.g. only 30/60 DPD or no issue visible */
	ELSE KEEP_FLAG = '0;Data Quality Issue';

/* Default Flag */
	IF (months_after_orig_dlq_90d_adj > 0 AND months_after_orig_dlq_90d_adj < 12) 
		OR (loan_age_noMod < 12 AND cd_zero_bal in ('02','03','09','15'))
		THEN DEFAULT_12M = 1;
		ELSE DEFAULT_12M = 0;

/* Create Date variable */
FORMAT DATUM date9.;
	DATUM = mdy(substr(put(dt_first_pi,$6.),5,2), 1, substr(put(dt_first_pi,$6.),1,4));

RUN;

PROC SQL;

CREATE TABLE final.CT_SAMPLE AS
	SELECT 
		DATUM,
		id_loan, 
		loan_age_noMod, 
		KEEP_FLAG, 
		DEFAULT_12M, 
		fico, 
		dt_first_pi, 
		flag_fthb, 
		dt_matr, 
		cd_msa, 
		mi_pct, 
		cnt_units, 
		occpy_sts, 
		cltv, 
		dti, 
		orig_upb, 
		ltv, 
		orig_int_rt, 
		channel, 
		ppmt_pnlty, 
		amrtzn_type, 
		st, 
		prop_type, 
		zipcode, 
		loan_purpose, 
		orig_loan_term, 	
		cnt_borr, 
		seller_name, 
		servicer_name, 
		flag_sc, 
		id_loan_preharp, 
		ind_afdl, 
		ind_harp, 
		cd_ppty_val_type, 
		flag_int_only, 
		last_period, 
		cd_zero_bal, 
		zero_bal_delq_sts, 
		prepay_count, 
		default_count
	FROM FINAL_DATASET
	WHERE SUBSTR(KEEP_FLAG,1,1) = '1'
	ORDER BY DATUM, id_loan;

QUIT;

proc import datafile="C:\Users\meikee.pagsinohin\Documents\MA\USregions.csv"
	out=USregions
	dbms=csv
	replace;
	getnames=yes;
run;

PROC SQL;

CREATE TABLE final.DEV_SAMPLE_5Y AS
	SELECT
		ct.*
		, Region AS us_reg
	FROM final.CT_SAMPLE ct
	LEFT JOIN USregions reg
	ON ct.st = reg.'State Code'n
	WHERE ct.dt_first_pi >= &START_DATE_DEV. 
	AND ct.dt_first_pi <= &END_DATE.;
;

QUIT;

PROC SQL;

CREATE TABLE final.DEV_SAMPLE_3Y AS
	SELECT
		ct.*
		, Region AS us_reg
	FROM final.CT_SAMPLE ct
	LEFT JOIN USregions reg
	ON ct.st = reg.'State Code'n
	WHERE ct.dt_first_pi >= &START_DATE_DEV_3Y. 
	AND ct.dt_first_pi <= &END_DATE_DEV_3Y.;
;

QUIT;

PROC SQL;

CREATE TABLE final.OOT_SAMPLE_1Y AS
	SELECT
		ct.*
		, Region AS us_reg
	FROM final.CT_SAMPLE ct
	LEFT JOIN USregions reg
	ON ct.st = reg.'State Code'n
	WHERE ct.dt_first_pi >= &START_DATE_VAL_1Y. 
	AND ct.dt_first_pi <= &END_DATE_VAL_1Y.;
;

QUIT;

PROC SQL;

	SELECT
		YEAR(DATUM) AS YEAR
		, KEEP_FLAG
		, COUNT(*) AS NR
	FROM FINAL_DATASET
	GROUP BY YEAR, KEEP_FLAG;

	TITLE "DEFAULT RATES BEFORE EXCLUSIONS";
	SELECT
		Datum
		,COUNT(*) AS NR
		,SUM(DEFAULT_12M) AS NR_DEF
		,AVG(DEFAULT_12M) AS DR
	FROM FINAL_DATASET
	GROUP BY Datum;

	TITLE;

QUIT;