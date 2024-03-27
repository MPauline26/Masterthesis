PROC CORR DATA = &USED_DATASET._FINAL OUT=CORRELATION(WHERE=(_TYPE_="CORR")) SPEARMAN;
VAR fico
	cltv
	cltv_adj
	dti
	ltv
	ltv_adj
	cnt_borr;

RUN;

/* VARIABLES cltv_ADJ, ltv, ltv_ADJ removed due to high correlation */

/* VARIABLES channel__R, loan_purpose__P, cd_ppty_val_type__2, us_reg__South not included due to linear combination */

proc reg data=&USED_DATASET._FINAL;
    model DEFAULT_12M = fico dti cltv cnt_borr 
						flag_fthb flag_mi flag_orig_loan_term_HEQ_360M
						channel__9 channel__B channel__C channel__T
						loan_purpose__C loan_purpose__N
						cd_ppty_val_type__1 cd_ppty_val_type__3 cd_ppty_val_type__9
						us_reg__Midwest us_reg__Northeast us_reg__Other us_reg__West
	/ vif;
run;

/*
Final potential model variables:
- fico
- dti
- cltv, cltv_ADJ -> 	correlated to flag_fthb, ltv/ltv_ADJ
						loan_purpose__C, loan_purpose__N, loan_purpose__P, 
						cd_ppty_val_type__1, cd_ppty_val_type__2,
						flag_mi, flag_orig_loan_term_HEQ_360M
						also removed: cd_ppty_val_type__3, cd_ppty_val_type__9
- cnt_borr
- channel__9, channel__B, channel__C, channel__R, channel__T
- us_reg__Midwest, us_reg__Northeast, us_reg__Other, us_reg__South, us_reg__West
*/

/*
	fico
	flag_fthb
	cltv
	cltv_adj
	dti
	ltv
	ltv_adj
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
	flag_orig_loan_term_HEQ_360M;
*/