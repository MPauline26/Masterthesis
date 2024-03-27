ODS GRAPHICS ON;

DATA TRAIN_SAMPLE TEST_SAMPLE;
SET final.&USED_DATASET._FINAL;

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

IF &SELECTED_SPLIT. = 1 THEN OUTPUT TRAIN_SAMPLE;
ELSE OUTPUT TEST_SAMPLE;

RUN;

PROC LOGISTIC DATA = TRAIN_SAMPLE DESCENDING OUTEST=MODEL_COEFF;
MODEL DEFAULT_12M =

fico
dti
cltv
cnt_borr
orig_upb

/*
	fico
	dti
	cltv
	cnt_borr
	flag_fthb
	flag_mi
	flag_orig_loan_term_HEQ_360M
	channel__R
	channel__B
	channel__C
	channel__T
	loan_purpose__C
	loan_purpose__N
	cd_ppty_val_type__1
	cd_ppty_val_type__3
	cd_ppty_val_type__2
	orig_upb
	us_reg__Midwest
	us_reg__Northeast
	us_reg__Other
	us_reg__West
	occpy_sts__S
	occpy_sts__I
*/


/* REMOVED DUE TO HIGH CORRELATION */
/*	cltv_ADJ, ltv, ltv_ADJ */

/* NOT INCLUDED DUE TO LINEAR COMBINATION */
/*	channel__9, loan_purpose__P, cd_ppty_val_type__9, us_reg__South, occpy_sts__P */

/ SELECTION = STEPWISE SLSTAY=0.15 SLENTRY=0.15 STB DETAILS LACKFIT; 
ODS OUTPUT EFFECTINMODEL =EFFECT;
ODS OUTPUT FITSTATISTICS=AIC( KEEP=CRITERION INTERCEPTANDCOVARIATES STEP
    RENAME=(INTERCEPTANDCOVARIATES=AIC) WHERE=(CRITERION='AIC'));
ODS OUTPUT FITSTATISTICS= BIC (KEEP=CRITERION INTERCEPTANDCOVARIATES STEP
    RENAME= (INTERCEPTANDCOVARIATES=BIC)  WHERE= (CRITERION='SC')); 
SCORE DATA=TRAIN_SAMPLE OUT = LOGIT_TRAINING FITSTAT;
SCORE DATA=TEST_SAMPLE OUT = LOGIT_TEST FITSTAT;
RUN;

/*AN ENTRY SIGNIFICANCE LEVEL OF 0.15, SPECIFIED IN THE SLENTRY=0.15 OPTION, MEANS A*/
/*VARIABLE MUST HAVE A P-VALUE < 0.15 IN ORDER TO ENTER THE MODEL REGRESSION.*/
/*AN EXIT SIGNIFICANCE LEVEL OF 0.15, SPECIFIED IN THE SLSTAY=0.15 OPTION, MEANS */
/*A VARIABLE MUST HAVE A P-VALUE > 0.15 IN ORDER TO LEAVE THE MODEL*/

/* GET AIC AND BIC PER STEP TO DETERMINE VARIABLE SELECTION */
PROC FREQ DATA=EFFECT NOPRINT;
TABLE STEP*EFFECT / OUT=SUM1;RUN;

DATA SUM1(KEEP=STEP EFFECT COUNT ); 
SET SUM1; 
RUN;

PROC SORT DATA=SUM1; 
BY STEP;
RUN;

PROC SUMMARY NWAY DATA=SUM1 MISSING;
CLASS STEP;
OUTPUT OUT=NEW (DROP=_TYPE_ _FREQ_) IDGROUP(OUT[10](EFFECT)=); 
RUN;

DATA WANT(KEEP= STEP VARL); 
SET NEW;
LENGTH VARL $1000;
VARL = CATX('- ', OF EFFECT:); 
RUN;

DATA AIC_BIC_PERSTEP(DROP=CRITERION) ;
MERGE AIC BIC WANT; 
BY STEP; 
RUN;

PROC SQL; DROP TABLE EFFECT, SUM1, NEW, WANT, AIC, BIC; QUIT;

DATA plot.MODEL_COEFF; 
SET MODEL_COEFF;
RUN;

DATA plot.LOGIT_TRAINING; 
SET LOGIT_TRAINING;
RUN;

DATA plot.LOGIT_TEST; 
SET LOGIT_TEST;
RUN;

DATA plot.AIC_BIC_PERSTEP; 
SET AIC_BIC_PERSTEP;
RUN;

DATA LOGIT_TRAINING;
SET plot.LOGIT_TRAINING (KEEP=DEFAULT_12M P_1 GROUP1 GROUP2);
RUN;

DATA LOGIT_TEST;
SET plot.LOGIT_TEST (KEEP=DEFAULT_12M P_1 GROUP1 GROUP2);
RUN;

%MACRO GINI_AUC_MODEL(SAMPLE, DATA_OUT);

data _null_;

call symput('GROUP1','2017');
call symput('GROUP2','2018');
call symput('GROUP3','2019');
call symput('GROUP4','2020');
call symput('GROUP5','2021');
call symput('GROUP6','ALL');

run;

DATA &DATA_OUT.;
	LENGTH GROUP $ 5;
RUN;

%DO M = 1 %TO 6;
%PUT ------------ &M. OF 6: &&GROUP&M.;

	DATA TEMP;
	SET &SAMPLE.;
	WHERE GROUP1 = "&&GROUP&M." OR GROUP2 = "&&GROUP&M.";
	KEEP DEFAULT_12M P_1 GROUP1 GROUP2;
	RUN;

	ODS GRAPHICS / IMAGENAME="&SAMPLE._MODEL_ROC" IMAGEFMT=PNG WIDTH = 20CM HEIGHT = 15CM;
	PROC LOGISTIC DATA=TEMP;
		MODEL DEFAULT_12M(EVENT='1') = P_1 / OUTROC=VROC;
		ROC;
	    ODS OUTPUT ROCASSOCIATION = TEMP2;
	RUN;

	DATA TEMP2;
	SET TEMP2;
	WHERE ROCMODEL = 'Model';
		GINI = 2 * AREA - 1;

		LENGTH VARIABLE $ 50;
		VARIABLE = "PD";

		RENAME Area = AUC;
		DROP ROCModel;

	RUN;

	DATA TEMP2;
	SET TEMP2;

	LENGTH GROUP $ 5;
	GROUP = "&&GROUP&M.";

	RUN;

	DATA &DATA_OUT.;
	SET &DATA_OUT. TEMP2;
	RUN;

%END;

	DATA plot.&DATA_OUT.;
	SET &DATA_OUT.;
		IF GROUP = '' THEN DELETE;
	RUN;



%MEND;

ODS GRAPHICS ON / MAXOBS=10929045;
ODS LISTING GPATH='C:\Users\meikee.pagsinohin\Documents\MA\plot' IMAGE_DPI = 300 STYLE=JOURNAL;

%GINI_AUC_MODEL(SAMPLE=LOGIT_TRAINING, DATA_OUT=ROC_TRAINING);
%GINI_AUC_MODEL(SAMPLE=LOGIT_TEST, DATA_OUT=ROC_TEST);