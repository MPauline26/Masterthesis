
ODS GRAPHICS ON / MAXOBS=10929045;
ODS LISTING GPATH='C:\Users\meikee.pagsinohin\Documents\MA\plot' IMAGE_DPI = 300 STYLE=JOURNAL;
ODS GRAPHICS / IMAGENAME="image" RESET=INDEX IMAGEFMT=PNG WIDTH = 20CM HEIGHT = 15CM ;

/* CALCULATE GINI VALUES FOR ALL VARIABLES */
%MACRO GINI(DATA, VAR, VAR_ORIG);

	ODS GRAPHICS / IMAGENAME="&TYPE_VAR._&VAR._ROC_&&GROUP&M.." IMAGEFMT=PNG WIDTH = 20CM HEIGHT = 15CM;
	PROC LOGISTIC DATA=&DATA.;
		MODEL DEFAULT_12M(EVENT='1') = &VAR. / OUTROC=ROC;
		ROC;
	    ODS OUTPUT ROCASSOCIATION = AUC;
	RUN;

	DATA AUC;
	SET AUC;
	WHERE ROCMODEL = 'Model';
		GINI = 2 * AREA - 1;

		LENGTH VARIABLE $ 50;
		VARIABLE = "&VAR.";

		RENAME Area = AUC;
		DROP ROCModel;

	RUN;

	PROC SQL; 

	CREATE TABLE AUC AS 
		SELECT 
			main.*
			, label.LABEL
		FROM AUC main
		LEFT JOIN VARIABLELIST label
		ON label.Variable = "&VAR_ORIG.";

	QUIT;

	DATA GINI_FIN;
	RETAIN Variable GINI;
	SET AUC;
	RUN;

	PROC PRINT DATA=AUC NOOBS LABEL;
	    VAR AUC GINI;
	RUN;

	PROC SQL; DROP TABLE AUC, ROC; QUIT;

%MEND;

%MACRO UNIV_ANALYSIS(DATA, VAR, GROUP, N_BAR, TYPE_VAR);

PROC SQL;

	CREATE TABLE GROUP_LIST AS 
		SELECT 
			DISTINCT GROUP1, GROUP2
		FROM &DATA.;

	SELECT COUNT(DISTINCT &GROUP.) INTO :TOTAL_GROUP TRIMMED FROM GROUP_LIST;
	SELECT DISTINCT &GROUP. INTO :GROUP1-:GROUP&TOTAL_GROUP. FROM GROUP_LIST;

QUIT;

%DO M = 1 %TO &TOTAL_GROUP.;
%PUT ------------ &M. OF &TOTAL_GROUP.: &&GROUP&M.;
	
	DATA TEMP;
	SET &DATA.;
	WHERE &GROUP. = "&&GROUP&M.";
	KEEP DEFAULT_12M DATUM &VAR. &GROUP.;
	RUN;

	%IF &TYPE_VAR. = NUM %THEN %DO;

		FILENAME GRAFOUT "C:\Users\meikee.pagsinohin\Documents\MA\plot\&TYPE_VAR._&VAR._DISTRIBUTION_&&GROUP&M...png"; 
		GOPTIONS RESET=ALL DEVICE=PNG GSFNAME=GRAFOUT;
		PROC GBARLINE DATA=TEMP;
			BAR	&VAR. / LEVELS=&N_BAR.;
			PLOT / SUMVAR=DEFAULT_12M	TYPE=MEAN;
			TITLE "&&GROUP&M.: Distribution of &VAR.";
		RUN;

		ODS GRAPHICS / IMAGENAME="&TYPE_VAR._&VAR._BOXPLOT_&&GROUP&M.." IMAGEFMT=PNG WIDTH = 20CM HEIGHT = 15CM;
		PROC SGPLOT  DATA=TEMP;
		   VBOX &VAR.;
		   TITLE "&&GROUP&M.: Boxplot of &VAR.";
		RUN; 

		ODS GRAPHICS / IMAGENAME="&TYPE_VAR._&VAR._BOXPLOT_DEF_&&GROUP&M.." IMAGEFMT=PNG WIDTH = 20CM HEIGHT = 15CM;
		PROC SGPLOT DATA=TEMP;
		   VBOX &VAR.  / GROUP = DEFAULT_12M;
		   TITLE "&&GROUP&M.: Boxplot of &VAR. for each category";
		RUN;

		ODS GRAPHICS / IMAGENAME="&TYPE_VAR._&VAR._KS_STATISTICS_&&GROUP&M.." IMAGEFMT=PNG WIDTH = 20CM HEIGHT = 15CM;
		PROC NPAR1WAY DATA=TEMP EDF;
			CLASS DEFAULT_12M;
			VAR &VAR.;
			OUTPUT OUT=KS_STATISTICS(RENAME=(_D_=KS_STAT _VAR_=VARIABLE) KEEP=_VAR_ _D_);
		RUN;

		PROC CORR DATA=TEMP OUT=CORR(WHERE=(_TYPE_="CORR") RENAME=(_NAME_=VARIABLE DEFAULT_12M=CORR));
			VAR DEFAULT_12M;
			WITH &VAR.;
		RUN;

		%GINI(DATA=TEMP, VAR=&VAR., VAR_ORIG=&VAR.);

		PROC SQL;

			CREATE TABLE GINI_KS_CORR AS
			SELECT 
				"&&GROUP&M." AS GROUP LENGTH=5
				, gini.VARIABLE
				, gini.GINI
				, gini.AUC
				, gini.LABEL
				, ks.KS_STAT
				, corr.CORR
			FROM GINI_FIN gini

			LEFT JOIN KS_STATISTICS ks
			ON ks.VARIABLE = gini.VARIABLE

			LEFT JOIN CORR corr
			ON corr.VARIABLE = gini.VARIABLE;

		QUIT;

	%END;
	%IF &TYPE_VAR. = CAT %THEN %DO;

		FILENAME GRAFOUT "C:\Users\meikee.pagsinohin\Documents\MA\plot\&TYPE_VAR._&VAR._DISTRIBUTION_&&GROUP&M...png"; 
		GOPTIONS RESET=ALL DEVICE=PNG GSFNAME=GRAFOUT;
		PROC GBARLINE DATA=TEMP;
			BAR	&VAR. ;
			PLOT / SUMVAR=DEFAULT_12M	TYPE=MEAN;
			TITLE "&&GROUP&M.: Distribution of &VAR.";
		RUN;

		PROC SQL;
			SELECT COUNT(DISTINCT &VAR.) INTO :TOTALCAT FROM TEMP;
			SELECT DISTINCT &VAR. INTO :VALUE1- FROM TEMP;
		QUIT;

		DATA TEMP;
		SET TEMP;

		%DO J = 1 %TO &TOTALCAT.;
			IF &VAR. = "&&VALUE&J." THEN &VAR.__&&VALUE&J. = 1;
			ELSE &VAR.__&&VALUE&J. = 0;
		%END;

		RUN;

		DATA GINI_KS_CORR;
		RUN;

		%DO K = 1 %TO &TOTALCAT.;
		%PUT ------------ &K. OF &TOTALCAT.: &VAR.__&&VALUE&K.;
			%GINI(DATA=TEMP, VAR=&VAR.__&&VALUE&K., VAR_ORIG=&VAR.);

			DATA GINI_KS_CORR;
			RETAIN GROUP;
			SET GINI_KS_CORR GINI_FIN;
			RUN;

		%END;

		DATA GINI_KS_CORR;
		SET GINI_KS_CORR;
			LENGTH GROUP $ 5;
			GROUP = "&&GROUP&M.";
			KEEP GROUP VARIABLE GINI AUC LABEL;
		RUN;

	%END;
	%IF &TYPE_VAR. = IND %THEN %DO;

		FILENAME GRAFOUT "C:\Users\meikee.pagsinohin\Documents\MA\plot\&TYPE_VAR._&VAR._DISTRIBUTION_&&GROUP&M...png"; 
		GOPTIONS RESET=ALL DEVICE=PNG GSFNAME=GRAFOUT;
		PROC GBARLINE DATA=TEMP;
			BAR	&VAR. / DISCRETE ;
			PLOT / SUMVAR=DEFAULT_12M	TYPE=MEAN;
			TITLE "&&GROUP&M.: Distribution of &VAR.";
		RUN;

		%GINI(DATA=TEMP, VAR=&VAR., VAR_ORIG=&VAR.);

		DATA GINI_KS_CORR;
		RETAIN GROUP;
		SET GINI_FIN;

		LENGTH GROUP $ 5;
		GROUP = "&&GROUP&M.";
		KEEP GROUP VARIABLE GINI AUC LABEL;

		RUN;

	%END;

	DATA GINI_KS_CORR_FIN;
	SET GINI_KS_CORR_FIN GINI_KS_CORR;
		IF VARIABLE = '' THEN DELETE;
	RUN;

	PROC SQL; DROP TABLE TEMP; QUIT;

%END;

%MEND;

%MACRO UNIV_ANALYSIS2(DATA, GROUP, TYPE_VAR, NBAR);

PROC SQL;

	SELECT COUNT(*) INTO :TOTAL TRIMMED FROM VARIABLELIST WHERE TYPE = "&TYPE_VAR.";
	SELECT VARIABLE INTO :VAR1-:VAR&TOTAL. FROM VARIABLELIST WHERE TYPE = "&TYPE_VAR.";

QUIT;

	%DO I = 1 %TO &TOTAL.;
	%PUT ------------ &I. OF &TOTAL.: &&VAR&I.;
		%UNIV_ANALYSIS(DATA=&DATA., VAR=&&VAR&I., GROUP=&GROUP., N_BAR=&NBAR., TYPE_VAR=&TYPE_VAR.);
	%END;

%MEND;

DATA GINI_KS_CORR_FIN;
LENGTH GROUP $ 5 VARIABLE $ 50 LABEL $ 150;
RUN;

/* GINI CALCULATION FOR ALL VARIABLES */
%UNIV_ANALYSIS2(DATA=&USED_DATASET., GROUP=GROUP1, TYPE_VAR=NUM, NBAR=10);
%UNIV_ANALYSIS2(DATA=&USED_DATASET., GROUP=GROUP1, TYPE_VAR=CAT);
%UNIV_ANALYSIS2(DATA=&USED_DATASET., GROUP=GROUP1, TYPE_VAR=IND);

DATA plot.GINI_KS_CORR_FIN;
SET GINI_KS_CORR_FIN;
RUN;

*ods graphics off;


/* --------------------------------------------------------------------------------------------------- */

/* TRANSFORMATION OF SPECIFIC VARIABLES, run after first part */

ODS GRAPHICS ON / MAXOBS=10929045;
ODS LISTING GPATH='C:\Users\meikee.pagsinohin\Documents\MA\plot' IMAGE_DPI = 300 STYLE=JOURNAL;
ODS GRAPHICS / IMAGENAME="image" RESET=INDEX IMAGEFMT=PNG WIDTH = 20CM HEIGHT = 15CM ;

DATA &USED_DATASET.;
SET &USED_DATASET.;

/* Additional transformations, added in Program "Miss Rate", copied here for overview */
/*

IF mi_pct > 0 THEN flag_mi = 1;
ELSE IF mi_pct = 0 THEN flag_mi = 0;

IF cnt_units > 0 THEN flag_cnt_units = 1;
ELSE IF cnt_units = 0 THEN flag_cnt_units = 0;

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

*/

RUN; 

DATA GINI_KS_CORR_FIN;
LENGTH GROUP $ 5 VARIABLE $ 50 LABEL $ 150;
RUN;

/* GINI CALCULATION FOR SPECIFIC (NEW) VARIABLES */
%UNIV_ANALYSIS(DATA=&USED_DATASET., VAR=flag_mi, GROUP=GROUP1, N_BAR=10, TYPE_VAR=IND);
%UNIV_ANALYSIS(DATA=&USED_DATASET., VAR=flag_cnt_units, GROUP=GROUP1, N_BAR=10, TYPE_VAR=IND);
%UNIV_ANALYSIS(DATA=&USED_DATASET., VAR=flag_orig_loan_term_HI_360M, GROUP=GROUP1, N_BAR=10, TYPE_VAR=IND);
%UNIV_ANALYSIS(DATA=&USED_DATASET., VAR=flag_orig_loan_term_HEQ_360M, GROUP=GROUP1, N_BAR=10, TYPE_VAR=IND);
%UNIV_ANALYSIS(DATA=&USED_DATASET., VAR=flag_orig_loan_term_EQ_360M, GROUP=GROUP1, N_BAR=10, TYPE_VAR=IND);
%UNIV_ANALYSIS(DATA=&USED_DATASET., VAR=orig_loan_term_3grp, GROUP=GROUP1, N_BAR=10, TYPE_VAR=CAT);
%UNIV_ANALYSIS(DATA=&USED_DATASET., VAR=cd_ppty_val_type, GROUP=GROUP1, N_BAR=10, TYPE_VAR=CAT);

DATA plot.GINI_KS_CORR_FIN_addVar;
SET GINI_KS_CORR_FIN;
RUN;


/* --------------------------------------------------------------------------------------------------- */


DATA GINI_KS_CORR_FIN;
SET plot.GINI_KS_CORR_FIN plot.GINI_KS_CORR_FIN_addVar;
RUN;

PROC SQL;

CREATE TABLE GINI_KS_CORR_FIN AS
	SELECT gini.*
	, label.TYPE
	, label.VARIABLE AS VARIABLE_ORIG
	FROM GINI_KS_CORR_FIN gini

	LEFT JOIN VARIABLELIST label
	ON label.LABEL = gini.LABEL;

QUIT;

PROC SORT DATA=GINI_KS_CORR_FIN OUT=GINI_KS_CORR_FIN;
BY VARIABLE GROUP LABEL GINI AUC DESCENDING KS_STAT DESCENDING CORR;
RUN;

ods graphics off;