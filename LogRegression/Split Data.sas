PROC SORT DATA=&USED_DATASET._FINAL ;
BY DEFAULT_12M GROUP2;
RUN;

PROC SURVEYSELECT 
	DATA=&USED_DATASET._FINAL 
	OUT=&USED_DATASET._FINAL 
	SAMPRATE=.7 
	OUTALL
    METHOD=SRS
    SEED=26020703;       /*SET SEED TO MAKE THIS EXAMPLE REPRODUCIBLE*/
    STRATA DEFAULT_12M GROUP2; /*SPECIFY VARIABLE TO USE FOR STRATIFICATION*/
RUN;

DATA final.&USED_DATASET._FINAL;
SET &USED_DATASET._FINAL;
RUN;

DATA final.TRAIN_SAMPLE final.TEST_SAMPLE;
SET &USED_DATASET._FINAL;

KEEP 
	SELECTED
	DATUM
	id_loan
	loan_age_noMod
	KEEP_FLAG
	DEFAULT_12M
	GROUP1
	GROUP2
	fico
	flag_fthb
	cltv
	cltv_adj
	dti
	ltv
	ltv_adj
	orig_upb
	channel__9
	channel__B
	channel__C
	channel__R
	channel__T
	loan_purpose__C
	loan_purpose__N
	loan_purpose__P
	cnt_borr
	cd_ppty_val_type__1
	cd_ppty_val_type__2
	cd_ppty_val_type__3
	cd_ppty_val_type__9
	us_reg__Midwest
	us_reg__Northeast
	us_reg__Other
	us_reg__South
	us_reg__West
	flag_mi
	flag_orig_loan_term_HEQ_360M
	cnt_units
	occpy_sts__S
	occpy_sts__P
	occpy_sts__I;

IF SELECTED = 1 THEN OUTPUT final.TRAIN_SAMPLE;
ELSE OUTPUT final.TEST_SAMPLE;

RUN;


PROC SQL;

	TITLE "DEFAULT RATES OF TRAINING SAMPLE (TOTAL)";
	SELECT
		COUNT(*) AS NR
		,SUM(DEFAULT_12M) AS NR_DEF
		,AVG(DEFAULT_12M) AS DR FORMAT PERCENT18.6
	FROM final.TRAIN_SAMPLE;

	TITLE "DEFAULT RATES OF TEST SAMPLE (TOTAL)";
	SELECT
		COUNT(*) AS NR
		,SUM(DEFAULT_12M) AS NR_DEF
		,AVG(DEFAULT_12M) AS DR FORMAT PERCENT18.6
	FROM final.TEST_SAMPLE;

	TITLE "DEFAULT RATES OF TRAINING/TEST SAMPLE";
	SELECT 
		a.DATUM
		,a.NR AS NR_TRAIN
		,b.NR AS NR_TEST
		,a.NR_DEF AS NR_DEF_TRAIN
		,b.NR_DEF AS NR_DEF_TEST
		,a.DR AS DR_TRAIN FORMAT PERCENT18.6
		,b.DR AS DR_TEST FORMAT PERCENT18.6
	FROM 
		(
			SELECT
				DATUM
				,COUNT(*) AS NR
				,SUM(DEFAULT_12M) AS NR_DEF
				,AVG(DEFAULT_12M) AS DR
			FROM final.TRAIN_SAMPLE
			GROUP BY DATUM
		) a 
	LEFT JOIN 
		(
			SELECT
				DATUM
				,COUNT(*) AS NR
				,SUM(DEFAULT_12M) AS NR_DEF
				,AVG(DEFAULT_12M) AS DR
			FROM final.TEST_SAMPLE
			GROUP BY DATUM
		) b
	ON a.DATUM = b.DATUM;

	TITLE;
QUIT;

