
DATA &USED_DATASET._FINAL;
SET &USED_DATASET._FINAL;
RUN;

PROC SQL;
    SELECT VARIABLE INTO :num_var SEPARATED BY " " FROM VARIABLELIST WHERE TYPE = "NUM";
QUIT;

%LET num_var = 
	&num_var. 
	fico_ADJ	
	mi_pct_ADJ	
	cnt_units_ADJ	
	cltv_ADJ	
	dti_ADJ	
	orig_upb_ADJ	
	ltv_ADJ	
	cnt_borr_ADJ;

PROC STDIZE DATA=&USED_DATASET._FINAL OUT=&USED_DATASET._FINAL METHOD=STD;
   VAR &NUM_VAR.;
RUN;