
DATA &USED_DATASET._FINAL;
SET &USED_DATASET._FINAL;
RUN;

PROC SQL;
    SELECT VARIABLE INTO :num_var SEPARATED BY " " FROM VARIABLELIST WHERE TYPE = "NUM";
QUIT;

%LET num_var = &num_var. cltv ltv;

PROC STDIZE DATA=T&USED_DATASET._FINALEST OUT=&USED_DATASET._FINAL METHOD=STD;
   VAR &NUM_VAR.;
RUN;