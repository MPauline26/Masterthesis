
PROC SQL;

TITLE "ANALYSIS OF flag_fthb - YEARS";
	SELECT 
		GROUP2
		, SUM(flag_fthb)/COUNT(flag_fthb) AS flag_fthb_1_PERC
		, 1-SUM(flag_fthb)/COUNT(flag_fthb) AS flag_fthb_0_PERC
		, AVG(DEFAULT_12M) AS DR FORMAT PERCENT18.6
	FROM &USED_DATASET._FINAL
	GROUP BY GROUP2;

TITLE "ANALYSIS OF flag_fthb - MONTHS";
	SELECT 
		DATUM
		, SUM(flag_fthb)/COUNT(flag_fthb) AS flag_fthb_1_PERC
		, 1-SUM(flag_fthb)/COUNT(flag_fthb) AS flag_fthb_0_PERC
		, AVG(DEFAULT_12M) AS DR FORMAT PERCENT18.6
	FROM &USED_DATASET._FINAL
	GROUP BY DATUM;

QUIT;

%MACRO CAT_VARIABLES_ADD_ANALYSIS(DATA, VAR, FLAG_ANALYSIS);

		PROC SQL;
			SELECT COUNT(DISTINCT &VAR.) INTO :TOTALCAT FROM &DATA.;
			SELECT DISTINCT &VAR. INTO :VALUE1- FROM &DATA.;
		QUIT;

		DATA &DATA.;
		SET &DATA.;

		%DO R = 1 %TO &TOTALCAT.;
			IF &VAR. = "&&VALUE&R." THEN &VAR.__&&VALUE&R. = 1;
			ELSE &VAR.__&&VALUE&R. = 0;
		%END;

		RUN;

	%IF &FLAG_ANALYSIS. = 1 %THEN %DO;

		PROC SQL;

		TITLE "ANALYSIS OF &VAR. - YEARS";
			SELECT 
				GROUP2

				%DO R = 1 %TO &TOTALCAT.;
					, SUM(&VAR.__&&VALUE&R.)/COUNT(&VAR.__&&VALUE&R.) AS &VAR.__&&VALUE&R.._PERC
				%END;

				, AVG(DEFAULT_12M) AS DR FORMAT PERCENT18.6
			FROM &DATA.
			GROUP BY GROUP2;

		TITLE "ANALYSIS OF &VAR. - MONTHS";
			SELECT 
				DATUM

				%DO R = 1 %TO &TOTALCAT.;
					, SUM(&VAR.__&&VALUE&R.)/COUNT(&VAR.__&&VALUE&R.) AS &VAR.__&&VALUE&R.._PERC
				%END;

				, AVG(DEFAULT_12M) AS DR FORMAT PERCENT18.6
			FROM &DATA.
			GROUP BY DATUM;

		TITLE;
		QUIT;

	%END;

%MEND;

%CAT_VARIABLES_ADD_ANALYSIS(DATA=&USED_DATASET._FINAL, VAR=loan_purpose, FLAG_ANALYSIS=1);
%CAT_VARIABLES_ADD_ANALYSIS(DATA=&USED_DATASET._FINAL, VAR=channel, FLAG_ANALYSIS=1);
%CAT_VARIABLES_ADD_ANALYSIS(DATA=&USED_DATASET._FINAL, VAR=cd_ppty_val_type, FLAG_ANALYSIS=1);
%CAT_VARIABLES_ADD_ANALYSIS(DATA=&USED_DATASET._FINAL, VAR=us_reg, FLAG_ANALYSIS=1);

%CAT_VARIABLES_ADD_ANALYSIS(DATA=&USED_DATASET._FINAL, VAR=occpy_sts, FLAG_ANALYSIS=0);

%label_data(&USED_DATASET._FINAL, work, VARIABLELIST, Variable, Label);
