
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
			, woe_iv.WoE
			, woe_iv.IV
			, gini.KS_STAT
			, gini.CORR
			, giniadj.GINI AS GINI_adj
			, giniadj.AUC AS AUC_adj
			, giniadj.KS_STAT AS KS_STAT_adj
			, giniadj.CORR AS CORRadj
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

		LEFT JOIN plot.GINI_KS_CORR_FIN_adjVAR giniadj
		ON miss.GROUP = giniadj.GROUP 
		AND miss.VARIABLE = substr(giniadj.VARIABLE, 1, length(giniadj.VARIABLE)-4)
		
		LEFT JOIN LongPctls pctls
		ON  miss.GROUP = pctls.GROUP
		AND miss.VARIABLE = pctls.VARIABLE

		LEFT JOIN OUTLIER_PERC pct_perc
		ON miss.VARIABLE = pct_perc.VARIABLE

		LEFT JOIN plot.WOE_IV_FIN woe_iv
		ON gini.VARIABLE = woe_iv.VARIABLE

	ORDER BY TYPE DESC, VARIABLE, GROUP;

QUIT;