OPTIONS COMPRESS=YES REUSE=YES;
OPTION ERRORS=0;
OPTION MSGLEVEL=I;

libname final 'C:\Users\meikee.pagsinohin\Documents\MA\data_fin';
libname plot 'C:\Users\meikee.pagsinohin\Documents\MA\plot';

%LET START_DATE = 199903;

%LET START_DATE_DEV_5Y = 201701;
%LET END_DATE_DEV_5Y = 202112;

%LET START_DATE_DEV_3Y = 201801;
%LET END_DATE_DEV_3Y = 202012;

%LET START_DATE_VAL_1Y = 202101;
%LET END_DATE_VAL_1Y = 202112;

*%LET USED_DATASET = DEV_SAMPLE_5Y;
%LET USED_DATASET = DEV_SAMPLE_3Y;
%LET VAL_DATASET = VAL_SAMPLE_1Y;

%LET SELECTED_SPLIT = SELECTED_70_30;
*%LET SELECTED_SPLIT = SELECTED_50_50;
*%LET SELECTED_SPLIT = SELECTED_90_10;

PROC IMPORT DATAFILE="C:\Users\meikee.pagsinohin\Documents\MA\VARIABLES.csv"
	OUT=WORK.VARIABLELIST
	DBMS=DLM 
	REPLACE;
	GETNAMES=YES;
	guessingrows=ALL; 
	DELIMITER=";";
RUN;








/****************************************************************************************************/

/* add the labels */
%macro label_data(data_set, library, ds_labels, column_name, column_label);

* create distinct macro variables for each variable name and label; 
data _null_; 
     set &ds_labels; 
     call symput('var' || trim(left(_N_)), trim(left(&column_name))); 
     call symput('label' || trim(left(_N_)), trim(left(&column_label))); 
     call symput('nobs', trim(left(_N_))); 
run;

* use PROC DATASETS to change the labels;
proc datasets 
     library = &library 
          memtype = data
          nolist; 
     modify &data_set; 
     label 
          %do i = 1 %to &nobs; 
               &&var&i = &&label&i 
          %end; 
     ; 
     quit; 
run; 

%mend;

DATA DEV_SAMPLE_3Y;
SET final.DEV_SAMPLE_3Y;

GROUP1 = "ALL";
GROUP2 = PUT(YEAR(DATUM),4.);

RUN;

%label_data(DEV_SAMPLE_3Y, work, VARIABLELIST, Variable, Label);

DATA DEV_SAMPLE_3Y_FINAL;
SET final.DEV_SAMPLE_3Y_FINAL;
RUN;

%label_data(DEV_SAMPLE_3Y_FINAL, work, VARIABLELIST, Variable, Label);

DATA DEV_SAMPLE_5Y;
SET final.DEV_SAMPLE_5Y;

GROUP1 = "ALL";
GROUP2 = PUT(YEAR(DATUM),4.);

RUN;

%label_data(DEV_SAMPLE_5Y, work, VARIABLELIST, Variable, Label);

DATA DEV_SAMPLE_5Y_FINAL;
SET final.DEV_SAMPLE_5Y_FINAL;
RUN;

%label_data(DEV_SAMPLE_5Y_FINAL, work, VARIABLELIST, Variable, Label);

PROC SQL;
  CREATE INDEX GROUP2 ON DEV_SAMPLE_5Y(GROUP2);
QUIT;