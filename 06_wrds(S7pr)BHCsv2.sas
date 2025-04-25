
%let path=W:\V2;
%let indbpathroot=D:\08_CDW;
%let inpath2compiledbhcs=C:\DW\BHCF2018Q1to2024Q4\bhc;
%let utilsdir=W:\Utils;
%let logdir=W:\V2;
%let pathepu=W:\V2\EPU;
libname FILEPATH "&path";
libname crsp "&indbpathroot\CRSP";
libname bhc "&indbpathroot";
libname bhcfedny "&inpath2compiledbhcs";
libname epu "&pathepu";


/*
%let path=D:\Newfolder\V2;
%let indbpathroot=D:\02_Economic\00_FINDATA;
%let inpath2compiledbhcs=D:\Newfolder\BHCF2018Q1to2024Q4\bhc;
%let utilsdir=D:\Newfolder\Utils;
%let logdir=D:\Newfolder\V2;
libname FILEPATH "&path";
libname crsp "&indbpathroot\CRSP";
libname bhc "&indbpathroot\BANK\06_WRDS";
libname bhcfedny "&inpath2compiledbhcs";
*/


%let logfilename=bhccrsp20250408a;
%include "&utilsdir./frank.sas";
%include "&utilsdir./numutils.sas";
%include "&utilsdir./charutils.sas";
%include "&utilsdir./truefalseutils.sas";


*logging out the program running info into a file;
proc printto log="&logdir./&logfilename..log";
run;


/*
WARNING: Multiple lengths were specified for the variable BHTXF656 by input data set(s). This can
         cause truncation of data.
*/
%let varstosync=BHTXF656:74;
%vars_to_char(varpluslengths=&varstosync, varslonglength=NULLNULL, lib=bhc, dset=bhcf8617wrds);


data bhc.bhcf8624sas;
set bhc.bhcf8617wrds bhcfedny.bhcf1824sas;
run;


data bhc.bhcf8624sasa (index=(rssd9001 rssd9999 prim_key=(rssd9001 rssd9999) 
		bhck2170 bhck2122 bhck4230));
	keep bhcb2210 bhcb2389 bhcb2604 bhcb3187 bhcb6648 bhck0081 bhck0213 bhck0276 
		bhck0277 bhck0278 bhck0279 bhck0395 bhck0397 bhck0400 bhck1287 bhck1350 
		bhck1403 bhck1407 bhck1410 bhck1590 bhck1616 bhck1655 bhck1763 bhck1764 
		bhck2008 bhck2011 bhck2122 bhck2170 bhck2800 bhck2948 bhck3163 bhck3164 
		bhck3165 bhck3210 bhck3283 bhck3506 bhck3507 bhck4070 bhck4074 bhck4076 
		bhck4077 bhck4078 bhck4079 bhck4093 bhck4150 bhck4230 bhck4340 bhck4399 
		bhck4483 bhck5506 bhck5507 bhck5525 bhck5526 bhck8560 bhck8561 bhcka220 
		bhckb490 bhckb491 bhckb492 bhckb493 bhckb494 bhckb496 bhckb497 bhckb538 
		bhckb539 bhckb989 bhckb995 bhckc386 bhckc387 bhckc886 bhckc887 bhckc888 
		bhck3123 bhck3521 bhck3196 bhck8434 bhck4107 bhck4073 
        bhck0211 bhck1289 bhck1293 bhck1298 
        bhdma243 bhdma242 bhck2309 bhck2332 
        bhck3814 bhck3816 bhck3817 bhck6550 bhck6566 bhck3820 bhck6570 bhck3822 
        bhck3411 bhckb557 
        bhckb529 bhck3545 bhck1773 bhckb985 bhck2145 
        bhck0426 bhck2160 
        bhcp3298 bhckc699 bhckg105 
		bhdm6631 bhdm6636 bhdmb987 bhdmb993 bhfn6631 bhfn6636 bhod2389 bhod2604 
		bhod3187 bhod3189 bhod6648 rssd9001 rssd9005 rssd9010 rssd9017 rssd9028 
		rssd9032 rssd9130 rssd9200 rssd9346 rssd9999 
        BHCK4635 BHCK4605 
        BHCKK137 BHCKK207
        BHCK8274 BHCA8274 BHCAA223 BHCKA223;
	set bhc.bhcf8624sas;
run;

/*
proc sql noprint;
	create index rssd9001 on bhc.bhcf8624sasa;
	create index rssd9999 on bhc.bhcf8624sasa;
	create index prim_key on bhc.bhcf8624sasa(rssd9001,rssd9999);
	create index bhck2170 on bhc.bhcf8624sasa;
	create index bhck2122 on bhc.bhcf8624sasa;
	create index bhck4230 on bhc.bhcf8624sasa;
quit;
*/


/*The CRSP_FRB link file contains both BHCs and CBs. 
The BHCFWRD is a BHC dataset. Some entities in the link file are BHCs, although their inst_types are 'Commmercial Bank'! and rssd9001s are in BHCFWRD.
That is why the BHCs in the link file have to be filtered out by merging with BHCFWRD.
*/
proc sql; 
	create view crsp.crspdfrblink24q42 as
	select * 
	from crsp.crspdfrblink24q4 
	where entity in (select distinct rssd9001 from bhc.bhcf8624sasa);
quit;


/*FORMATINGfiltering the neccesary variables and transforming date info*/
proc sql; 
	create view bhc.bhcf8624sasb as 
	select year(input(put(rssd9999,8.),yymmdd8.)) as year, 
		cats('Q',qtr(input(put(rssd9999,8.),yymmdd8.))) as quarter, 
		rssd9001, rssd9999, rssd9130, rssd9005, rssd9032, rssd9200, 
		rssd9028, rssd9017, rssd9010, rssd9346, bhck4150, 
		bhck2170 /*TA :: Total Assets*/, 
        bhck3210 /*TE :: Total Equity Capital*/, 
		/*TCE ratio*/ 
		bhck2948, bhck3163, bhck3164, bhck3165, bhck5506, bhck5507, 
		bhck3283/*, bhck3163, bhck3164, bhck3165, bhck5506, bhck5507: already selected in the preceeding line*/ 
		/*TCE ratio*/, 
		bhck2122 /*TL :: Total Loan*/, 
		/*bhck4079 + bhck4074 TI :: Total Income*/ 
		bhck4107 /*TII :: Total Interest Income*/, 
		bhck4073 /*TIE :: Total Interest Expense*/, 
		bhdm6631, bhdm6636, bhfn6631, bhfn6636 /*TD :: Total Deposit*/,
        /*----------NPL calculation - begin ---------------------------------------------*/
		bhck5525, bhck3506, bhck5526, bhck3507, bhck1616, bhck1407, bhck1403 /*NPL: 
		Nonperforming loan = Total Loans, Leasing Financing Receivables ( (Nonaccrual) and  (past due >= 90 days and still accruing) )
		Notes: bhck5525 and bhck5526 are no longer available from 2018Mar31.
		BHCK5525 1990-09-30	2017-12-31 TOTAL LOANS, LEASING FINANCING RECEIVABLES AND DEBT SECURITIES 
		AND OTHER ASSETS - PAST DUE 90 DAYS OR MORE AND STILL ACCRUING No FR Y-9C
		BHCK5526 1990-09-30	2017-12-31 TOTAL LOANS, LEASING FINANCING RECEIVABLES AND DEBT SECURITIES 
		AND OTHER ASSETS - NONACCRUAL No FR Y-9C
		They can be represented by their components, bhck1407, and bhck1403, for the unavailable period 
		from 1985Jun30 - 1990Jun30, and 2018Mar31 - the present.
		BHCK1407 1985-06-30 1990-06-30 TOTAL LOANS AND LEASE FINANCING RECEIVABLES: PAST DUE 90 DAYS OR MORE AND STILL ACCRUING	No FR Y-9C
		BHCK1407 2018-03-31 9999-12-31 TOTAL LOANS AND LEASE FINANCING RECEIVABLES: PAST DUE 90 DAYS OR MORE AND STILL ACCRUING	No FR Y-9C
		BHCK1403 1985-06-30	1990-06-30 TOTAL LOANS AND LEASE FINANCE RECEIVABLES: NONACCRUAL No	FR Y-9C
		BHCK1403 2018-03-31	9999-12-31 TOTAL LOANS AND LEASE FINANCE RECEIVABLES: NONACCRUAL No	FR Y-9C
		*/, 
		/*
		sum(a nonmissing value, a missing value) = the nonmissing value;
		sum(a missing value, a missing value) = a missing value, and causes a NOTE like: 
			NOTE: Invalid (or missing) arguments to the SUM function have caused the function to return a missing value.
		*/
		case /*these two following dates have no relationship with the two main dates of setting the time boundary of the final sample */
			when rssd9999 <= 19900630 or rssd9999 >= 20180331 then 
				sum(bhck1407,bhck1403,bhck1616)
			else 
				sum(bhck5525,-1*bhck3506,bhck5526,-1*bhck3507,bhck1616) 
		end as NPLnum, 
        /*----------NPL calculation - end ---------------------------------------------*/
		bhck4093, bhck4074, bhck4079 /*Cost-to-Income*/, 
		bhck4340/*, bhck3210: already selected at Total Equity Capital*/ /*ROE*/, 
        /*bhck4340, bhck2170 /*ROA*/ 
		bhck0081, bhck0395, bhck0397, bhck0276, bhck0277, bhck0278, bhck0279, bhck0400 /*LiquidAssets2TA*/, 
		bhck0213, bhck1287 /*LiquidAssets2TA*/, 
		bhck1350, bhck2800 /*LiquidAssets2TA*/, 
		bhdmb987, bhckb989, bhdmb993, bhckb995 /*LiquidAssets2TA*/, 
		bhcb2210, bhod3189/*, bhfn6631: already selected at 'Total Deposit'*/ /*Non-Interest bearing Deposit*/,
		bhcb3187, bhod3187, bhcb2389, bhod2389, bhcb6648, bhod6648 /*Interest bearing Deposit*/, 
		bhcb2604, bhod2604 /*Wholesale funding*/, 
		bhck1763, bhck1764 /*Commercial and Industrial Loan*/, 
		bhck1410 /*Real Estate Loan*/, 
		bhck1590 /*Agricultural Loan*/, 
		bhck2008, bhck2011 /*Comsumer Loan*/, /*see */  
        /*
		2021 - Hegde for this modification
		*/
		case
			when rssd9999 <= 20001231 then 
				sum(BHCK2008,BHCK2011)
            when rssd9999 >= 20010101 and rssd9999 <= 20101231 then 
                sum(BHCKB538,BHCKB539,BHCK2011)
			else 
				sum(BHCKB538,BHCKB539,BHCKK137,BHCKK207) 
		end as CONSnum, 
		bhckb538, bhckb539/*, /*bhck2011: already selected at 'Comsumer Loan'*/ /*Comsumer Loan*//*, 
		bhck4079: already selected at 'cost-to-income'*/ /*NonInterest Income*//*,  
		bhck4074: already selected at 'cost-to-income'*/ /*Net Interest Income*/, 
		bhck4070 /*Fiduciary Activities Income*/, 
		bhck1655, bhck4077, bhcka220, bhck4076 /*Trading Revenue*/, 
		bhck4483 /*Service Charges on Deposit Accounts*/, 
		bhck4078, bhck4399 /*Other noninterest Income*/, 
		bhck8560, bhck8561, bhckb490, bhckb491, bhckb492, bhckb493, bhckb494, bhckb496, bhckb497 /*Other noninterest Income*//*, 
		/*bhck8560, bhck8561: already selected in the preceeding line*/, bhckc386, bhckc387 /*Other noninterest Income*/, 
		bhckc886, bhckc888, bhckc887 /*Other noninterest Income*/, 
		/*(TL - TD) / TA :: Deposit Funding Gap*/
		/*Income diversification*/
		/*bhck4074, bhck4079,: already selected at 'Cost-to-Income'*/ /*bhck4070,:already selected at 'Fiduciary Activities Income'*/ 
		/*bhck4483,: already selected at 'Service Charges on Deposit Accounts'*/ 
		/*bhcka220,: already selected at 'Tranding Revenue'*/ 
		/*bhckc886, bhckc888, bhckc887, bhckc386, bhckc387, bhckb491, bhckb492, bhckb493,
		bhck8560, bhck8561, bhckb496, bhckb497,: already selected at 'Other NonInterest Income*/  
		bhck4230 , 
		bhck3123, bhck3521, bhck3196, bhck8434, 
 		/*bhck4107,: already selected at 'Total Interest Income*/ /*bhck4073,: already selected at Total Interest Expense*/

        /*LCR_Numerator_data items*/ 
        /*bhck0081 bhck0395 bhck0397*/ bhck0211, /*bhck1287 bhdmb987*/ bhck1289, 
        /*bhck2948*/ bhck1293, bhck1298, 
        
        /*LCR_Denominator_data items*/
        bhdma243, bhdma242, /*bhfn6631 bhfn6636 bhdmb993 bhckb995*/ bhck2309, bhck2332, 
        bhck3814, bhck3816, bhck3817, bhck6550, bhck6566, bhck3820, bhck6570, bhck3822, 
        bhck3411, bhckb557, /*bhckb989*/
        
        /*NSFR_asset_data items*/ 
        bhckb529, /*bhdmb987 bhckb989*/ bhck3545, bhck1773, bhckb985, bhck2145, /*bhck3163*/ 
        bhck0426, bhck2160, 
  
        /*NSFR_liability_data items*/ 
        /*bhcb2210 bhcb2389 bhcb2604 bhod6648*/ bhcp3298, bhckc699, /*bhdm6631 bhfn6631 bhck3123*/ bhckg105, 

		/*Charge-offs and Recoveries for Loan Loss Provisions*/ 
		BHCK4635, BHCK4605,
        
        /*Tier1 Capital ratio : 
            TIER 1 CAPITAL ALLOWABLE UNDER THE RISK-BASED CAPITAL GUIDELINES / 
                RISK-WEIGHTED ASSETS (NET OF ALLOWANCES AND OTHER DEDUCTIONS)
        */
        case 
			when rssd9999 <= 20140331 then BHCK8274
            when rssd9999 >= 20140401 and rssd9999 <= 20141231 then 
            case 
                when BHCK8274 ^= . then BHCK8274
                else BHCA8274
            end     
			else BHCA8274
		end as Tier1CAP, 
        
        case 
			when rssd9999 <= 20140331 then BHCKA223
            when rssd9999 >= 20140401 and rssd9999 <= 20141231 then 
            case 
                when BHCKA223 is not NULL then BHCKA223
                else BHCAA223
            end     
			else BHCAA223
		end as RskwgtASSET, 
        
        (calculated Tier1CAP) / (calculated RskwgtASSET) as T1CAPRatio,
        
        (calculated Tier1CAP) / BHCK2122 as T1CAPLoanRatio
        
	from bhc.bhcf8624sasa 
	where rssd9999 between 19860930 and 20240930 
		and bhck2170 is not null 
		and bhck2122 ne 0 
	order by rssd9001, year, quarter;
quit;


data bhc.bhcf8624sasb1;
set bhc.bhcf8624sasb;
IDX=_N_;
run;


/*
creating indexes on views is not allowed.
proc sql noprint;
	create index rssd9001 on bhc.bhcf8624sasb;
	create index year on bhc.bhcf8624sasb;
	create index rssd9001year on bhc.bhcf8624sasb(rssd9001,year);
quit;
*/
	

/*Technical note: 
sum(bhck4074true,bhck4079true) as TotOITrue does not work with the bhck4074true and 
bhck4079true created from calculation expressions. Error messages like 
'ERROR: The following columns were not found in the contributing tables: bhck4074true, bhck4079true. 
The S engine was looking up the bhck4074true and bhck4079true in the contributing tables rather than 
the selected variables. Alias however work well as LAG1_bhck2122, and the following lagged variable. 
A new view is necessary to use the true varibles in calculation expressions.
*/
proc sql;
	create table bhc.bhcf8624sasc as
		select  BASE.*, 
			LAG1.bhck2170 as LAG1_bhck2170, 
			(BASE.bhck2170 - LAG1_bhck2170)/LAG1_bhck2170 as GrTA, 
			LAG1.bhck2122 as LAG1_bhck2122, 
			(BASE.bhck2122 - LAG1_bhck2122)/LAG1_bhck2122 as GrLoans,
			LAG1.bhck4230 as LAG1_bhck4230, 
			/*Diversification main measures*/ 
			LAG1.bhck4074 as LAG1_bhck4074, /*NET INTEREST INCOME*/ 
			LAG1.bhck4079 as LAG1_bhck4079, /*TOTAL NON-INTEREST INCOME*/
			LAG1.bhck4070 as LAG1_bhck4070, /*Total Income from fiduciary activities*/
			LAG1.bhck4483 as LAG1_bhck4483, /*Service charges on deposit accounts in domestic offices*/
			LAG1.bhcka220 as LAG1_bhcka220, /*trading revenue*/
			LAG1.bhckc886 as LAG1_bhckc886, /*fees and commissions from securities brokerage*/
			LAG1.bhckc888 as LAG1_bhckc888, /*Investment banking, advisory, and underwriting fees and commissions*/
			LAG1.bhckc887 as LAG1_bhckc887, /*Fees and commissions from annuity sales*/
			LAG1.bhckc386 as LAG1_bhckc386, /*Underwriting income from insurance and reinsurance activities*/
			LAG1.bhckc387 as LAG1_bhckc387, /*Income from other insurance activities*/
			LAG1.bhckb491 as LAG1_bhckb491, /*VENTURE CAPITAL REVENUE*/
			LAG1.bhckb492 as LAG1_bhckb492, /*NET SERVICING FEES*/
			LAG1.bhckb493 as LAG1_bhckb493, /*NET SECURITIZATION INCOME */
			LAG1.bhck8560 as LAG1_bhck8560, /*Net gains (losses) on sales of loans and leases*/
			LAG1.bhck8561 as LAG1_bhck8561, /*Net gains (losses) on sales of other real estate owned*/
			LAG1.bhckb496 as LAG1_bhckb496, /*NET GAINS (LOSSES) ON SALES OF OTHER ASSETS (EXCLUDING SECURITIES)*/
			LAG1.bhckb497 as LAG1_bhckb497, /*OTHER NONINTEREST INCOME*/ 
			BASE.bhck4074 - LAG1_bhck4074 as bhck4074true, 
			BASE.bhck4079 - LAG1_bhck4079 as bhck4079true, 
			BASE.bhck4070 - LAG1_bhck4070 as bhck4070true, 
			BASE.bhck4483 - LAG1_bhck4483 as bhck4483true, 
			BASE.bhcka220 - LAG1_bhcka220 as bhcka220true, 
			BASE.bhckc886 - LAG1_bhckc886 as bhckc886true, 
			BASE.bhckc888 - LAG1_bhckc888 as bhckc888true, 
			BASE.bhckc887 - LAG1_bhckc887 as bhckc887true, 
			BASE.bhckc386 - LAG1_bhckc386 as bhckc386true, 
			BASE.bhckc387 - LAG1_bhckc387 as bhckc387true, 
			BASE.bhckb491 - LAG1_bhckb491 as bhckb491true, 
			BASE.bhckb492 - LAG1_bhckb492 as bhckb492true, 
			BASE.bhckb493 - LAG1_bhckb493 as bhckb493true, 
			BASE.bhck8560 - LAG1_bhck8560 as bhck8560true, 
			BASE.bhck8561 - LAG1_bhck8561 as bhck8561true, 
			BASE.bhckb496 - LAG1_bhckb496 as bhckb496true, 
			BASE.bhckb497 - LAG1_bhckb497 as bhckb497true, 
            
            /**************************************************/
            /*****THE FIRST GROUP OF MEASURE CONSTRUCTIONS,*****/
            /*****TYPICALLY FOR LAG OPERATIONS OF UP TO 4*****/
            /**************************************************/

			/*Total operating income = Total Net II + Total Non II*/
			sum(calculated bhck4074true,calculated bhck4079true) as TotOITrue, 

			/*10. Total net interest income (II)*/
			calculated bhck4074true as dvTotII, 

			/*Non-interest incomes
			11. commission income (CI)*/
			/*Note: missing values are automatically removed from the operation when taking a SUM function.
			But it is not if the values are added together by "+" operator.
			For example: 1 + . = . ; sum(1,.) = 1 ; . - 1 = . ; sum(.,-1*1) = -1 ; 1 - . = . ; sum(1,-1*.) = 1*/
			sum(calculated bhck4070true,
			    calculated bhck4483true,
			    calculated bhckc886true,
			    calculated bhckc888true,
			    calculated bhckc887true,
			    calculated bhckc386true,
			    calculated bhckc387true,
			    calculated bhckb492true) as dvCI,

			/*12. Net profit from other operations (NPFO)*/
			sum(calculated bhcka220true,
				calculated bhckb491true,
				calculated bhckb493true,
				calculated bhck8560true,
				calculated bhck8561true,
				calculated bhckb496true) as dvNPFO, 

			/*13. Other non-interest income (ONII)*/
			/*BASE.BHCKB497True as dvONII*/

			sum(calculated TotOITrue, 
				(-1)*(calculated dvTotII), 
				(-1)*(calculated dvCI), 
				(-1)*(calculated dvNPFO)) as dvONII, 

			/*Income diversification (IDIV)*/
			(1 - sum((calculated dvTotII/calculated TotOITrue)**2,
			        (calculated dvCI/calculated TotOITrue)**2,
			        (calculated dvNPFO/calculated TotOITrue)**2,
			        (calculated dvONII/calculated TotOITrue)**2)) as dvIDIV,   
			/*END: Diversification main measures*/

			sum(BASE.bhck3521, BASE.bhck3196) as RSGL, 
			BASE.bhck8434 as UrSGL, 

			BASE.bhck4074/BASE.bhck2170 as NetInterestMargin, 
			BASE.bhck4107/BASE.bhck2170 as NIMTII, 
			BASE.bhck4073/BASE.bhck2170 as NIMTIE, 
			LAG1.bhck4074/LAG1.bhck2170 as LAG1_NIM,
			LAG1.bhck4107/LAG1.bhck2170 as LAG1_NIMTII, 
			LAG1.bhck4073/LAG1.bhck2170 as LAG1_NIMTIE, 
 
			(calculated NetInterestMargin - calculated LAG1_NIM)/calculated LAG1_NIM as GrNIM, 
			(calculated NIMTII - calculated LAG1_NIMTII)/calculated LAG1_NIMTII as GrNIMTII, 
			(calculated NIMTIE - calculated LAG1_NIMTIE)/calculated LAG1_NIMTIE as GrNIMTIE, 
			BASE.bhck4093/sum(BASE.bhck4107, BASE.bhck4079) as Efficiency, 
			sum(BASE.bhck4107, BASE.bhck4079) as Revenue, 
			BASE.bhck4093 as NonInterestExpense, 
			(calculated Revenue - LAG1.Revenue)/LAG1.Revenue as GrRevenue,
			(BASE.bhck4093 - LAG1.bhck4093)/LAG1.bhck4093 as GrNonInterestExpense, 
			(calculated GrRevenue - calculated GrNonInterestExpense) as OperatingLeverage, 

            /*LCR_Numerator_data items*/ 
            sum(BASE.bhck0081, BASE.bhck0395, BASE.bhck0397, BASE.bhck0211, BASE.bhck1287, 
				BASE.bhdmb987, BASE.bhck1289, BASE.bhck2948, BASE.bhck1293, BASE.bhck1298) as LCRStockOfHQLA, 
            
            /*LCR_Denominator_data items*/
            sum(0.03*sum(BASE.bhck1293, BASE.bhck1298, -1*BASE.bhdma243, -1*BASE.bhdma242), 
                0.1*sum(BASE.bhfn6631, BASE.bhfn6636, BASE.bhdma243, BASE.bhdma242), 
                BASE.bhdmb993, BASE.bhckb995, BASE.bhck2309, BASE.bhck2332, 
                BASE.bhck3814, BASE.bhck3816, BASE.bhck3817, BASE.bhck6550, 
                BASE.bhck6566, BASE.bhck3820, 
                BASE.bhck6570, BASE.bhck3822, 
                BASE.bhck3411, 
                BASE.bhckb557) as LCROutflow, 
                
            BASE.bhckb989 as LCRInFlow, 
            max(calculated LCROutflow - BASE.bhckb989, 0.25*(calculated LCROutflow)) as LCRNetCashOutflows, 
            (calculated LCRStockOfHQLA/calculated LCRNetCashOutflows) as LCR, 
            
            /***2021 - Hegde, all loan loss provision measures by 100 to enhance the readability of coefficients in regression analyses***/
            100*BASE.BHCK4230/BASE.BHCK2122 as LLP2, /*LLP scaled by TotalLoans*/
            100*sum(BASE.BHCK4230,-1*BASE.BHCK4635,BASE.BHCK4605)/BASE.BHCK2122 as ALLP2, /*primary adjusted LLP2 (used to estimate DiscretionaryLLP, 2021 - Hegde), as Provision for loan losses - gross charge-offs + recoveries, to avoid estimating a mechanical relation given the direct impact of charge-offs on loan loss reserves*/
            100*sum(BASE.BHCK4230,BASE.BHCK4605)/BASE.BHCK2122 as ALLP2r, /*secondary adjusted LLP2, (used to estimate DiscretionaryLLP, 2021 - Hegde), as loan loss provisions plus recoveries*/
            
            100*BASE.BHCK4230/LAG1.bhck2122 as LLP2lag, /*LLP scaled by lagged TotalLoans*/
            100*sum(BASE.BHCK4230,-1*BASE.BHCK4635,BASE.BHCK4605)/LAG1.bhck2122 as ALLP2lag, /*primary adjusted LLP2 (used to estimate DiscretionaryLLP, 2021 - Hegde), as Provision for loan losses - gross charge-offs + recoveries, to avoid estimating a mechanical relation given the direct impact of charge-offs on loan loss reserves*/
            100*sum(BASE.BHCK4230,BASE.BHCK4605)/LAG1.bhck2122 as ALLP2rlag, /*secondary adjusted LLP2, (used to estimate DiscretionaryLLP, 2021 - Hegde), as loan loss provisions plus recoveries*/
            
			100*BASE.bhck3123/BASE.BHCK2122 as LLR2, /*Allowance for loan losses (loan loss reserves) scaled by total loans*/
            
            BASE.CONSnum/BASE.BHCK2122 as ConsumerLoansShare, /*1-s2.0-S1062940814000540-mmc1 and 2021-Hegde: OK*/
			(calculated ConsumerLoansShare) as CONS,
            
            sum(BASE.bhck1763,BASE.bhck1764)/BASE.bhck2122 as TotalCandILoansShare, /*1-s2.0-S1062940814000540-mmc1 and 2021-Hegde: OK*/
            BASE.bhck1410/BASE.bhck2122 as RealEstateLoansShare
            
		from (select * from bhc.bhcf8624sasb1) BASE
		left join (select *, sum(bhck4107, bhck4079) as Revenue  
					from bhc.bhcf8624sasb1) LAG1
			on BASE.rssd9001=LAG1.rssd9001 
			/*and BASE.year=LAG1.year: use this condition when we want to 
			take the lag within one year, i.e. the lag at the first quarter 
			is unavailable (or missing)*/
			and BASE.IDX=LAG1.IDX+1;
quit;


proc import out= bhc.aggloangrowth datafile="&path/AggregatedLoanGrowth.csv" dbms=csv replace; guessingrows=130; run;


proc sql;
	create view bhc.bhcf8624sasc1 as
		select  BASE.*, 
                AGG.All_Institutions/100 as AggGrLoans, 
                (BASE.GrLoans - calculated AggGrLoans) as AbGrLoans 
		from bhc.bhcf8624sasc BASE
		left join bhc.aggloangrowth AGG
			on BASE.year=AGG.year and BASE.quarter=AGG.quarter
		order by BASE.rssd9001, BASE.year, BASE.quarter;
quit;


/*
proc sql noprint;
	create index rssd9001 on bhc.bhcf8624sasc;
	create index year on bhc.bhcf8624sasc;
	create index rssd9001year on bhc.bhcf8624sasc(rssd9001,year);
quit;
*/
proc sql;
	create table bhc.bhcf8624sasd (drop=LAG1_bhck4074 LAG1_bhck4079 LAG1_bhck4070 
			LAG1_bhck4483 LAG1_bhcka220 LAG1_bhckc886 LAG1_bhckc888 LAG1_bhckc887 
			LAG1_bhckc386 LAG1_bhckc387 LAG1_bhckb491 LAG1_bhckb492 LAG1_bhckb493 
			LAG1_bhck8560 LAG1_bhck8561 LAG1_bhckb496 LAG1_bhckb497 bhck4074true 
			bhck4079true bhck4070true bhck4483true bhcka220true bhckc886true bhckc888true 
			bhckc887true bhckc386true bhckc387true bhckb491true bhckb492true bhckb493true 
			bhck8560true bhck8561true bhckb496true bhckb497true) as 
		select  BASE.*, 
			LAG1.GrTA as LAG1_GrTA, 
			LAG2.GrTA as LAG2_GrTA, 
			LAG3.GrTA as LAG3_GrTA, 
			LAG4.GrTA as LAG4_GrTA, 

			LAG1.GrLoans as LAG1_GrLoans, 
			LAG2.GrLoans as LAG2_GrLoans, 
			LAG3.GrLoans as LAG3_GrLoans, 
			LAG4.GrLoans as LAG4_GrLoans, 

			LAG1.AbGrLoans as LAG1_AbGrLoans, 
			LAG2.AbGrLoans as LAG2_AbGrLoans, 
			LAG3.AbGrLoans as LAG3_AbGrLoans, 
			LAG4.AbGrLoans as LAG4_AbGrLoans, 
			LAG5.AbGrLoans as LAG5_AbGrLoans, 
			LAG6.AbGrLoans as LAG6_AbGrLoans, 
			LAG7.AbGrLoans as LAG7_AbGrLoans, 
			LAG8.AbGrLoans as LAG8_AbGrLoans, 
			LAG9.AbGrLoans as LAG9_AbGrLoans, 
			LAG10.AbGrLoans as LAG10_AbGrLoans, 
			LAG11.AbGrLoans as LAG11_AbGrLoans, 
			LAG12.AbGrLoans as LAG12_AbGrLoans, 

			LAG1.bhck4230 as LAG1_LoanLossProvision, 
			LAG2.bhck4230 as LAG2_LoanLossProvision, 
			LAG3.bhck4230 as LAG3_LoanLossProvision, 
			LAG4.bhck4230 as LAG4_LoanLossProvision, 

			LAG1.bhck3123 as LAG1_LoanLossAllowance, 
			LAG2.bhck3123 as LAG2_LoanLossAllowance, 
			LAG3.bhck3123 as LAG3_LoanLossAllowance, 
			LAG4.bhck3123 as LAG4_LoanLossAllowance, 

			LAG1.RSGL as LAG1_RSGL, 
			LAG2.RSGL as LAG2_RSGL, 
			LAG3.RSGL as LAG3_RSGL, 
			LAG4.RSGL as LAG4_RSGL, 

			LAG1.UrSGL as LAG1_UrSGL, 
			LAG2.UrSGL as LAG2_UrSGL, 
			LAG3.UrSGL as LAG3_UrSGL, 
			LAG4.UrSGL as LAG4_UrSGL,

			LAG1.NetInterestMargin as LAG1_NetInterestMargin, 
			LAG2.NetInterestMargin as LAG2_NetInterestMargin, 
			LAG3.NetInterestMargin as LAG3_NetInterestMargin, 
			LAG4.NetInterestMargin as LAG4_NetInterestMargin, 

			LAG1.GrNIM as LAG1_GrNIM, 
			LAG2.GrNIM as LAG2_GrNIM, 
			LAG3.GrNIM as LAG3_GrNIM, 
			LAG4.GrNIM as LAG4_GrNIM, 

			/*LAG1.NIMTII as LAG1_NIMTII, : already calculated in the previous steps*/
			LAG2.NIMTII as LAG2_NIMTII, 
			LAG3.NIMTII as LAG3_NIMTII, 
			LAG4.NIMTII as LAG4_NIMTII, 

			LAG1.GrNIMTII as LAG1_GrNIMTII, 
			LAG2.GrNIMTII as LAG2_GrNIMTII, 
			LAG3.GrNIMTII as LAG3_GrNIMTII, 
			LAG4.GrNIMTII as LAG4_GrNIMTII, 

			/*LAG1.NIMTIE as LAG1_NIMTIE, : already calculated in the previous steps*/
			LAG2.NIMTIE as LAG2_NIMTIE, 
			LAG3.NIMTIE as LAG3_NIMTIE, 
			LAG4.NIMTIE as LAG4_NIMTIE, 

			LAG1.GrNIMTIE as LAG1_GrNIMTIE, 
			LAG2.GrNIMTIE as LAG2_GrNIMTIE, 
			LAG3.GrNIMTIE as LAG3_GrNIMTIE, 
			LAG4.GrNIMTIE as LAG4_GrNIMTIE, 

			LAG1.Efficiency as LAG1_Efficiency, 
			LAG2.Efficiency as LAG2_Efficiency, 
			LAG3.Efficiency as LAG3_Efficiency, 
			LAG4.Efficiency as LAG4_Efficiency, 

			LAG1.OperatingLeverage as LAG1_OperatingLeverage, 
			LAG2.OperatingLeverage as LAG2_OperatingLeverage, 
			LAG3.OperatingLeverage as LAG3_OperatingLeverage, 
			LAG4.OperatingLeverage as LAG4_OperatingLeverage,   
            
            LAG1.LLP2 as LAG1_LLP2, 
			LAG2.LLP2 as LAG2_LLP2, 
			LAG3.LLP2 as LAG3_LLP2, 
			LAG4.LLP2 as LAG4_LLP2,   
            
            LAG1.LLP2lag as LAG1_LLP2lag, 
			LAG2.LLP2lag as LAG2_LLP2lag, 
			LAG3.LLP2lag as LAG3_LLP2lag, 
			LAG4.LLP2lag as LAG4_LLP2lag,   
            
            LAG1.ALLP2 as LAG1_ALLP2, 
			LAG2.ALLP2 as LAG2_ALLP2, 
			LAG3.ALLP2 as LAG3_ALLP2, 
			LAG4.ALLP2 as LAG4_ALLP2,   
            
            LAG1.ALLP2lag as LAG1_ALLP2lag, 
			LAG2.ALLP2lag as LAG2_ALLP2lag, 
			LAG3.ALLP2lag as LAG3_ALLP2lag, 
			LAG4.ALLP2lag as LAG4_ALLP2lag,   
            
            LAG1.ALLP2r as LAG1_ALLP2r, 
			LAG2.ALLP2r as LAG2_ALLP2r, 
			LAG3.ALLP2r as LAG3_ALLP2r, 
			LAG4.ALLP2r as LAG4_ALLP2r, 
            
            LAG1.ALLP2rlag as LAG1_ALLP2rlag, 
			LAG2.ALLP2rlag as LAG2_ALLP2rlag, 
			LAG3.ALLP2rlag as LAG3_ALLP2rlag, 
			LAG4.ALLP2rlag as LAG4_ALLP2rlag, 

			LAG1.LLR2 as LAG1_LLR2, 
			LAG2.LLR2 as LAG2_LLR2, 
			LAG3.LLR2 as LAG3_LLR2, 
			LAG4.LLR2 as LAG4_LLR2,
            
            LAG1.CONS as LAG1_CONS, 
			LAG2.CONS as LAG2_CONS, 
			LAG3.CONS as LAG3_CONS, 
			LAG4.CONS as LAG4_CONS,
            
            LAG1.NPLnum/BASE.LAG1_bhck2122 as LAG1_NPL,
            
            LAG1.RealEstateLoansShare/BASE.LAG1_bhck2122 as LAG1_RE,
            
            LAG1.TotalCandILoansShare/BASE.LAG1_bhck2122 as LAG1_CI,
            
            LAG1.T1CAPRatio as LAG1_T1CAPRatio, 
			LAG2.T1CAPRatio as LAG2_T1CAPRatio, 
			LAG3.T1CAPRatio as LAG3_T1CAPRatio, 
			LAG4.T1CAPRatio as LAG4_T1CAPRatio,
            
            LAG1.T1CAPLoanRatio as LAG1_T1CAPLoanRatio, 
			LAG2.T1CAPLoanRatio as LAG2_T1CAPLoanRatio, 
			LAG3.T1CAPLoanRatio as LAG3_T1CAPLoanRatio, 
			LAG4.T1CAPLoanRatio as LAG4_T1CAPLoanRatio
             
		from (select * from bhc.bhcf8624sasc1) BASE
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio
					from bhc.bhcf8624sasc1) LAG1
			on BASE.rssd9001=LAG1.rssd9001 
			/*and BASE.year=LAG1.year*/
			and BASE.IDX=LAG1.IDX+1
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio  
					from bhc.bhcf8624sasc1) LAG2
			on BASE.rssd9001=LAG2.rssd9001 
			/*and BASE.year=LAG2.year*/
			and BASE.IDX=LAG2.IDX+2
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG3
			on BASE.rssd9001=LAG3.rssd9001 
			/*and BASE.year=LAG3.year*/
			and BASE.IDX=LAG3.IDX+3 
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG4
			on BASE.rssd9001=LAG4.rssd9001 
			/*and BASE.year=LAG4.year*/
			and BASE.IDX=LAG4.IDX+4
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG5
			on BASE.rssd9001=LAG5.rssd9001 
			/*and BASE.year=LAG4.year*/
			and BASE.IDX=LAG5.IDX+5
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG6
			on BASE.rssd9001=LAG6.rssd9001 
			/*and BASE.year=LAG4.year*/
			and BASE.IDX=LAG6.IDX+6
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG7
			on BASE.rssd9001=LAG7.rssd9001 
			/*and BASE.year=LAG4.year*/
			and BASE.IDX=LAG7.IDX+7
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG8
			on BASE.rssd9001=LAG8.rssd9001 
			/*and BASE.year=LAG4.year*/
			and BASE.IDX=LAG8.IDX+8
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG9
			on BASE.rssd9001=LAG9.rssd9001 
			/*and BASE.year=LAG4.year*/
			and BASE.IDX=LAG9.IDX+9
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG10
			on BASE.rssd9001=LAG10.rssd9001 
			/*and BASE.year=LAG4.year*/
			and BASE.IDX=LAG10.IDX+10
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG11
			on BASE.rssd9001=LAG11.rssd9001 
			/*and BASE.year=LAG4.year*/
			and BASE.IDX=LAG11.IDX+11
		left join (select rssd9001, year, IDX, 
					GrTA, GrLoans, AggGrLoans, AbGrLoans, 
                    bhck4230, bhck3123, 
                    RSGL, UrSGL, 
					NetInterestMargin, Efficiency, OperatingLeverage, 
                    GrNIM, GrNIMTII, GrNIMTIE, NIMTII, NIMTIE, 
                    NPLnum, LLP2, ALLP2, ALLP2r, LLP2lag, ALLP2lag, ALLP2rlag, LLR2, CONS, 
                    RealEstateLoansShare, TotalCandILoansShare, 
                    T1CAPRatio, T1CAPLoanRatio   
					from bhc.bhcf8624sasc1) LAG12
			on BASE.rssd9001=LAG12.rssd9001 
			/*and BASE.year=LAG4.year*/
			and BASE.IDX=LAG12.IDX+12;
quit;


proc import out= bhc.gdpdef datafile="&path/GDPDEF_2024Oct01.csv" dbms=csv replace; guessingrows=312; run;

proc sql;
	create view bhc.bhcf8624sasd2 as 
		select a.*, b.gdpdef 
	from bhc.bhcf8624sasd a 
    left join bhc.gdpdef b 
    on a.year = b.year and a.quarter = b.quarter;
quit;
    

/*****THE SECOND GROUP OF MEASURE CONSTRUCTIONS*****/
/*calculating the variables using the measures of (citation goes here), and 
keeping the BHCs in CRSP_FRB links (which now contains only BHCs traded on stock markets*/
proc sql;
	create view bhc.bhcf8624sase as 
		select rssd9001, rssd9999, year, quarter, 
		bhck2170 as TotAssets, 
        (bhck2170/gdpdef)*100 as TotAssetsReal,
		log(bhck2170) as logTotAssets, /*log(var) returns natural logarithm (base e)of var. log10(var) gives the logarithm base 10 of var*/
        log(calculated TotAssetsReal) as logTotAssetsReal, 
		bhck2122 as TotLoans, 
		100*sum(sum(bhck2170,-1*bhck2948),-1*sum(bhck3163,bhck3164,bhck3165,bhck5506,bhck5507),-1*bhck3283)/sum(bhck2170,-1*sum(bhck3163,bhck3164,bhck3165,bhck5506,bhck5507)) as TCERatio, 
		NPLnum/bhck2122 as NPL, 
		bhck4093 / sum(bhck4074,bhck4079) as CostIncome2, 
		bhck4340 / bhck3210 as ROE, 
        bhck3210 / bhck2170 as CapitalRatio, /*Capital ratio : Total equity capital / Total Assets*/
        bhck4340 / bhck2170 as ROA, /*Profitibility : ROA */
		sum(bhdm6631,bhdm6636,bhfn6631,bhfn6636)/bhck2170 as DepositsToAssets, /*Funding structure : Total Deposits (both domestic and foreign) / Total Assets */
        bhck4079 / BHCK4107 as NonInterestIncome, /*Income structure and business model : Total Non-Interest Income / Total Interest Income*/
		sum(bhck0081,bhck0395,bhck0397,bhck0276,bhck0277,-1*bhck0278,-1*bhck0279,bhck0400,
		bhck0213,bhck1287,
		bhck1350,-1*bhck2800, 
		bhdmb987,bhckb989,-1*bhdmb993,-1*bhckb995)/bhck2170 as LiquidAssetstoAssets, 
		sum(bhck0081,bhck0395,bhck0397,bhck0276,bhck0277,-1*bhck0278,-1*bhck0279,bhck0400)/bhck2170 as LiquidAssetstoAssets1,
		sum(bhck0081,bhck0395,bhck0397,bhck0276,bhck0277,-1*bhck0278,-1*bhck0279,bhck0213,bhck1287)/bhck2170 as LiquidAssetstoAssets2,
		sum(bhck0081,bhck0395,bhck0397,bhck1350,-1*bhck2800,bhck0213,bhck1287)/bhck2170 as LiquidAssetstoAssets3,
		sum(bhck0081,bhck0395,bhck0397,bhdmb987,bhckb989,-1*bhdmb993,-1*bhckb995,bhck0213,bhck1287)/bhck2170 as LiquidAssetstoAssets4,
		sum(bhcb2210,bhod3189,bhfn6631)/sum(bhdm6631,bhdm6636,bhfn6631,bhfn6636) as NoninterestDepositsShare, 
		sum(bhcb3187,bhod3187,bhcb2389,bhod2389,bhcb6648,bhod6648)/sum(bhdm6631,bhdm6636,bhfn6631,bhfn6636) as InterestCoreDepositsShare,
		sum(bhcb2604,bhod2604)/sum(bhdm6631,bhdm6636,bhfn6631,bhfn6636) as WholesaleFundingShare, 
		TotalCandILoansShare,
		RealEstateLoansShare,
		bhck1590/bhck2122 as AgricultureLoansShare, 
		ConsumerLoansShare, 
		sum(1,-1*TotalCandILoansShare,-1*RealEstateLoansShare,-1*(calculated AgricultureLoansShare),-1*ConsumerLoansShare) as OtherLoansShare, 
		bhck2122/bhck2170 as LoansToAssets, 
		bhck4079/sum(bhck4074,bhck4079) as NonInterestIncomeShare, 
		bhck4074/sum(bhck4074,bhck4079) as InterestIncomeShare, 
		bhck4070/sum(bhck4074,bhck4079) as FiduciaryActivitiesShare, 
		bhck4483/sum(bhck4074,bhck4079) as ServiceChargesonDepAccShare, 
		sum(bhck1655,bhck4077,
		bhcka220,bhck4076)/sum(bhck4074,bhck4079)as TradingRevenueShare, 
		sum(bhck4078,bhck4399,
		bhck8560,bhck8561,bhckb490,bhckb491,bhckb492,bhckb493,bhckb494,bhckb496,bhckb497,	
		bhckc386,bhckc387, 	
		bhckc886,bhckc888,bhckc887)/sum(bhck4074,bhck4079) as OtherNIIShare, 
		sum(bhck2122,-1*sum(bhdm6631,bhdm6636,bhfn6631,bhfn6636))/bhck2170 as DepositFundingGap, 
		dvIDIV, 
		GrTA,
		LAG1_GrTA,
		LAG2_GrTA,
		LAG3_GrTA,
		LAG4_GrTA,
		GrLoans,
		LAG1_GrLoans,
		LAG2_GrLoans,
		LAG3_GrLoans,
		LAG4_GrLoans, 
		AbGrLoans,
		LAG1_AbGrLoans,
		LAG2_AbGrLoans,
		LAG3_AbGrLoans,
		LAG4_AbGrLoans, 
		LAG5_AbGrLoans,
		LAG6_AbGrLoans,
		LAG7_AbGrLoans,
		LAG8_AbGrLoans, 
		LAG9_AbGrLoans,
		LAG10_AbGrLoans,
		LAG11_AbGrLoans,
		LAG12_AbGrLoans, 
		bhck4150, 
		bhck4230 as LoanLossProvision, 
		log(bhck4230) as logLLProvision, 	
		LAG1_LoanLossProvision, 
		LAG2_LoanLossProvision, 
		LAG3_LoanLossProvision, 
		LAG4_LoanLossProvision, 
		log(LAG1_LoanLossProvision) as logLG1LLProvision, 
		log(LAG2_LoanLossProvision) as logLG2LLProvision, 
		log(LAG3_LoanLossProvision) as logLG3LLProvision, 
		log(LAG4_LoanLossProvision) as logLG4LLProvision, 
		bhck3123 as LoanLossAllowance, 
		log(bhck3123) as logLLAllowance, 
		LAG1_LoanLossAllowance, 
		LAG2_LoanLossAllowance, 
		LAG3_LoanLossAllowance, 
		LAG4_LoanLossAllowance, 
		log(LAG1_LoanLossAllowance) as logLG1LLAllowance, 
		log(LAG2_LoanLossAllowance) as logLG2LLAllowance, 
		log(LAG3_LoanLossAllowance) as logLG3LLAllowance, 
		log(LAG4_LoanLossAllowance) as logLG4LLAllowance, 
		RSGL, 
		log(RSGL) as logRSGL, 
		LAG1_RSGL, 
		LAG2_RSGL, 
		LAG3_RSGL, 
		LAG4_RSGL, 
		log(LAG1_RSGL) as logLG1RSGL, 
		log(LAG2_RSGL) as logLG2RSGL, 
		log(LAG3_RSGL) as logLG3RSGL, 
		log(LAG4_RSGL) as logLG4RSGL, 
		UrSGL, 
		log(UrSGL) as logUrSGL, 
		LAG1_UrSGL, 
		LAG2_UrSGL, 
		LAG3_UrSGL, 
		LAG4_UrSGL, 
		log(LAG1_UrSGL) as logLG1UrSGL, 
		log(LAG2_UrSGL) as logLG2UrSGL, 
		log(LAG3_UrSGL) as logLG3UrSGL, 
		log(LAG4_UrSGL) as logLG4UrSGL, 

		NetInterestMargin, 
		LAG1_NetInterestMargin, 
		LAG2_NetInterestMargin, 
		LAG3_NetInterestMargin, 
		LAG4_NetInterestMargin, 
		GrNIM, 
		LAG1_GrNIM, 
		LAG2_GrNIM, 
		LAG3_GrNIM, 
		LAG4_GrNIM, 
		NIMTII, 
		LAG1_NIMTII, 
		LAG2_NIMTII, 
		LAG3_NIMTII, 
		LAG4_NIMTII, 
		GrNIMTII, 
		LAG1_GrNIMTII, 
		LAG2_GrNIMTII, 
		LAG3_GrNIMTII, 
		LAG4_GrNIMTII, 
		NIMTIE, 
		LAG1_NIMTIE, 
		LAG2_NIMTIE, 
		LAG3_NIMTIE, 
		LAG4_NIMTIE, 
		GrNIMTIE, 
		LAG1_GrNIMTIE, 
		LAG2_GrNIMTIE, 
		LAG3_GrNIMTIE, 
		LAG4_GrNIMTIE, 
		Efficiency, 
		LAG1_Efficiency, 
		LAG2_Efficiency, 
		LAG3_Efficiency, 
		LAG4_Efficiency, 
		OperatingLeverage, 
		LAG1_OperatingLeverage, 
		LAG2_OperatingLeverage, 
		LAG3_OperatingLeverage, 
		LAG4_OperatingLeverage, 
        LLP2,
        LAG1_LLP2, 
		LAG2_LLP2, 
		LAG3_LLP2, 
		LAG4_LLP2,   
        LLP2lag,
        LAG1_LLP2lag, 
		LAG2_LLP2lag, 
		LAG3_LLP2lag, 
		LAG4_LLP2lag,   
        ALLP2,
        LAG1_ALLP2, 
		LAG2_ALLP2, 
		LAG3_ALLP2, 
		LAG4_ALLP2,   
        ALLP2lag,
        LAG1_ALLP2lag, 
		LAG2_ALLP2lag, 
		LAG3_ALLP2lag, 
		LAG4_ALLP2lag,   
        ALLP2r,   
        LAG1_ALLP2r, 
		LAG2_ALLP2r, 
		LAG3_ALLP2r, 
		LAG4_ALLP2r, 
        ALLP2rlag,   
        LAG1_ALLP2rlag, 
		LAG2_ALLP2rlag, 
		LAG3_ALLP2rlag, 
		LAG4_ALLP2rlag,
		LLR2,
        LAG1_LLR2, 
		LAG2_LLR2, 
		LAG3_LLR2, 
		LAG4_LLR2,
        CONS,
        LAG1_CONS, 
		LAG2_CONS, 
		LAG3_CONS, 
		LAG4_CONS,
		CONS - LAG1_CONS as deltaCONS,
        LAG1_NPL,
        (calculated NPL) - LAG1_NPL as deltaNPL,
        LAG1_RE,
        RealEstateLoansShare - LAG1_RE as deltaRE,
        LAG1_CI,
        TotalCandILoansShare - LAG1_CI as deltaCI,
        T1CAPRatio,
        LAG1_T1CAPRatio, 
		LAG2_T1CAPRatio, 
		LAG3_T1CAPRatio, 
		LAG4_T1CAPRatio,
        T1CAPLoanRatio,
        LAG1_T1CAPLoanRatio, 
		LAG2_T1CAPLoanRatio, 
		LAG3_T1CAPLoanRatio, 
		LAG4_T1CAPLoanRatio

	from bhc.bhcf8624sasd2  
	where rssd9001 in (select distinct entity from crsp.crspdfrblink24q42) 
	order by rssd9001, rssd9999;
quit;


%frank(dsetin  = bhc.bhcf8624sase,
        dsetout = bhc.bhcf8624sasf,
        vars    = TotAssets
					logTotAssets
                    TotAssetsReal
                    logTotAssetsReal
					TotLoans
					TCERatio
					NPL
					CostIncome2
					ROE
                    CapitalRatio
                    ROA
                    DepositsToAssets
                    NonInterestIncome
					LiquidAssetstoAssets
					LiquidAssetstoAssets1
					LiquidAssetstoAssets2
					LiquidAssetstoAssets3
					LiquidAssetstoAssets4
					NoninterestDepositsShare
					InterestCoreDepositsShare
					WholesaleFundingShare
					/*DepositsToAssets*/
					TotalCandILoansShare
					RealEstateLoansShare
					AgricultureLoansShare
					ConsumerLoansShare
					OtherLoansShare
					LoansToAssets
					/*DepositFundingGap*/
					NonInterestIncomeShare
					InterestIncomeShare
					FiduciaryActivitiesShare
					ServiceChargesonDepAccShare
					TradingRevenueShare
					OtherNIIShare
					DepositFundingGap 
					GrTA 
					LAG1_GrTA 
					LAG2_GrTA 
					LAG3_GrTA 
					LAG4_GrTA 
					GrLoans 
					LAG1_GrLoans 
					LAG2_GrLoans 
					LAG3_GrLoans 
					LAG4_GrLoans 
					AbGrLoans 
					LAG1_AbGrLoans 
					LAG2_AbGrLoans 
					LAG3_AbGrLoans 
					LAG4_AbGrLoans 
					LAG5_AbGrLoans 
					LAG6_AbGrLoans 
					LAG7_AbGrLoans 
					LAG8_AbGrLoans 
					LAG9_AbGrLoans 
					LAG10_AbGrLoans 
					LAG11_AbGrLoans 
					LAG12_AbGrLoans 
					dvIDIV 
					LoanLossProvision 
					LAG1_LoanLossProvision 
					LAG2_LoanLossProvision 
					LAG3_LoanLossProvision 
					LAG4_LoanLossProvision 
					logLLProvision 
					logLG1LLProvision 
					logLG2LLProvision 
					logLG3LLProvision 
					logLG4LLProvision 
					LoanLossAllowance 
					LAG1_LoanLossAllowance 
					LAG2_LoanLossAllowance 
					LAG3_LoanLossAllowance 
					LAG4_LoanLossAllowance 
					logLLAllowance 
					logLG1LLAllowance 
					logLG2LLAllowance 
					logLG3LLAllowance 
					logLG4LLAllowance 
					RSGL 
					logRSGL
					LAG1_RSGL 
					LAG2_RSGL 
					LAG3_RSGL 
					LAG4_RSGL 
					logLG1RSGL 
					logLG2RSGL 
					logLG3RSGL 
					logLG4RSGL 
					UrSGL 
					logUrSGL 
					LAG1_UrSGL 
					LAG2_UrSGL 
					LAG3_UrSGL 
					LAG4_UrSGL 
					logLG1UrSGL 
					logLG2UrSGL 
					logLG3UrSGL 
					logLG4UrSGL 

					NetInterestMargin 
					LAG1_NetInterestMargin 
					LAG2_NetInterestMargin 
					LAG3_NetInterestMargin 
					LAG4_NetInterestMargin 
					GrNIM 
					LAG1_GrNIM 
					LAG2_GrNIM 
					LAG3_GrNIM 
					LAG4_GrNIM 
					NIMTII 
					LAG1_NIMTII 
					LAG2_NIMTII 
					LAG3_NIMTII 
					LAG4_NIMTII 
					GrNIMTII 
					LAG1_GrNIMTII 
					LAG2_GrNIMTII 
					LAG3_GrNIMTII 
					LAG4_GrNIMTII 
					NIMTIE 
					LAG1_NIMTIE 
					LAG2_NIMTIE 
					LAG3_NIMTIE 
					LAG4_NIMTIE 
					GrNIMTIE 
					LAG1_GrNIMTIE 
					LAG2_GrNIMTIE 
					LAG3_GrNIMTIE 
					LAG4_GrNIMTIE 
					Efficiency 
					LAG1_Efficiency 
					LAG2_Efficiency 
					LAG3_Efficiency 
					LAG4_Efficiency 
					OperatingLeverage 
					LAG1_OperatingLeverage 
					LAG2_OperatingLeverage 
					LAG3_OperatingLeverage 
					LAG4_OperatingLeverage
					LLP2
                    LAG1_LLP2
                    LAG2_LLP2
                    LAG3_LLP2 
                    LAG4_LLP2   
                    LLP2lag
                    LAG1_LLP2lag
                    LAG2_LLP2lag
                    LAG3_LLP2lag 
                    LAG4_LLP2lag   
					ALLP2 
                    LAG1_ALLP2 
                    LAG2_ALLP2 
                    LAG3_ALLP2 
                    LAG4_ALLP2   
                    ALLP2lag 
                    LAG1_ALLP2lag 
                    LAG2_ALLP2lag 
                    LAG3_ALLP2lag 
                    LAG4_ALLP2lag   
					ALLP2r 
                    LAG1_ALLP2r 
                    LAG2_ALLP2r 
                    LAG3_ALLP2r 
                    LAG4_ALLP2r 
                    ALLP2rlag 
                    LAG1_ALLP2rlag 
                    LAG2_ALLP2rlag 
                    LAG3_ALLP2rlag 
                    LAG4_ALLP2rlag
					LLR2
			        LAG1_LLR2 
					LAG2_LLR2 
					LAG3_LLR2 
					LAG4_LLR2
                    CONS
                    LAG1_CONS
                    LAG2_CONS
                    LAG3_CONS
                    LAG4_CONS
					deltaCONS
                    LAG1_NPL
                    deltaNPL
                    LAG1_RE
                    deltaRE
                    LAG1_CI
                    deltaCI
                    T1CAPRatio
                    LAG1_T1CAPRatio
                    LAG2_T1CAPRatio
                    LAG3_T1CAPRatio
                    LAG4_T1CAPRatio
                    T1CAPLoanRatio
                    LAG1_T1CAPLoanRatio 
                    LAG2_T1CAPLoanRatio 
                    LAG3_T1CAPLoanRatio 
                    LAG4_T1CAPLoanRatio,
        type    = winsor,
        pctl    = 1 99
        );


proc sql noprint;
   select cats(name,'=',name,'w1')
          into :renamelist 
          separated by ' ' 
          from dictionary.columns
          where upcase(libname) = 'BHC' and upcase(memname) = 'BHCF8624SASF'
          and upcase(name) ne 'RSSD9001' and upcase(name) ne 'RSSD9999' 
		  and upcase(name) ne 'YEAR' and upcase(name) ne 'QUARTER';
quit;


proc datasets library = bhc nolist;
   modify bhcf8624sasf;
   rename &renamelist;
quit;


proc sql noprint;
   select cats('a.',name) 
		  into :wznamelist 
          separated by ', ' 
          from dictionary.columns
          where upcase(libname) = 'BHC' and upcase(memname) = 'BHCF8624SASF'
          and upcase(name) ne 'RSSD9001' and upcase(name) ne 'RSSD9999' 
		  and upcase(name) ne 'YEAR' and upcase(name) ne 'QUARTER';
quit;


/*add non-winzed variables to the winzed one, for debugging
Technical note: WARNINGs of duplicated columns in select phrase 
like 'SELECT * ' occurs when joinning two tables.
Getting a macro variable containing a list of suffixed or prefixed columns 
in either tables helps to elimnate that WARNINGs.
WARNING: Variable .... already exists on file ........
*/
proc sql; 
	create view bhc.bhcf8624sasg as
	select b.*, &wznamelist
	from bhc.bhcf8624sasf a inner join bhc.bhcf8624sase b 
	on a.rssd9001=b.rssd9001 and a.rssd9999=b.rssd9999;
quit;


/*winsorizing causes some BHCs disappeared
must check: maindatabase TotalAssets 153691 -winsorized-> 531864.22 ?? while wisorize.sas in this program returns unchanged;
consider: deflate as did in the paper (printed);
pay attention: all calculated variables are in ratios except TotalAssets and TotalLoans*/
proc sql; 
	create view bhc.bhcf8624sash as
	select * 
	from bhc.bhcf8624sasg 
	where 1 = 1 
    /* and TotAssetsw1 >= 500000 */ ;
quit;


/*Add PERMCOs info from the CRSPFRB links to the filtered BHCFWRDS, 
and the remaining links info : name, inst_type, dt_start, and dt_end */
proc sql; 
	create view bhc.bhcf8624sasi as
	select a.*, b.name, b.inst_type, b.permco, b.dt_start, b.dt_end 
	from bhc.bhcf8624sash a left join crsp.crspdfrblink24q42 b 
	on ((a.rssd9001=b.entity and not dup_entity and not dup_permco) 
		or (a.rssd9001=b.entity and (dup_entity or dup_permco) and a.rssd9999 <= b.dt_end and dup = 1) 
		or (a.rssd9001=b.entity and (dup_entity or dup_permco) and a.rssd9999 >= b.dt_start and dup = 2)
		or (a.rssd9001=b.entity and (dup_entity or dup_permco) and a.rssd9999 >= b.dt_start and a.rssd9999 <= b.dt_end and dup = 3));
quit;


/*mapping Time index to rssd9999 for bank-time regression
Techincal note: feedback can be used to debug the execution of a sql.
It provides the transformed statement which eventually executed by SQL engine.
*/
proc sql; 
	create view bhc.bhcf8624sasj as
	select a.*, b.endquarteridx as time 
	from bhc.bhcf8624sasi a left join crsp.systemendquarters2 b 
	on a.year=b.year and a.quarter=b.quarter and b.endquarteridx ne '';
quit;


/*reorder the columns, moving the identifying variables to the front*/
data bhc.bhcf8624sask; 	
	retain rssd9001 rssd9999 Time year quarter permco name inst_type dt_start dt_end;
	set bhc.bhcf8624sasj;
	baselinesample1 = 0;
	truecallcrspmatch = 0;
	baselinesample1call = 0;
run;


/*A practice of eliminating WARNINGs due to obtaining a view from joining two tables or views.*/
proc sql noprint;
   select cats('b.',name) 
		  into :tailvarlist 
          separated by ', ' 
          from dictionary.columns
          where upcase(libname) = 'CRSP' and upcase(memname) = 'TAILBETA_CRSP24S6'
          and upcase(name) ne 'PERMCO' and upcase(name) ne 'ENDYEAR' 
		  and upcase(name) ne 'ENDQUARTER';
quit;
/*joining tail betas into the bankdata using PERMCO and (year,quarter) correspondingly. 
Because the fundamental data was matched to the 15th quarters of 16-quarter rolling windows (spreading from quarter t to t+15), 
the fundamental items are therefore lagged 16 quarters, from t+15 back to t-1, for the regressions.*/

proc sql; 
	create view bhc.bhcf8624sasl as
	select a.*, &tailvarlist
	from bhc.bhcf8624sask a left join crsp.tailbeta_crsp24S6 b
	on a.permco=b.permco and a.year=b.endyear and a.quarter=b.endquarter
	order by a.rssd9001, a.year, a.quarter;
quit;


/*reorder the columns to make them looked like the counterparts in the downloaded Maindatabase.csv, 
time framing the sample for the baseline*/
data bhc.bhcf8624sasm; 
	retain banknumberid rssd9001 rssd9999 time bankpermno permco year quarter 
	name inst_type dt_start dt_end startdate enddate startyear startquarter endyear endquarter 
	missings_perc zeros_perc tailbeta logtailbeta tauSL taupower tailbetaIR 
	CoVarQNT CoVarQNTconst CoVarQNTslope CoVaREVT CoVaREVTSL CoVaREVTIR
	missings_perc zeros_perc commonbeta commonSL commonIR MESest ESSest
	TBk10 TBk10SL TBk10IR TBk20 TBk20SL TBk20IR TBk30 TBk30SL TBk30IR TBk50 TBk50SL TBk50IR
	TBk60 TBk60SL TBk60IR TBk70 TBk70SL TBk70IR TBk80 TBk80SL TBk80IR;
	set bhc.bhcf8624sasl;
	/*For now, this replicated baselinesample is not exactly the same as the baselinesample of Van Oordt and Chen Zhou.
	Because in their sample, there were still many observations that satisfied the conditional to be in the baselinesample, 
	but the baseline flags were set to 0 instead of 1.*/
	if (rssd9999 >= 19860930 and rssd9999 <= 20240930) 
		and tailbeta ^= 0 and tailbeta ^= . /*invalid tailbeta have to be eliminated from the sample*/
		and GrTAw1 ^= . and GrLoansw1 ^= . 
	then baselinesample1 = 1; /*the sample for the main analyses only contains tailbetas in 19860930 and 20240930*/
    
    /*dt_start and dt_end are the lower and upper bounds of date provided in CRSP-FRB (or crsp-call, or call-crsp) link file, 
    while startdate and enddate are the start and end dates of estimation windows observed during beta calculation from both bank and system returns. These start and end dates are originally from CRSP database. Therefore, if a pair of startdate and enddate is subrange of or fitted into their corresponding bank date range in the link file, the CALL data and CRSP in the corresponding row is a true match, i.e. truecallcrspmatch flag must be 1*/
	if dt_start <= startdate and enddate <= dt_end then truecallcrspmatch = 1;
	
    if baselinesample1 = 1 and truecallcrspmatch = 1 then baselinesample1call = 1;
	if bankpermno = . then delete; /*dropping the fundamental data that is not associated with any tailbeta,
	i.e. tailbetas or stock prices are not available for the banks at some particular quarters*/
run;

proc import out= epu.inflation datafile="&pathepu\EMVoliilityMACRONewsINFLATION.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.exrates datafile="&pathepu\EMVolitilityEXRATES.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.gspenddefsdebts datafile="&pathepu\EMVolitilityGOVTSPENDDefsDebts.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.bizinvsentiment datafile="&pathepu\EMVolitilityMACRONewsBIZInvSEN.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.consmrspendsentiment datafile="&pathepu\EMVolitilityMACRONewsCONSUMERSpendingSEN.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.interest datafile="&pathepu\EMVolitiliyMACRONewsINTEREST.csv	" dbms=csv replace; guessingrows=160; run;
proc import out= epu.overallv1 datafile="&pathepu\EPU_Overall_V1.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.finregulation datafile="&pathepu\EPUFINREG.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.fiscalpolicy datafile="&pathepu\EPUFISCALPolicy.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.gspend datafile="&pathepu\EPUGOVTSPEND.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.mntarypolicy datafile="&pathepu\EPUMONETARYPolicy.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.tradepolicy datafile="&pathepu\EPUTRADEPolicy.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.emrelated datafile="&pathepu\EUEMrelated.csv" dbms=csv replace; guessingrows=160; run;
proc import out= epu.rgdpgr datafile="&pathepu\realGDPgrowthQ.csv" dbms=csv replace; guessingrows=310; run;

proc sql;
	create table bhc.bhcf8624sasn (drop=observation_date yearquarter) as 
		select  BASE.*, 
            inflation.EMVMACROINFLATION, 
			exrates.EMVEXRATES, 
			gspenddefsdebts.EMVGOVTSPEND, 
            bizinvsentiment.EMVMACROBUS, 
			consmrspendsentiment.EMVMACROCONSUME, 
            interest.EMVMACROINTEREST, 
            overallv1.EPUOvV1, 
            finregulation.EPUFINREG, 
            fiscalpolicy.EPUFISCAL, 
            gspend.EPUGOVTSPEND, 
            mntarypolicy.EPUMONETARY, 
            tradepolicy.EPUTRADE, 
            emrelated.WLEMUINDXD, 
            rgdpgr.rgdpgr 

		from (select * from bhc.bhcf8624sasm) BASE
		left join (select * 
					from epu.inflation) inflation
			on BASE.year=inflation.year 
			and BASE.quarter=inflation.quarter
		left join (select * 
					from epu.exrates) exrates
			on BASE.year=exrates.year 
			and BASE.quarter=exrates.quarter
		left join (select * 
					from epu.gspenddefsdebts) gspenddefsdebts
			on BASE.year=gspenddefsdebts.year 
			and BASE.quarter=gspenddefsdebts.quarter
		left join (select * 
					from epu.bizinvsentiment) bizinvsentiment
			on BASE.year=bizinvsentiment.year 
			and BASE.quarter=bizinvsentiment.quarter
		left join (select * 
					from epu.consmrspendsentiment) consmrspendsentiment
			on BASE.year=consmrspendsentiment.year 
			and BASE.quarter=consmrspendsentiment.quarter
		left join (select * 
					from epu.interest) interest
			on BASE.year=interest.year 
			and BASE.quarter=interest.quarter
		left join (select * 
					from epu.overallv1) overallv1
			on BASE.year=overallv1.year 
			and BASE.quarter=overallv1.quarter
		left join (select * 
					from epu.finregulation) finregulation
			on BASE.year=finregulation.year 
			and BASE.quarter=finregulation.quarter
		left join (select * 
					from epu.fiscalpolicy) fiscalpolicy
			on BASE.year=fiscalpolicy.year 
			and BASE.quarter=fiscalpolicy.quarter
		left join (select * 
					from epu.gspend) gspend
			on BASE.year=gspend.year 
			and BASE.quarter=gspend.quarter
		left join (select * 
					from epu.mntarypolicy) mntarypolicy
			on BASE.year=mntarypolicy.year 
			and BASE.quarter=mntarypolicy.quarter
		left join (select * 
					from epu.tradepolicy) tradepolicy
			on BASE.year=tradepolicy.year 
			and BASE.quarter=tradepolicy.quarter 
        left join (select * 
					from epu.emrelated) emrelated
			on BASE.year=emrelated.year 
			and BASE.quarter=emrelated.quarter
        left join (select * 
					from epu.rgdpgr) rgdpgr
			on BASE.year=rgdpgr.year 
			and BASE.quarter=rgdpgr.quarter;
quit;

proc export data= bhc.bhcf8624sasn outfile="&path/06_Maindatabase24(S7out).csv" dbms=csv replace; run;
