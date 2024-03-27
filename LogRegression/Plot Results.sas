ODS GRAPHICS ON / MAXOBS=10929045;
ODS LISTING GPATH='C:\Users\meikee.pagsinohin\Documents\MA\plot' IMAGE_DPI = 300 STYLE=JOURNAL;
ODS GRAPHICS / IMAGENAME="image" RESET=INDEX IMAGEFMT=PNG WIDTH = 20CM HEIGHT = 15CM ;

/* TRANSFORMATION OF MI_PCT VARIABLE */
DATA &USED_DATASET.;
SET &USED_DATASET.;

IF mi_pct > 0 THEN flag_mi = 1;
ELSE flag_mi = 0;

RUN; 

DATA GINI_KS_CORR_FIN;
LENGTH GROUP $ 5 VARIABLE $ 50 LABEL $ 150;
RUN;

%UNIV_ANALYSIS(DATA=&USED_DATASET., VAR=flag_mi, GROUP=GROUP1, N_BAR=10, TYPE_VAR=NUM);
%UNIV_ANALYSIS(DATA=&USED_DATASET., VAR=flag_mi, GROUP=GROUP2, N_BAR=10, TYPE_VAR=NUM);


PROC SQL;
	CREATE TABLE UNIV_ANALYSIS_RESULT AS
		SELECT 
			miss.GROUP
			, COALESCE(miss.TYPE, gini.TYPE) AS TYPE
			, miss.VARIABLE
			, COALESCE(gini.VARIABLE,miss.VARIABLE) AS VARIABLE_SUBTYPE
			, COALESCE(miss.LABEL, gini.LABEL, pctls.LABEL) AS LABEL
			, miss.MISSING
			, miss.NOT_MISSING
			, miss.MISS_PERCENT
			, gini.GINI
			, gini.AUC
			, gini.KS_STAT
			, gini.CORR
			, pctls.Sum
			, pctls.Mean
			, pctls.Mode
			, pctls.StdDev
			, pctls.Min
			, pctls.P1
			, pctls.P5
			, pctls.P25
			, pctls.Median
			, pctls.P75
			, pctls.P95
			, pctls.P99
			, pctls.Max
			, pct_perc.L_BOARDER
			, pct_perc.H_BOARDER
			, pct_perc.L_OUTLIER AS L_OUTLIER_NUM
			, pct_perc.H_OUTLIER AS H_OUTLIER_NUM
			, pct_perc.OUTLIER AS OUTLIER_NUM
			, pct_perc.L_OUTLIER_PERC
			, pct_perc.H_OUTLIER_PERC
			, pct_perc.OUTLIER_PERC
		FROM MISSINGTABLE miss

		LEFT JOIN GINI_KS_CORR_FIN gini
		ON  miss.GROUP = gini.GROUP
		AND miss.VARIABLE = gini.VARIABLE_ORIG
		
		LEFT JOIN LongPctls pctls
		ON  miss.GROUP = pctls.GROUP
		AND miss.VARIABLE = pctls.VARIABLE

		LEFT JOIN OUTLIER_PERC pct_perc
		ON miss.VARIABLE = pct_perc.VARIABLE

	ORDER BY TYPE DESC, VARIABLE, GROUP;

QUIT;

%MACRO PLOT_GINI_TS(DATA, STAT, COND, TITLE);

ods graphics / imagename="&STAT. dev through years &TITLE." reset=index imagefmt=png width = 20cm height = 15cm;
	proc sgplot data=&DATA.(WHERE=(&COND.));
	    series x=GROUP y=&STAT. / group=VARIABLE_SUBTYPE;
		xaxis values=('2017' '2018' '2019' '2020' '2021' 'ALL') ;
		TITLE "&STAT. Development 2017-2021 of &TITLE.";
	run;

	PROC SQL; TITLE; QUIT;

%MEND;

%MACRO PLOT_ALL(DATA, STAT, FLAG);

%IF &FLAG. = ALL_VAR %THEN %DO;

	%IF &STAT. = MISS_PERCENT %THEN %DO;
		PROC SORT DATA=&DATA. OUT=TEMP;
		BY DESCENDING TYPE VARIABLE GROUP;

		PROC SORT DATA=TEMP OUT=TEMP NODUPKEY;
		BY TYPE VARIABLE GROUP;

		DATA TEMP;
		SET TEMP;
			VARIABLE_SUBTYPE = VARIABLE;
		RUN;

		%LET DATA = TEMP;

		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = TYPE="NUM", TITLE=numeric variables);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = (TYPE="CAT" AND VARIABLE NOT IN ("ind_afdl")), TITLE=categorical variables);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = (TYPE="CAT" AND VARIABLE = "ind_afdl"), TITLE=categorical variable ind_afdl);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = TYPE="IND", TITLE=indicator variables);

		PROC SQL; DROP TABLE TEMP; QUIT;

	%END;
	%ELSE %DO;

		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = TYPE="NUM", TITLE=numeric variables);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = VARIABLE="occpy_sts", TITLE=categorical variable occpy_sts);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = VARIABLE="channel", TITLE=categorical variable channel);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = VARIABLE="amrtzn_type", TITLE=categorical variable amrtzn_type);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = VARIABLE="prop_type", TITLE=categorical variable prop_type);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = VARIABLE="loan_purpose", TITLE=categorical variable loan_purpose);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = VARIABLE="ind_afdl", TITLE=categorical variable ind_afdl);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = VARIABLE="us_reg", TITLE=categorical variable us_reg);
		%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = TYPE="IND", TITLE=indicator variables);

	%END;

%END;
%ELSE %IF &FLAG. = NUM_VAR %THEN %DO;

	%PLOT_GINI_TS(DATA=&DATA., STAT=&STAT., COND = TYPE="NUM", TITLE=numeric variables);

%END;
%ELSE %IF &FLAG. = PCTLS %THEN %DO;

PROC SQL NOPRINT;

	SELECT COUNT(*) INTO :TOTAL_NUM TRIMMED FROM VARIABLELIST WHERE TYPE = "NUM";
	SELECT VARIABLE INTO :VAR1-:VAR&TOTAL_NUM. FROM VARIABLELIST WHERE TYPE = "NUM";

QUIT;

	%DO N = 1 %TO &TOTAL_NUM.;
	%PUT ------------ &N. OF &TOTAL_NUM.: &&VAR&N.;
	ods graphics / imagename="pctls dev through years &&VAR&N." reset=index imagefmt=png width = 20cm height = 15cm;
		proc sgplot data=&DATA.(WHERE=(VARIABLE="&&VAR&N."));
		    series x=GROUP y=Mean;
			series X=GROUP Y=StdDev;
			series X=GROUP Y=Min;
			series X=GROUP Y=P1;
			series X=GROUP Y=P5;
			series X=GROUP Y=P25;
			series X=GROUP Y=Median;
			series X=GROUP Y=P75;
			series X=GROUP Y=P95;
			series X=GROUP Y=P99;
			series X=GROUP Y=Max;
			xaxis values=('2017' '2018' '2019' '2020' '2021' 'ALL') ;
			TITLE "PCTLS Development 2017-2021 of &&VAR&N.";
		run;

		PROC SQL; TITLE; QUIT;
	%END;
%END;

%MEND;

%PLOT_ALL(DATA=UNIV_ANALYSIS_RESULT,STAT=MISS_PERCENT, FLAG=ALL_VAR);
%PLOT_ALL(DATA=UNIV_ANALYSIS_RESULT,STAT=GINI, FLAG=ALL_VAR);

%PLOT_ALL(DATA=UNIV_ANALYSIS_RESULT,STAT=KS_STAT, FLAG=NUM_VAR);
%PLOT_ALL(DATA=UNIV_ANALYSIS_RESULT,STAT=CORR, FLAG=NUM_VAR);

%PLOT_ALL(DATA=UNIV_ANALYSIS_RESULT,STAT=, FLAG=PCTLS);

ODS GRAPHICS OFF;