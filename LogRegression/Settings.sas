OPTIONS COMPRESS=YES REUSE=YES;
OPTION ERRORS=0;

libname final 'C:\Users\meikee.pagsinohin\Documents\MA\data_fin';

%LET START_DATE = 199903;
%LET START_DATE_DEV = 201701;
%LET END_DATE = 202112;

PROC IMPORT DATAFILE="C:\Users\meikee.pagsinohin\Documents\MA\VARIABLES.csv"
	OUT=WORK.VARIABLELIST
	DBMS=DLM 
	REPLACE;
	GETNAMES=YES;
	DELIMITER=";";
RUN;

DATA DEV_SAMPLE_5Y;
SET final.DEV_SAMPLE_5Y;
RUN;

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

%label_data(DEV_SAMPLE_5Y, work, VARIABLELIST, Variable, Label);
