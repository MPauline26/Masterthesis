
PROC SQL;

	TITLE "DEFAULT RATES OF WHOLE SAMPLE (SINCE 1999)";
	SELECT
		Datum
		,COUNT(*) AS NR
		,SUM(DEFAULT_12M) AS NR_DEF
		,AVG(DEFAULT_12M) AS DR
	FROM final.CT_SAMPLE
	GROUP BY Datum;

	TITLE "DEFAULT RATES OF DEVELOPMENT SAMPLE (SINCE 2017)";
	SELECT
		Datum
		,COUNT(*) AS NR
		,SUM(DEFAULT_12M) AS NR_DEF
		,AVG(DEFAULT_12M) AS DR
	FROM final.DEV_SAMPLE_5Y
	GROUP BY Datum;

	TITLE "DEFAULT RATES OF DEVELOPMENT SAMPLE (SINCE 2018 UNTIL 2020)";
	SELECT
		Datum
		,COUNT(*) AS NR
		,SUM(DEFAULT_12M) AS NR_DEF
		,AVG(DEFAULT_12M) AS DR
	FROM final.DEV_SAMPLE_3Y
	GROUP BY Datum;

	TITLE "DEFAULT RATES OF OUT OF TIME SAMPLE (SINCE 2021)";
	SELECT
		Datum
		,COUNT(*) AS NR
		,SUM(DEFAULT_12M) AS NR_DEF
		,AVG(DEFAULT_12M) AS DR
	FROM final.OOT_SAMPLE_1Y
	GROUP BY Datum;

	TITLE;
QUIT;

