
%LET USED_DATASET = DEV_SAMPLE_5Y;

/* ANALYSE DISTINCT VALUES AND DETERMINE MISSING RATE FOR ALL TYPES OF VARIABLES */
%MACRO MISS_VAR(DATA, TYPE_VAR, VAR=XXX);

%IF &VAR. = XXX %THEN %DO;

	PROC SQL NOPRINT;

		SELECT COUNT(*) INTO :TOTAL TRIMMED FROM VARIABLELIST WHERE TYPE = "&TYPE_VAR.";
		SELECT VARIABLE INTO :VAR1-:VAR&TOTAL. FROM VARIABLELIST WHERE TYPE = "&TYPE_VAR.";

	QUIT;

	%DO I = 1 %TO &TOTAL.;
	%PUT ------------ &I. OF &TOTAL.: &&VAR&I.;
		PROC SQL;

			CREATE TABLE TEMP AS
				SELECT 
					"&TYPE_VAR." AS TYPE
					,"&&VAR&I." AS VARIABLE
					,put(cats(&&VAR&I.),$100.) AS VALUE
					,COUNT(*) AS FREQ
			FROM &DATA.
			GROUP BY &&VAR&I.;
		
		QUIT;

		DATA MISS_VAR;
		SET MISS_VAR TEMP;
		IF Variable = '' THEN DELETE;
		RUN;

		PROC SQL; DROP TABLE TEMP; QUIT;

	%END;

%END;
%ELSE %DO;

		PROC SQL;

			CREATE TABLE TEMP AS
				SELECT 
					"&TYPE_VAR." AS TYPE
					,"&VAR." AS VARIABLE
					,put(cats(&VAR.),$100.) AS VALUE
					,COUNT(*) AS FREQ
			FROM &DATA.
			GROUP BY &VAR.;
		
		QUIT;

		DATA MISS_VAR;
		SET MISS_VAR TEMP;
		IF Variable = '' THEN DELETE;
		RUN;

		PROC SQL; DROP TABLE TEMP; QUIT;

%END;

%MEND;

*DATA MISS_VAR;
*LENGTH TYPE $ 5 VARIABLE $ 50 VALUE $ 100;
*RUN;

*%MISS_VAR(DATA=&USED_DATASET., TYPE_VAR=CAT);
*%MISS_VAR(DATA=&USED_DATASET., TYPE_VAR=IND);
*%MISS_VAR(DATA=&USED_DATASET., TYPE_VAR=NUM);
*%MISS_VAR(DATA=&USED_DATASET., TYPE_VAR=MAN, VAR=st);

DATA &USED_DATASET.;
SET &USED_DATASET.(RENAME=(	cnt_borr 		= cnt_borr_raw 
						flag_fthb 		= flag_fthb_raw 
						ppmt_pnlty 		= ppmt_pnlty_raw 
						flag_sc 		= flag_sc_raw 
						ind_harp 		= ind_harp_raw 
						flag_int_only 	= flag_int_only_raw));

/* SET INDICATOR VARIABLES TO 1 AND 0 */
IF flag_fthb_raw = 'Y' 		THEN flag_fthb = 1; 		ELSE flag_fthb = 0;
IF ppmt_pnlty_raw = 'Y'		THEN ppmt_pnlty = 1; 		ELSE ppmt_pnlty = 0;
IF flag_sc_raw = 'Y' 		THEN flag_sc = 1; 			ELSE flag_sc = 0;
IF ind_harp_raw = 'Y' 		THEN ind_harp = 1; 			ELSE ind_harp = 0;
IF flag_int_only_raw = 'Y' 	THEN flag_int_only = 1; 	ELSE flag_int_only = 0;

/* SET MISSING VALUES TO NULL/9, ACCORDING TO DATA DICTIONARY AND MISSING ENTRY */

/* INDICATOR VARIABLES */
/* ppmt_pnlty_raw, flag_int_only have no missing entries in DEV_SAMPLE_5Y */
IF flag_fthb_raw = '9' 			THEN flag_fthb = .;
IF flag_sc_raw = '' 			THEN flag_sc = .;
IF ind_harp_raw = '' 			THEN ind_harp = .;

/* CATEGORICAL VARIABLES */
/* occpy_sts, amrtzn_type, prop_type, loan_purpose, st have no missing entries in DEV_SAMPLE_5Y*/
IF occpy_sts = '9' 				THEN occpy_sts = '9';
IF channel = '9' 				THEN channel = '9'; 
IF prop_type = '99'				THEN prop_type = '9';
IF ind_afdl = '9' 			THEN ind_afdl = '9';
IF loan_purpose = '9'			THEN loan_purpose = '9'; 
IF us_reg = '' AND st ^= '' 	THEN us_reg = 'Other'; /* US OUTSIDE OF MAIN LAND */
ELSE IF us_reg = '' 			THEN us_reg = '9';

/* NUMERICAL VARIABLES */
/* cnt_units, orig_upb, orig_loan_term have no missing entries in DEV_SAMPLE_5Y*/
IF fico = 9999 				THEN fico = .;
IF cd_msa = . 				THEN cd_msa = .; 
IF mi_pct = 999 			THEN mi_pct = .;
IF cnt_units = 99 			THEN cnt_units = .; /* no case found */
IF cltv = 999 				THEN cltv = .; /* no case found */
IF dti = 999 				THEN dti = .;
IF ltv = 999				THEN ltv = .; /* no case found */

/* CHANGE FORMAT TO NUMERIC */
cnt_borr_temp = input(cnt_borr_raw, 8.);
IF cnt_borr_raw = '99' THEN cnt_borr_temp = .;
RENAME cnt_borr_temp = cnt_borr;

RUN;

/* re-label */
%label_data(&USED_DATASET., work, VARIABLELIST, Variable, Label);

/* CALCULATE MISSING PERCENTAGE FOR ALL VARIABLES */
/* create a format to group missing and nonmissing */
proc format;
 value $missfmt '9'='Missing' other='Not Missing';
 value  missfmt  . ='Missing' other='Not Missing';
run;

PROC SQL NOPRINT;

SELECT VARIABLE INTO :CAT_VAR separated by " " FROM VARIABLELIST WHERE TYPE = "CAT";
SELECT VARIABLE INTO :NUM_VAR separated by " " FROM VARIABLELIST WHERE TYPE = "NUM";
SELECT VARIABLE INTO :IND_VAR separated by " " FROM VARIABLELIST WHERE TYPE = "IND";

SELECT VARIABLE INTO :NUM_IND_VAR separated by " " 			FROM VARIABLELIST WHERE TYPE IN ("NUM","IND");
SELECT CATS('F_',VARIABLE) INTO :ALL_VAR separated by ", " 	FROM VARIABLELIST WHERE TYPE IN ("CAT","NUM","IND");

QUIT;

%MACRO MISSINGTABLE(DATA, COND, GROUP);

ODS OUTPUT ONEWAYFREQS=WORK.TEMP;
proc freq data=&DATA.&COND.; 
format &CAT_VAR. $missfmt.; /* apply format for the duration of this PROC */
tables &CAT_VAR. / missing missprint nocum nopercent;
format &NUM_IND_VAR. missfmt.;
tables &NUM_IND_VAR. / missing missprint nocum nopercent;
run;

DATA TEMP;
RETAIN VARIABLE MISS_NONMISS;
SET TEMP;

LENGTH VARIABLE $ 40 MISS_NONMISS $ 20;
VARIABLE = SUBSTR(Table,7);
MISS_NONMISS = TRIM(COALESCEC(&ALL_VAR.));

KEEP VARIABLE MISS_NONMISS FREQUENCY;

RUN;

PROC SQL;

CREATE TABLE TEMP AS
	SELECT 
		VARIABLE
		,MAX(CASE WHEN MISS_NONMISS = 'Missing' THEN FREQUENCY END) AS MISSING
		,MAX(CASE WHEN MISS_NONMISS = 'Not Missing' THEN FREQUENCY END) AS NOT_MISSING
	FROM TEMP
GROUP BY VARIABLE;

QUIT;

DATA TEMP;
RETAIN GROUP;
SET TEMP;

	FORMAT MISS_PERCENT PERCENT15.10;
	MISS_PERCENT = MISSING / SUM(MISSING,NOT_MISSING);

	IF MISSING = . THEN DO;
		MISSING = 0;
		MISS_PERCENT = 0;
	END;

	IF NOT_MISSING = . THEN NOT_MISSING = 0;


	LENGTH GROUP $ 5;
	GROUP = &GROUP.;
RUN;

DATA MISSINGTABLE;
SET MISSINGTABLE TEMP;
	IF VARIABLE = '' THEN DELETE;
RUN;

PROC SQL; DROP TABLE TEMP; QUIT;

%MEND;

DATA MISSINGTABLE;
LENGTH VARIABLE $ 50;
RUN;

%MISSINGTABLE(DATA=&USED_DATASET., COND=, GROUP="ALL");
%MISSINGTABLE(DATA=&USED_DATASET., COND=(WHERE=(GROUP2 = "2017")), GROUP="2017");
%MISSINGTABLE(DATA=&USED_DATASET., COND=(WHERE=(GROUP2 = "2018")), GROUP="2018");
%MISSINGTABLE(DATA=&USED_DATASET., COND=(WHERE=(GROUP2 = "2019")), GROUP="2019");
%MISSINGTABLE(DATA=&USED_DATASET., COND=(WHERE=(GROUP2 = "2020")), GROUP="2020");
%MISSINGTABLE(DATA=&USED_DATASET., COND=(WHERE=(GROUP2 = "2021")), GROUP="2021");

PROC SQL;

	CREATE TABLE MISSINGTABLE AS
		SELECT 
			miss.*
			, label.TYPE
			, label.LABEL

	FROM MISSINGTABLE miss
	LEFT JOIN VARIABLELIST label
	ON label.VARIABLE = miss.VARIABLE;

QUIT;