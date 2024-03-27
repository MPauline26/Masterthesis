DATA OOF_SAMPLE;
SET final.OOT_SAMPLE_1Y(RENAME=(	cnt_borr 		= cnt_borr_raw 
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
IF ind_afdl = '9' 				THEN ind_afdl = '9';
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

/* TRANSFORMATION OF MI_PCT AND orig_loan_term , added afterwards */
IF mi_pct > 0 THEN flag_mi = 1;
ELSE IF mi_pct = 0 THEN flag_mi = 0;

IF cnt_units > 1 THEN flag_cnt_units = 1;
ELSE IF cnt_units = 1 THEN flag_cnt_units = 0;

LENGTH orig_loan_term_3grp $ 10;
IF orig_loan_term < 360 THEN orig_loan_term_3grp = "LE_360M";
ELSE IF orig_loan_term = 360 THEN orig_loan_term_3grp = "EQ_360M";
ELSE IF orig_loan_term > 360 THEN orig_loan_term_3grp = "HI_360M";

IF orig_loan_term <= 360 THEN flag_orig_loan_term_HI_360M = 0;
ELSE IF orig_loan_term > 360 THEN flag_orig_loan_term_HI_360M = 1;

IF orig_loan_term < 360 THEN flag_orig_loan_term_HEQ_360M = 0;
ELSE IF orig_loan_term >= 360 THEN flag_orig_loan_term_HEQ_360M = 1;

IF orig_loan_term = 360 THEN flag_orig_loan_term_EQ_360M = 1;
ELSE flag_orig_loan_term_EQ_360M = 0;

IF cd_ppty_val_type = '9' THEN cd_ppty_val_type = '9';

RUN;

%MACRO TRANSFORMATION(DATA, TYPE_VAR);

PROC SQL NOPRINT;

	SELECT COUNT(*) 		INTO :TOTAL_PERC TRIMMED FROM VARIABLELIST WHERE TYPE = "NUM";
	SELECT VARIABLE 		INTO :VAR1-:VAR&TOTAL_PERC. FROM VARIABLELIST WHERE TYPE = "NUM";
	SELECT FLAG_LOW_CAP 	INTO :FLAG_LOW_CAP1-:FLAG_LOW_CAP&TOTAL_PERC. FROM VARIABLELIST WHERE TYPE = "NUM";
	SELECT FLAG_HIGH_CAP 	INTO :FLAG_HIGH_CAP1-:FLAG_HIGH_CAP&TOTAL_PERC. FROM VARIABLELIST WHERE TYPE = "NUM";
	SELECT FLAG_MISSING 	INTO :FLAG_MISSING1-:FLAG_MISSING&TOTAL_PERC. FROM VARIABLELIST WHERE TYPE = "NUM";

QUIT;

	%DO O = 1 %TO &TOTAL_PERC.;
	%PUT ------------ &O. OF &TOTAL_PERC.: &&VAR&O.;

	PROC SQL;

		SELECT Mean, Median, StdDev, L_BOARDER, H_BOARDER INTO :mean, :median, :stdv, :lboarder, :hboarder FROM UNIV_ANALYSIS_RESULT
		WHERE Variable = "&&VAR&O.";

	QUIT;

	DATA &DATA.;
	SET &DATA.;

	&&VAR&O.._ADJ = &&VAR&O.;

		%IF &&FLAG_MISSING&O. = 1 %THEN %DO;
			IF &&VAR&O.._ADJ = . THEN &&VAR&O.._ADJ = &median.;
		%END;
		%IF &&FLAG_LOW_CAP&O. = 1 %THEN %DO;
			IF &&VAR&O. < &lboarder. THEN &&VAR&O.._ADJ = &lboarder.;
		%END;
		%IF &&FLAG_HIGH_CAP&O. = 1 %THEN %DO;
			IF &&VAR&O. > &hboarder. THEN &&VAR&O.._ADJ = &hboarder.;
		%END;
		%IF &&FLAG_MISSING&O. = 1 %THEN %DO;
			IF &&VAR&O.. = . THEN &&VAR&O.. = &median.;
		%END;

	RUN;

	DATA &DATA.;
	SET &DATA.(RENAME=(&&VAR&O.. = &&VAR&O.._ORIG &&VAR&O.._ADJ = &&VAR&O.._ADJ_ORIG));

		&&VAR&O.._NEW = (&&VAR&O.._ORIG - &mean.)/&stdv.;
		&&VAR&O.._ADJ_NEW = (&&VAR&O.._ADJ_ORIG - &mean.)/&stdv.;

	RUN;

	DATA &DATA.;
	SET &DATA.(DROP=&&VAR&O.._ORIG &&VAR&O.._ADJ_ORIG);

		RENAME &&VAR&O.._NEW = &&VAR&O..;
		RENAME &&VAR&O.._ADJ_NEW = &&VAR&O.._ADJ;

	RUN;

	%END;

%MEND;

%TRANSFORMATION(OOF_SAMPLE, "NUM");

DATA OOF_SAMPLE;
SET OOF_SAMPLE;

	flag_fthb_ADJ = flag_fthb;
	IF flag_fthb_ADJ = . THEN flag_fthb_ADJ = 1;

	IF flag_fthb = . THEN flag_fthb = 1;

	flag_mi_ADJ = flag_mi;
	IF flag_mi_ADJ = . THEN flag_mi_ADJ = 1;

	IF flag_mi = . THEN flag_mi = 1;

	flag_cnt_units_ADJ = flag_cnt_units;
	IF flag_cnt_units_ADJ = . THEN flag_cnt_units_ADJ = 1;

	IF flag_cnt_units = . THEN flag_cnt_units = 1;
	
	SELECTED_70_30 = 9;
	SELECTED_50_50 = 9;
	SELECTED_90_10 = 9;

RUN;

%CAT_VARIABLES_ADD_ANALYSIS(DATA=OOF_SAMPLE, VAR=loan_purpose, FLAG_ANALYSIS=0);
%CAT_VARIABLES_ADD_ANALYSIS(DATA=OOF_SAMPLE, VAR=channel, FLAG_ANALYSIS=0);
%CAT_VARIABLES_ADD_ANALYSIS(DATA=OOF_SAMPLE, VAR=cd_ppty_val_type, FLAG_ANALYSIS=0);
%CAT_VARIABLES_ADD_ANALYSIS(DATA=OOF_SAMPLE, VAR=us_reg, FLAG_ANALYSIS=0);
%CAT_VARIABLES_ADD_ANALYSIS(DATA=OOF_SAMPLE, VAR=occpy_sts, FLAG_ANALYSIS=0);

DATA OOF_SAMPLE;
SET OOF_SAMPLE;

	MODEL_SCORE_LOG	=	-4.545702244309740
+	fico			*	-0.542021303003175
+	dti				*	0.407737989534439
+	cltv			*	0.261253300989300
+	cnt_borr		*	-0.248438417513309
+	orig_upb		*	0.340675349437970;


PD_LOG = 1/(1+exp(-MODEL_SCORE_LOG));

RUN;