/*

ssc install asdoc
ssc install logout
ssc install mmv
ssc install asrol

//Note when running xtabond2:
//The Stata's default running mode is favoring speed over space (i.e. it optimized for fast speed without caring space limit.
//However, to prevent Stata from throwing fatal error due to cannot allocate more memory, i.e. switching to favoring space over speed by type and run, mata: mata set matafavor space, perm

asdoc tabstat $SUMSTATS1 if baselinesample1call==1 , stat(mean sd min p10 p90 max N) columns(statistics)

//good precision
logout, save("Myfile.xls") excel replace: tabstat $SUMSTATS1 if baselinesample1call==1 , stat(mean sd min p10 p90 max N) columns(statistics) format(%9.3f)

logout, save("Myfile2.xls") excel replace: tabstat RSSD9999 resTotAssetsL16 TCERatiow1L16 NPLw1L16 CostIncome2w1L16 ROEw1L16 LiquidAssetstoAssetsw1L16 DepositFundingGapw1L16 LoansToAssetsw1L16 NonInterestIncomeSharew1L16 TFDRatioL16 FD4TRatioL16 FD4HRatioL16 if baselinesample1call==1 , stat(mean sd min p10 p90 max N) columns(statistics) format(%9.3f)

https://www.statalist.org/forums/forum/general-stata-discussion/general/1308971-new-package-on-ssc-asrol-module-to-calculate-moving-rolling-window-statistics
*/



clear all
set more off
set matsize 10000

*ssc install ranktest
*ssc install ivreg2
*ssc install ivendog

**** SET DIRECTORIES *************
global basepath = "D:\02_Economic\05_ALX\01_SystemicRisk_VanOordt2019\reps\loangrowth\resultsLoanlossProvision"
adopath + "D:\02_Economic\05_ALX\01_SystemicRisk_VanOordt2019\reps\VanOordt\programs\ado"
cd "$basepath"
**********************************


**** LOAD DATA FROM************
import delimited "D:\Newfolder\V2\06_Maindatabase24(S7out).csv", delimiter(comma) varnames(1) stripquote(yes) case(preserve) asdouble
keep if bankpermno != .
egen panelid = group(rssd9001 permco bankpermno)
drop rssd9001
rename panelid rssd9001
tsset rssd9001 time
**********************************


keep if TotAssetsRealw1 > 2000000 & TotAssetsRealw1 < 10000000

/*
drop if year >= 2018
*/

* log of explanatory variables
g logtailbetaIR = log(tailbetaIR)
g logtailbetaSL = log(taupower)

xtreg ALLP2w1 LAG1_LLR2w1 LAG1_NPLw1 deltaNPLw1 LAG1_REw1 deltaREw1 LAG1_CIw1 deltaCIw1 LAG1_CONSw1 deltaCONSw1  i.time if baselinesample1==1 & F16.year>1993, fe ro i(rssd9001) cluster(rssd9001)

predict ALLP2w1_hat
gen DLLP2w1 = ALLP2w1 - ALLP2w1_hat 
gen NDLLP2w1=ALLP2w1_hat
drop ALLP2w1_hat

***********************************************
*
*       APPENDIX: TABLE I WITH SUMMARY STATISTICS
*
***********************************************


***********************************************
*
*       GENERATE VARIABLES AND LISTS
*
***********************************************
* Residual of total assets
global ALLVARSTOTALASSETS1 DLLP2w1 $VARSCON

//SUMSTATS for Reports
global VARSLLP LLP2w1 LLR2w1 LLP2lagw1 ALLP2rw1 DLLP2w1

global VARSCON TCERatiow1 NPLw1 CostIncome2w1 ROEw1 LiquidAssetstoAssetsw1 DepositsToAssetsw1 LoansToAssetsw1 NonInterestIncomeSharew1 GrTAw1 

global VARSLLPCON $VARSLLP $VARSCON

global VARSXSRVC ServiceChargesonDepAccSharew1 FiduciaryActivitiesSharew1 TradingRevenueSharew1 OtherNIISharew1  

global VARSXLOAN RealEstateLoansSharew1 TotalCandILoansSharew1 ConsumerLoansSharew1 AgricultureLoansSharew1 OtherLoansSharew1

global VARSXINCM InterestCoreDepositsSharew1 WholesaleFundingSharew1 NoninterestDepositsSharew1 InterestIncomeSharew1 

* Variable lists for regressions
global VARSCONLAG16 TCERatiow1L16 NPLw1L16 CostIncome2w1L16 ROEw1L16  LiquidAssetstoAssetsw1L16 DepositsToAssetsw1L16 LoansToAssetsw1L16 NonInterestIncomeSharew1L16 GrTAw1L16 

global VARSXSRVCLAG16 ServiceChargesonDepAccSharew1L16 FiduciaryActivitiesSharew1L16 TradingRevenueSharew1L16 OtherNIISharew1L16  

global VARSXLOANLAG16 TotalCandILoansSharew1L16 ConsumerLoansSharew1L16 AgricultureLoansSharew1L16 OtherLoansSharew1L16 //RealEstateLoansSharew1L16

global VARSXINCMLAG16 InterestCoreDepositsSharew1L16 WholesaleFundingSharew1L16 NoninterestDepositsSharew1L16 InterestIncomeSharew1L16 

global BASELINEVARSINDEP resTotAssetsDLLP2w1L16 DLLP2w1L16 $VARSCONLAG16

global VARSWITHNII resTotAssetsDLLP2w1L16 DLLP2w1L16 $VARSCONLAG16 $VARSXSRVCLAG16 

global VARSPORTFOLIO resTotAssetsDLLP2w1L16 DLLP2w1L16 $VARSCONLAG16 $VARSXLOANLAG16 


* Table
//tabstat tailbeta taupower tailbetaIR if baselinesample1==1 , stat(mean sd min p10 p90 max n) columns(statistics)
//tabstat $SUMSTATS1 if baselinesample1call==1 , stat(mean sd min p10 p90 max n) columns(statistics)
*************************************************


* Summary statistics
asdoc tabstat tailbeta taupower tailbetaIR $VARSLLP logTotAssetsRealw1 $VARSCON if baselinesample1call==1 , stat(mean sd min p10 p90 max) dec(3) columns(statistics) abb(32) varwidth(32) save(results/DescrptStatsReport.doc) replace

asdoc tabstat tailbeta taupower tailbetaIR logtailbeta logtailbetaSL logtailbetaIR $VARSLLP logTotAssetsRealw1 $VARSCON $VARSXSRVC $VARSXLOAN $VARSXINCM if baselinesample1call==1 , stat(mean median sd min p10 p90 max N) dec(3) columns(statistics) abb(32) varwidth(32) save(results/DescrptStatsDetail.doc) replace

asdoc pwcorr tailbeta taupower tailbetaIR $VARSLLP logTotAssetsRealw1 $VARSCON if baselinesample1call==1, dec(3) columns(statistics) abb(32) varwidth(32) save(results/Correlations.doc) replace //star(all) 
***********************************************



//LLP2w1 
regress logTotAssetsRealw1 LLP2w1 TCERatiow1 NPLw1 CostIncome2w1  ROEw1  LiquidAssetstoAssets3w1 DepositsToAssetsw1 InterestCoreDepositsSharew1 WholesaleFundingSharew1 RealEstateLoansSharew1 AgricultureLoansSharew1 TotalCandILoansSharew1 ConsumerLoansSharew1 LoansToAssetsw1 FiduciaryActivitiesSharew1 ServiceChargesonDepAccSharew1 TradingRevenueSharew1 InterestIncomeSharew1 GrTAw1 i.time if F16.baselinesample1==1 & F16.year>1993, ro //& L12.year <= 1996
predict logTotAssetsRealw1_hat
//resTotAssets : LLP2w1
gen resTotAssetsLLP2w1 = logTotAssetsRealw1 - logTotAssetsRealw1_hat 
drop logTotAssetsRealw1_hat

//LLR2w1 
regress logTotAssetsRealw1 LLR2w1 TCERatiow1 NPLw1 CostIncome2w1  ROEw1  LiquidAssetstoAssets3w1 DepositsToAssetsw1 InterestCoreDepositsSharew1 WholesaleFundingSharew1 RealEstateLoansSharew1 AgricultureLoansSharew1 TotalCandILoansSharew1 ConsumerLoansSharew1 LoansToAssetsw1 FiduciaryActivitiesSharew1 ServiceChargesonDepAccSharew1 TradingRevenueSharew1 InterestIncomeSharew1 GrTAw1 i.time if F16.baselinesample1==1 & F16.year>1993, ro //& L12.year <= 1996
predict logTotAssetsRealw1_hat
//resTotAssets : LLR2w1
gen resTotAssetsLLR2w1 = logTotAssetsRealw1 - logTotAssetsRealw1_hat 
drop logTotAssetsRealw1_hat

//LLP2lagw1 
regress logTotAssetsRealw1 LLP2lagw1 TCERatiow1 NPLw1 CostIncome2w1  ROEw1  LiquidAssetstoAssets3w1 DepositsToAssetsw1 InterestCoreDepositsSharew1 WholesaleFundingSharew1 RealEstateLoansSharew1 AgricultureLoansSharew1 TotalCandILoansSharew1 ConsumerLoansSharew1 LoansToAssetsw1 FiduciaryActivitiesSharew1 ServiceChargesonDepAccSharew1 TradingRevenueSharew1 InterestIncomeSharew1 GrTAw1 i.time if F16.baselinesample1==1 & F16.year>1993, ro //& L12.year <= 1996
predict logTotAssetsRealw1_hat
//resTotAssets : LLP2lagw1
gen resTotAssetsLLP2lagw1 = logTotAssetsRealw1 - logTotAssetsRealw1_hat 
drop logTotAssetsRealw1_hat

//ALLP2rw1 
regress logTotAssetsRealw1 ALLP2rw1 TCERatiow1 NPLw1 CostIncome2w1  ROEw1  LiquidAssetstoAssets3w1 DepositsToAssetsw1 InterestCoreDepositsSharew1 WholesaleFundingSharew1 RealEstateLoansSharew1 AgricultureLoansSharew1 TotalCandILoansSharew1 ConsumerLoansSharew1 LoansToAssetsw1 FiduciaryActivitiesSharew1 ServiceChargesonDepAccSharew1 TradingRevenueSharew1 InterestIncomeSharew1 GrTAw1 i.time if F16.baselinesample1==1 & F16.year>1993, ro //& L12.year <= 1996
predict logTotAssetsRealw1_hat
//resTotAssets : ALLP2rw1
gen resTotAssetsALLP2rw1 = logTotAssetsRealw1 - logTotAssetsRealw1_hat 
drop logTotAssetsRealw1_hat

//DLLP2w1
regress logTotAssetsRealw1 DLLP2w1 TCERatiow1 NPLw1 CostIncome2w1  ROEw1  LiquidAssetstoAssets3w1 DepositsToAssetsw1 InterestCoreDepositsSharew1 WholesaleFundingSharew1 RealEstateLoansSharew1 AgricultureLoansSharew1 TotalCandILoansSharew1 ConsumerLoansSharew1 LoansToAssetsw1 FiduciaryActivitiesSharew1 ServiceChargesonDepAccSharew1 TradingRevenueSharew1 InterestIncomeSharew1 GrTAw1 i.time if F16.baselinesample1==1 & F16.year>1993, ro //& L12.year <= 1996
predict logTotAssetsRealw1_hat
//resTotAssets : DLLP2w1
gen resTotAssetsDLLP2w1 = logTotAssetsRealw1 - logTotAssetsRealw1_hat 
drop logTotAssetsRealw1_hat

* Lags of variables because command cluster2 cannot handle time operators
/*
 The SUMSTATS1 need to be shifted back to 16 quarters because of the following:
+the--beginning-----a---period---of----16---quarters-----the--end+
**********************
*the characteristics* -> as the underlying condition that a bank will operate in*
**********************
+++++++++++++++++
+the            +  
+tail-betas     +
+which grasp    +
+the volitility +
+of the bank's  +
+stock return   +
+over the period+
+++++++++++++++++
--> the bank's characteristics will help explain the severe shocks over the period
*/
foreach x of global VARSLLPCON {
gen 	 `x'L16= L16.`x' 
}

foreach x of global VARSXSRVC {
gen 	 `x'L16= L16.`x' 
}

foreach x of global VARSXLOAN {
gen 	 `x'L16= L16.`x' 
}

foreach x of global VARSXINCM {
gen 	 `x'L16= L16.`x' 
}
gen 	 resTotAssetsLLP2w1L16 = L16.resTotAssetsLLP2w1
gen 	 resTotAssetsLLR2w1L16 = L16.resTotAssetsLLR2w1
gen 	 resTotAssetsLLP2lagw1L16 = L16.resTotAssetsLLP2lagw1
gen 	 resTotAssetsALLP2rw1L16 = L16.resTotAssetsALLP2rw1
gen 	 resTotAssetsDLLP2w1L16 = L16.resTotAssetsDLLP2w1




***********************************************
*
*       REGRESSIONS TABLE 1 (BASELINE RESULTS)
*
***********************************************
* Model (1)
* Calculate partial R-squared
regress logtailbeta $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
//global adjusted_r2 = e(r2_a)
* Output
outreg2 using .\results\rp_table1.xls, bdec(3) sdec(3) replace label keep($BASELINEVARSINDEP) addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) 

* Model (2)
* Calculate partial R-squared
regress logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
qui tab rssd9001 if e(sample)
local NoBnks= `r(r)'

* Output
outreg2 using .\results\rp_table1.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (3)
* Calculate partial R-squared
regress logtailbetaIR $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaIR $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_table1.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
***********************************************




***********************************************
*
*       REGRESSIONS TABLE 2 (NON-INTEREST INCOME)
*
***********************************************
* Model (1)
* Calculate partial R-squared
regress logtailbeta $VARSWITHNII i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $VARSWITHNII i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\table2.xls, addtext("T FE and clustered at bank and time level","","Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) drop(_I*) replace label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2)
* Calculate partial R-squared
regress logtailbetaSL $VARSWITHNII i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $VARSWITHNII i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\table2.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($VARSWITHNII) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) 

* Model (3)
* Calculate partial R-squared
regress logtailbetaIR $VARSWITHNII i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaIR $VARSWITHNII i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\table2.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($VARSWITHNII) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) 
***********************************************





***********************************************
*
*       REGRESSIONS TABLE 3 (CONVENTIONAL RISK MEASURES)
*
***********************************************
g logcommonbeta = log(commonbeta)
g logcommonSL = log(commonSL)
g logcommonIR = log(commonIR)

* Model (1)
* Calculate partial R-squared
regress logtailbeta logcommonSL logcommonIR $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta logcommonSL logcommonIR $BASELINEVARSINDEP i.time if baselinesample1==1 , fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_table3.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(logcommonSL logcommonIR  $BASELINEVARSINDEP) replace label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2)
* Calculate partial R-squared
regress logtailbetaSL logcommonSL logcommonIR $BASELINEVARSINDEP i.time if baselinesample1==1, ro 
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL logcommonSL logcommonIR  $BASELINEVARSINDEP i.time if baselinesample1==1 , fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_table3.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(logcommonSL logcommonIR $BASELINEVARSINDEP) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
* Model (3)
* Calculate partial R-squared
regress logtailbetaIR logcommonSL logcommonIR $BASELINEVARSINDEP i.time if baselinesample1==1, ro 
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaIR logcommonSL logcommonIR $BASELINEVARSINDEP i.time if baselinesample1==1 , fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_table3.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(logcommonSL logcommonIR $BASELINEVARSINDEP) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

drop logcommonbeta logcommonSL logcommonIR
***********************************************





***********************************************
*
*       REGRESSIONS TABLE 4 (EXPOSURE COVAR)
*
***********************************************
* Calculate the estimated level of T(\tau,\xi)
g logCoVaREVTT = log(CoVaREVTSL / taupower)
* log exposure CoVaR based on Extrem Value Theory
g logCoVaREVT = log(CoVaREVT)
* log exposure CoVaR based on Quantile Regressions
g logCoVarQNT = log(CoVarQNT)

* Model (1) - Exposure CoVaR 
* Calculate partial R-squared
regress logCoVaREVTT $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logCoVaREVTT $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_table4.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEVARSINDEP) replace label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2) - Exposure CoVaR based on EVT
* Calculate partial R-squared
regress logCoVaREVT $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logCoVaREVT $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_table4.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (3) - Exposure CoVaR based on Quantile Regression
* Calculate partial R-squared
regress logCoVarQNT $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logCoVarQNT $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_table4.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
***********************************************





***********************************************
*
*       APPENDIX: TABLE II (PORTFOLIO DECOMPOSITION)
*
***********************************************
* Model (1)
* Calculate partial R-squared
regress logtailbeta $VARSPORTFOLIO i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $VARSPORTFOLIO i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_ii_portfoliodecompose.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($VARSPORTFOLIO) replace label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2)
* Calculate partial R-squared
regress logtailbetaSL $VARSPORTFOLIO i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $VARSPORTFOLIO i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_ii_portfoliodecompose.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($VARSPORTFOLIO) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (3)
* Calculate partial R-squared
regress logtailbetaIR $VARSPORTFOLIO i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaIR $VARSPORTFOLIO i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_ii_portfoliodecompose.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($VARSPORTFOLIO) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
******************************************





***********************************************
*
*       APPENDIX: TABLES IV AND V (PREDICT)
*
***********************************************
regress logtailbeta  l16.logtailbetaIR if baselinesample1==1 & year==2009 & quarter=="Q4" & l16.logtailbetaSL!=., ro
outreg2 using .\results\wtable_iv.xls, replace
regress logtailbeta  l32.logtailbetaIR if baselinesample1==1 & year==2009 & quarter=="Q4" & l32.logtailbetaSL!=., ro
outreg2 using .\results\wtable_iv.xls, append 
regress logtailbeta  l48.logtailbetaIR if baselinesample1==1 & year==2009 & quarter=="Q4" & l48.logtailbetaSL!=., ro
outreg2 using .\results\wtable_iv.xls, append
***********************************************
regress logtailbeta  l16.logtailbetaSL if baselinesample1==1 & year==2009 & quarter=="Q4", ro
outreg2 using .\results\wtable_iv.xls, append
regress logtailbeta  l32.logtailbetaSL if baselinesample1==1 & year==2009 & quarter=="Q4", ro
outreg2 using .\results\wtable_iv.xls, append
regress logtailbeta  l48.logtailbetaSL if baselinesample1==1 & year==2009 & quarter=="Q4", ro
outreg2 using .\results\wtable_iv.xls, append
***********************************************
regress logtailbeta  l16.logtailbetaIR if baselinesample1==1 & year==1999 & quarter=="Q4" & l16.logtailbetaSL!=., ro
outreg2 using .\results\wtable_v.xls, replace
regress logtailbeta  l32.logtailbetaIR if baselinesample1==1 & year==1999 & quarter=="Q4" & l32.logtailbetaSL!=., ro
outreg2 using .\results\wtable_v.xls, append 
regress logtailbeta  l48.logtailbetaIR if baselinesample1==1 & year==1999 & quarter=="Q4" & l48.logtailbetaSL!=., ro
outreg2 using .\results\wtable_v.xls, append 
***********************************************
regress logtailbeta  l16.logtailbetaSL if baselinesample1==1 & year==1999 & quarter=="Q4", ro
outreg2 using .\results\wtable_v.xls, append 
regress logtailbeta  l32.logtailbetaSL if baselinesample1==1 & year==1999 & quarter=="Q4", ro
outreg2 using .\results\wtable_v.xls, append 
regress logtailbeta  l48.logtailbetaSL if baselinesample1==1 & year==1999 & quarter=="Q4", ro
outreg2 using .\results\wtable_v.xls, append
***********************************************





***********************************************
*
*      APPENDIX: TABLE VI (LONGER LAGS)
*
***********************************************
foreach x of global VARSLLPCON {
gen 	 `x'L17= L17.`x' 
}
g resTotAssetsDLLP2w1L17=L17.resTotAssetsDLLP2w1
global BASELINEROBUSTNESSL17 resTotAssetsDLLP2w1L17 DLLP2w1L17 TCERatiow1L17 NPLw1L17 CostIncome2w1L17 ROEw1L17 LiquidAssetstoAssetsw1L17 DepositsToAssetsw1L17 LoansToAssetsw1L17 NonInterestIncomeSharew1L17 GrTAw1L17 

foreach x of global VARSLLPCON {
gen 	 `x'L18= L18.`x' 
}
g resTotAssetsDLLP2w1L18=L18.resTotAssetsDLLP2w1
global BASELINEROBUSTNESSL18 resTotAssetsDLLP2w1L18 DLLP2w1L18 TCERatiow1L18 NPLw1L18 CostIncome2w1L18 ROEw1L18 LiquidAssetstoAssetsw1L18 DepositsToAssetsw1L18 LoansToAssetsw1L18 NonInterestIncomeSharew1L18 GrTAw1L18 

foreach x of global VARSLLPCON {
gen 	 `x'L19= L19.`x' 
}
g resTotAssetsDLLP2w1L19=L19.resTotAssetsDLLP2w1
global BASELINEROBUSTNESSL19 resTotAssetsDLLP2w1L19 DLLP2w1L19 TCERatiow1L19 NPLw1L19 CostIncome2w1L19 ROEw1L19 LiquidAssetstoAssetsw1L19 DepositsToAssetsw1L19 LoansToAssetsw1L19 NonInterestIncomeSharew1L19 GrTAw1L19 

foreach x of global VARSLLPCON {
gen 	 `x'L20= L20.`x' 
}
g resTotAssetsDLLP2w1L20=L20.resTotAssetsDLLP2w1
global BASELINEROBUSTNESSL20 resTotAssetsDLLP2w1L20 DLLP2w1L20 TCERatiow1L20 NPLw1L20 CostIncome2w1L20 ROEw1L20 LiquidAssetstoAssetsw1L20 DepositsToAssetsw1L20 LoansToAssetsw1L20 NonInterestIncomeSharew1L20 GrTAw1L20 

* Ensure a common sample
regress logtailbeta $BASELINEROBUSTNESSL17 i.time if baselinesample1==1, ro
g baselinesample1L17 = e(sample)
regress logtailbeta $BASELINEROBUSTNESSL18 i.time if baselinesample1==1, ro
g baselinesample1L18 = e(sample)
regress logtailbeta $BASELINEROBUSTNESSL19 i.time if baselinesample1==1, ro
g baselinesample1L19 = e(sample)
regress logtailbeta $BASELINEROBUSTNESSL20 i.time if baselinesample1==1 & baselinesample1L17==1 & baselinesample1L18==1 & baselinesample1L19==1
g baselinesample1L20 = e(sample)

* Model (1) with 1 lag (1 quarter)
* Calculate partial R-squared
regress logtailbeta $BASELINEVARSINDEP i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEVARSINDEP i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEVARSINDEP) replace label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) 

regress logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags_sl.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEVARSINDEP) replace label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) 


* Model (2) with 2 lag (2 quarters)
* Calculate partial R-squared
regress logtailbeta $BASELINEROBUSTNESSL17 i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEROBUSTNESSL17 i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEROBUSTNESSL17) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) 


regress logtailbetaSL $BASELINEROBUSTNESSL17 i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEROBUSTNESSL17 i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags_sl.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEROBUSTNESSL17) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) 


* Model (3) with 3 lags (3 quarters)
* Calculate partial R-squared
regress logtailbeta $BASELINEROBUSTNESSL18 i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEROBUSTNESSL18 i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEROBUSTNESSL18) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) 

regress logtailbetaSL $BASELINEROBUSTNESSL18 i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEROBUSTNESSL18 i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags_sl.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEROBUSTNESSL18) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) 


* Model (4) with 4 lags (4 quarters)
* Calculate partial R-squared
regress logtailbeta $BASELINEROBUSTNESSL19 i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEROBUSTNESSL19 i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESSL19) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

regress logtailbetaSL $BASELINEROBUSTNESSL19 i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEROBUSTNESSL19 i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags_sl.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESSL19) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (5) with 5 lags (5 quarters)
* Calculate partial R-squared
regress logtailbeta $BASELINEROBUSTNESSL20 i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEROBUSTNESSL20 i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESSL20) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)  

regress logtailbetaSL $BASELINEROBUSTNESSL20 i.time if baselinesample1L20==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEROBUSTNESSL20 i.time if baselinesample1L20==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_vi_longerlags_sl.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESSL20) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)  
***********************************************



****************************************
*
*       APPENDIX: TABLE VII, VIII and IX (DIFFERENT LEVELS OF k)
*
****************************************
g logTBk10 =log(TBk10)
g logTBk10SL =log(TBk10SL )
g logTBk10IR =log(TBk10IR )
g logTBk20 =log(TBk20 )
g logTBk20SL =log(TBk20SL) 
g logTBk20IR =log(TBk20IR )
g logTBk30 =log(TBk30 )
g logTBk30SL =log(TBk30SL) 
g logTBk30IR =log(TBk30IR )
g logTBk50 =log(TBk50 )
g logTBk50SL =log(TBk50SL) 
g logTBk50IR =log(TBk50IR )
g logTBk60 =log(TBk60 )
g logTBk60SL =log(TBk60SL) 
g logTBk60IR =log(TBk60IR )
g logTBk70 =log(TBk70 )
g logTBk70SL =log(TBk70SL) 
g logTBk70IR =log(TBk70IR) 
g logTBk80 =log(TBk80 )
g logTBk80SL =log(TBk80SL) 
g logTBk80IR =log(TBk80IR)
**** TABLE VII: SYSTEMIC RISK *********
* Model (1)
* Calculate partial R-squared
regress logTBk10 $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk10 $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_vii_tb_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) replace label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2)
* Calculate partial R-squared
regress logTBk20 $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk20 $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_vii_tb_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
  
* Model (3)
* Calculate partial R-squared
regress logTBk30 $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk30 $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_vii_tb_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (5)
* Calculate partial R-squared
regress logTBk50 $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk50 $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_vii_tb_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (6)
* Calculate partial R-squared
regress logTBk60 $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk60 $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_vii_tb_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (7)
* Calculate partial R-squared
regress logTBk70 $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk70 $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_vii_tb_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (8)
* Calculate partial R-squared
regress logTBk80 $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk80 $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_vii_tb_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

**** TABLE VIII: SYSTEMIC LINKAGE *****
* Model (1)
* Calculate partial R-squared
regress logTBk10SL $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk10SL $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_viii_sl_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) replace label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2)
* Calculate partial R-squared
regress logTBk20SL $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk20SL $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_viii_sl_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (3)
* Calculate partial R-squared
regress logTBk30SL $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk30SL $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_viii_sl_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (5)
* Calculate partial R-squared
regress logTBk50SL $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk50SL $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_viii_sl_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (6)
* Calculate partial R-squared
regress logTBk60SL $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk60SL $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_viii_sl_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (7)
* Calculate partial R-squared
regress logTBk70SL $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk70SL $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_viii_sl_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (8)
* Calculate partial R-squared
regress logTBk80SL $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk80SL $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_viii_sl_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
 
**** TABLE IX: BANK TAIL RISK *****
* Model (1)
* Calculate partial R-squared
regress logTBk10IR $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk10IR $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_ix_ir_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) replace label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2)
* Calculate partial R-squared
regress logTBk20IR $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk20IR $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_ix_ir_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (3)
* Calculate partial R-squared
regress logTBk30IR $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk30IR $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_ix_ir_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
 
* Model (5)
* Calculate partial R-squared
regress logTBk50IR $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk50IR $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_ix_ir_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (6)
* Calculate partial R-squared
regress logTBk60IR $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk60IR $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_ix_ir_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (7)
* Calculate partial R-squared
regress logTBk70IR $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk70IR $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_ix_ir_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (8)
* Calculate partial R-squared
regress logTBk80IR $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logTBk80IR $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\wtable_ix_ir_diffKs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
**********************************





***********************************************
*
*       APPENDIX: TABLE X (OTHER ROBUSTNESS CHECKS)
*
***********************************************
* Preparations
global BASELINEROBUSTNESS1_nolags resTotAssetsDLLP2w1 DLLP2w1 $VARSCON 

global BASELINEROBUSTNESS1 resTotAssetsDLLP2w1_m DLLP2w1_m TCERatiow1_m NPLw1_m CostIncome2w1_m ROEw1_m  LiquidAssetstoAssetsw1_m DepositsToAssetsw1_m LoansToAssetsw1_m NonInterestIncomeSharew1_m GrTAw1_m 

global BASELINEROBUSTNESS2 resTotAssetsDLLP2w1 $VARSCON 

gen samplerobustness1 = 1 if (zeros_perc + missings_perc)<0.60 & truecallcrspmatch==1 & L16.TotAssetsRealw1>500000 & logtailbeta!=.
gen samplerobustness2 = 1 if (zeros_perc + missings_perc)<0.60 & truecallcrspmatch==1 & L16.TotAssetsRealw1>500000 & tailbeta!=.
g sizeemployeesL16 = log(L16.BHCK4150)

global BASELINEROBUSTNESS4 sizeemployeesL16 DLLP2w1 $VARSCON   



//>>>>>>>>>>>
//SYSTEMIC RISK::SIMULTANEOSUS CHARACTERISTICS (RWINDOWS SIZE)
* Model (1): IV-GMM with Simultaneous (averaged) bank characteristics
tsfill
foreach Item of global BASELINEROBUSTNESS1_nolags {
	mvsumm `Item' , gen(`Item'_m) stat(mean) window(16) end
}
* Partial R-squared
xi: ivreg2 logtailbeta l16.logtailbeta i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro gmm2s cluster(rssd9001)
global model_r2 = e(r2)
xi: ivreg2 logtailbeta l16.logtailbeta i.time ( = $VARSWITHNII) if e(sample), ro gmm2s cluster(rssd9001)
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
* Actual regression
*xi: cluster2 logtailbeta $BASELINEROBUSTNESS1 i.time if samplerobustness1==1, fcluster(rssd9001) tcluster(time)
xi: ivreg2 logtailbeta l16.logtailbeta i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro gmm2s cluster(rssd9001)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
/*run 'ereturn list' for the statistics evariables from the regression, 
especially Hansen J statistics, and Kleibergen-Paap rk LM statistic
. ereturn list
scalars:
                  e(N) =  15762
          e(inexog_ct) =  84
...		  
                 e(r2) =  .428025965275709
               e(rmse) =  .2554603622461217
...
			   ee(idp) =  4.25140704847e-14
               e(iddf) =  4
             e(idstat) =  68.70872622884126
                 e(jp) =  .6607264582272726
                e(jdf) =  3
                  e(j) =  1.59410830727844
...
macros:
            e(predict) : "ivreg2_p"
            e(version) : "04.1.10"

*/
global HansenJs = e(j)
global HansenJp = e(jp)
global KPLMs = e(idstat)
global KPLMp = e(idp)

outreg2 using .\results\rp_wtable_x_robustness.xls, addtext(Hansen J Statistic, `e(j)', Hansen J p value, `e(jp)', Kleibergen-Paap LM, `e(idstat)', Kleibergen-Paap LM p value, `e(idp)', "Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESS1 $VARSWITHNII) replace label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2): FE (With bank fixed effects)
set matsize 10000
* Partial R-squared
regress logtailbeta $BASELINEVARSINDEP i.rssd9001 if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.rssd9001 if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEVARSINDEP i.rssd9001 if baselinesample1==1 , fcluster(rssd9001) tcluster(time)
outreg2 using .\results\rp_wtable_x_robustness.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (3): Without taking logs (including zero \beta^T estimates)
* Calculate partial R-squared
regress tailbeta $BASELINEVARSINDEP i.time if samplerobustness2==1, ro 
global model_r2 = e(r2)
regress tailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 tailbeta $BASELINEVARSINDEP i.time if samplerobustness2==1, fcluster(rssd9001) tcluster(time)
outreg2 using .\results\rp_wtable_x_robustness.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (4): Small (banks)
* Calculate partial R-squared
regress logtailbeta $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16<log(10*1000*1000), ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16<log(10*1000*1000), fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_x_robustness.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (5): Large (banks)
* Calculate partial R-squared
regress logtailbeta $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16>log(10*1000*1000) , ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16>log(10*1000*1000), fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_x_robustness.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (6): Measure size by raw FTEs instead of Total Assets
* Calculate partial R-squared
regress logtailbeta $BASELINEROBUSTNESS4 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEROBUSTNESS4 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_x_robustness.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESS4) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Online appendix, footnote 1: IVREG instead of GMM
* Calculate partial R-squared
xi: ivreg2 logtailbeta l16.logtailbeta i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro cluster(rssd9001)
global model_r2 = e(r2)
xi: ivreg2 logtailbeta i.time ( = $VARSWITHNII) if e(sample), ro  cluster(rssd9001)
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
*xi: cluster2 logtailbeta $BASELINEROBUSTNESS1 i.time if samplerobustness1==1, fcluster(rssd9001) tcluster(time)
xi: ivreg2 logtailbeta l16.logtailbeta i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro cluster(rssd9001)
outreg2 using .\results\wtable_x_robustness_ivreg.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESS1 $VARSWITHNII) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
*******************************************************************
//SYSTEMIC RISK::SIMULTANEOUS CHARACTERISTICS::END




//>>>>>>>>>>>
//SYSTEMIC LINKAGE::SIMULTANEOUS CHARACTERISTICS
* Model (1): IV-GMM with Simultaneous (averaged) bank characteristics
* Partial R-squared
xi: ivreg2 logtailbetaSL l16.logtailbetaSL i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro gmm2s cluster(rssd9001)
global model_r2 = e(r2)
xi: ivreg2 logtailbetaSL l16.logtailbetaSL i.time ( = $VARSWITHNII) if e(sample), ro gmm2s cluster(rssd9001)
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
* Actual regression
*xi: cluster2 logtailbeta $BASELINEROBUSTNESS1 i.time if samplerobustness1==1, fcluster(rssd9001) tcluster(time)
xi: ivreg2 logtailbetaSL l16.logtailbetaSL i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro gmm2s cluster(rssd9001)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
/*run 'ereturn list' for the statistics evariables from the regression, 
especially Hansen J statistics, and Kleibergen-Paap rk LM statistic
. ereturn list
scalars:
                  e(N) =  15762
          e(inexog_ct) =  84
...		  
                 e(r2) =  .428025965275709
               e(rmse) =  .2554603622461217
...
			   ee(idp) =  4.25140704847e-14
               e(iddf) =  4
             e(idstat) =  68.70872622884126
                 e(jp) =  .6607264582272726
                e(jdf) =  3
                  e(j) =  1.59410830727844
...
macros:
            e(predict) : "ivreg2_p"
            e(version) : "04.1.10"

*/
global HansenJs = e(j)
global HansenJp = e(jp)
global KPLMs = e(idstat)
global KPLMp = e(idp)

outreg2 using .\results\rp_wtable_x_robustnessSL.xls, addtext(Hansen J Statistic, `e(j)', Hansen J p value, `e(jp)', Kleibergen-Paap LM, `e(idstat)', Kleibergen-Paap LM p value, `e(idp)', "Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESS1 $VARSWITHNII) replace label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2): FE (With bank fixed effects)
set matsize 10000
* Partial R-squared
regress logtailbetaSL $BASELINEVARSINDEP i.rssd9001 if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.rssd9001 if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEVARSINDEP i.rssd9001 if baselinesample1==1 , fcluster(rssd9001) tcluster(time)
outreg2 using .\results\rp_wtable_x_robustnessSL.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (3): Without taking logs (including zero \beta^T estimates)
* Calculate partial R-squared
regress taupower $BASELINEVARSINDEP i.time if samplerobustness2==1 , ro
global model_r2 = e(r2)
regress taupower i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 taupower $BASELINEVARSINDEP i.time if samplerobustness2==1, fcluster(rssd9001) tcluster(time)
outreg2 using .\results\rp_wtable_x_robustnessSL.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (4): Small (banks)
* Calculate partial R-squared
regress logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16<log(10*1000*1000), ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16<log(10*1000*1000), fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_x_robustnessSL.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (5): Large (banks)
* Calculate partial R-squared
regress logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16>log(10*1000*1000) , ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16>log(10*1000*1000), fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_x_robustnessSL.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (6): Measure size by raw FTEs instead of Total Assets
* Calculate partial R-squared
regress logtailbetaSL $BASELINEROBUSTNESS4 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEROBUSTNESS4 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_x_robustnessSL.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESS4) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Online appendix, footnote 1: IVREG instead of GMM
* Calculate partial R-squared
xi: ivreg2 logtailbetaSL l16.logtailbetaSL i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro cluster(rssd9001)
global model_r2 = e(r2)
xi: ivreg2 logtailbetaSL i.time ( = $VARSWITHNII) if e(sample), ro cluster(rssd9001)
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
*xi: cluster2 logtailbeta $BASELINEROBUSTNESS1 i.time if samplerobustness1==1, fcluster(rssd9001) tcluster(time)
xi: ivreg2 logtailbetaSL l16.logtailbetaSL i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro cluster(rssd9001)
outreg2 using .\results\wtable_x_robustness_ivregSL.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESS1 $VARSWITHNII) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
*******************************************************************
//SYSTEMIC LINKAGE::SIMULTANEOUS CHARACTERISTICS::END





//>>>>>>>>>>>
//BANK-SPECIFIC RISK::SIMULTANEOUS CHARACTERISTICS
* Model (1): IV-GMM with Simultaneous (averaged) bank characteristics
* Partial R-squared
xi: ivreg2 logtailbetaIR l16.logtailbetaIR i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro gmm2s cluster(rssd9001)
global model_r2 = e(r2)
xi: ivreg2 logtailbetaIR i.time ( = $VARSWITHNII) if e(sample), ro gmm2s cluster(rssd9001)
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
* Actual regression
*xi: cluster2 logtailbeta $BASELINEROBUSTNESS1 i.time if samplerobustness1==1, fcluster(rssd9001) tcluster(time)
xi: ivreg2 logtailbetaIR l16.logtailbetaIR i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro gmm2s cluster(rssd9001)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
/*run 'ereturn list' for the statistics evariables from the regression, 
especially Hansen J statistics, and Kleibergen-Paap rk LM statistic
. ereturn list
scalars:
                  e(N) =  15762
          e(inexog_ct) =  84
...		  
                 e(r2) =  .428025965275709
               e(rmse) =  .2554603622461217
...
			   ee(idp) =  4.25140704847e-14
               e(iddf) =  4
             e(idstat) =  68.70872622884126
                 e(jp) =  .6607264582272726
                e(jdf) =  3
                  e(j) =  1.59410830727844
...
macros:
            e(predict) : "ivreg2_p"
            e(version) : "04.1.10"

*/
global HansenJs = e(j)
global HansenJp = e(jp)
global KPLMs = e(idstat)
global KPLMp = e(idp)

outreg2 using .\results\rp_wtable_x_robustnessIR.xls, addtext(Hansen J Statistic, `e(j)', Hansen J p value, `e(jp)', Kleibergen-Paap LM, `e(idstat)', Kleibergen-Paap LM p value, `e(idp)', "Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESS1 $VARSWITHNII) replace label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (2): FE (With bank fixed effects)
set matsize 10000
* Partial R-squared
regress logtailbetaIR $BASELINEVARSINDEP i.rssd9001 if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.rssd9001 if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaIR $BASELINEVARSINDEP i.rssd9001 if baselinesample1==1 , fcluster(rssd9001) tcluster(time)
outreg2 using .\results\rp_wtable_x_robustnessIR.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (3): Without taking logs (including zero \beta^T estimates)
* Calculate partial R-squared
regress tailbetaIR $BASELINEVARSINDEP i.time if samplerobustness2==1 , ro
global model_r2 = e(r2)
regress tailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 tailbetaIR $BASELINEVARSINDEP i.time if samplerobustness2==1, fcluster(rssd9001) tcluster(time)
outreg2 using .\results\rp_wtable_x_robustnessIR.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (4): Small (banks)
* Calculate partial R-squared
regress logtailbetaIR $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16<log(10*1000*1000), ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaIR $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16<log(10*1000*1000), fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_x_robustnessIR.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (5): Large (banks)
* Calculate partial R-squared
regress logtailbetaIR $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16>log(10*1000*1000) , ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaIR $BASELINEVARSINDEP i.time if baselinesample1==1 & logTotAssetsRealw1L16>log(10*1000*1000), fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_x_robustnessIR.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEVARSINDEP) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (6): Measure size by raw FTEs instead of Total Assets
* Calculate partial R-squared
regress logtailbetaIR $BASELINEROBUSTNESS4 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaIR $BASELINEROBUSTNESS4 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_x_robustnessIR.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESS4) append label  addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Online appendix, footnote 1: IVREG instead of GMM
* Calculate partial R-squared
xi: ivreg2 logtailbetaIR l16.logtailbetaIR i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro cluster(rssd9001)
global model_r2 = e(r2)
xi: ivreg2 logtailbetaIR i.time ( = $VARSWITHNII) if e(sample), ro cluster(rssd9001)
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
*xi: cluster2 logtailbeta $BASELINEROBUSTNESS1 i.time if samplerobustness1==1, fcluster(rssd9001) tcluster(time)
xi: ivreg2 logtailbetaIR l16.logtailbetaIR i.time ($BASELINEROBUSTNESS1 = $VARSWITHNII) if baselinesample1==1, ro cluster(rssd9001)
outreg2 using .\results\wtable_x_robustness_ivregIR.xls, addtext("Time fixed effects", Yes, "Bank fixed effects", No, "Clustering at bank level", Yes, "Clustering at time level", Yes)  bdec(3) sdec(3) keep($BASELINEROBUSTNESS1 $VARSWITHNII) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
*******************************************************************
//BANK-SPECIFIC RISK::SIMULTANEOUS CHARACTERISTICS::END






// SYSTEMIC RISK::BASELINE RESUTLS WITH ALTERNATIVE MEASURES FOR LLP
* Model (1)
* Calculate partial R-squared
regress logtailbeta $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
//global adjusted_r2 = e(r2_a)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPs.xls, bdec(3) sdec(3) replace label keep($BASELINEVARSINDEP) addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) 


* Model (2) :: LLR2w1 
* Calculate partial R-squared
regress logtailbeta resTotAssetsLLR2w1L16 LLR2w1L16 $VARSCONLAG16 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta resTotAssetsLLR2w1L16 LLR2w1L16 $VARSCONLAG16 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
qui tab rssd9001 if e(sample)
local NoBnks= `r(r)'
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(resTotAssetsLLR2w1L16 LLR2w1L16 $VARSCONLAG16) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
 
 
* Model (3) :: LLP2lagw1
* Calculate partial R-squared
regress logtailbeta resTotAssetsLLP2lagw1L16 LLP2lagw1L16 $VARSCONLAG16 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta resTotAssetsLLP2lagw1L16 LLP2lagw1L16 $VARSCONLAG16 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(resTotAssetsLLP2lagw1L16 LLP2lagw1L16 $VARSCONLAG16) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
***********************************************


* Model (4) :: ALLP2rw1
* Calculate partial R-squared
regress logtailbeta resTotAssetsALLP2rw1L16 ALLP2rw1L16 $VARSCONLAG16 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta resTotAssetsALLP2rw1L16 ALLP2rw1L16 $VARSCONLAG16 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(resTotAssetsALLP2rw1L16 ALLP2rw1L16 $VARSCONLAG16) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
***********************************************


* Model (5) :: NDLLP2w1
* Calculate partial R-squared
regress logtailbeta resTotAssetsNDLLP2w1L16 NDLLP2w1L16 $VARSCONLAG16 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta resTotAssetsNDLLP2w1L16 NDLLP2w1L16 $VARSCONLAG16 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(resTotAssetsNDLLP2w1L16 NDLLP2w1L16 $VARSCONLAG16) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
***********************************************
// SYSTEMIC RISK::BASELINE RESUTLS WITH ALTERNATIVE MEASURES FOR LLP::END




// SYSTEMIC LINKAGE::BASELINE RESUTLS WITH ALTERNATIVE MEASURES FOR LLP
* Model (1)
* Calculate partial R-squared
regress logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEVARSINDEP i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
//global adjusted_r2 = e(r2_a)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPsSL.xls, bdec(3) sdec(3) replace label keep($BASELINEVARSINDEP) addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) 


* Model (2) :: LLR2w1 
* Calculate partial R-squared
regress logtailbetaSL resTotAssetsLLR2w1L16 LLR2w1L16 $VARSCONLAG16 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL resTotAssetsLLR2w1L16 LLR2w1L16 $VARSCONLAG16 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
qui tab rssd9001 if e(sample)
local NoBnks= `r(r)'
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPsSL.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(resTotAssetsLLR2w1L16 LLR2w1L16 $VARSCONLAG16) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
 
 
* Model (3) :: LLP2lagw1
* Calculate partial R-squared
regress logtailbetaSL resTotAssetsLLP2lagw1L16 LLP2lagw1L16 $VARSCONLAG16 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL resTotAssetsLLP2lagw1L16 LLP2lagw1L16 $VARSCONLAG16 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPsSL.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(resTotAssetsLLP2lagw1L16 LLP2lagw1L16 $VARSCONLAG16) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
***********************************************


* Model (4) :: ALLP2rw1
* Calculate partial R-squared
regress logtailbetaSL resTotAssetsALLP2rw1L16 ALLP2rw1L16 $VARSCONLAG16 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL resTotAssetsALLP2rw1L16 ALLP2rw1L16 $VARSCONLAG16 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPsSL.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(resTotAssetsALLP2rw1L16 ALLP2rw1L16 $VARSCONLAG16) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
***********************************************


* Model (5) :: NDLLP2w1
* Calculate partial R-squared
regress logtailbetaSL resTotAssetsNDLLP2w1L16 NDLLP2w1L16 $VARSCONLAG16 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL resTotAssetsNDLLP2w1L16 NDLLP2w1L16 $VARSCONLAG16 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPsSL.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep(resTotAssetsNDLLP2w1L16 NDLLP2w1L16 $VARSCONLAG16) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
***********************************************
// SYSTEMIC LINKAGE::BASELINE RESUTLS WITH ALTERNATIVE MEASURES FOR LLP::END
  
  
  
  
  
  
  
  
  
  
  
  

// ALTERNATIVE MEASURES FOR LLP
* Model (1)
* LLR
* Calculate partial R-squared
regress logtailbeta LLR2w1 $BASELINEROBUSTNESS2 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbeta LLR2w1 $BASELINEROBUSTNESS2 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
//global adjusted_r2 = e(r2_a)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPs.xls, bdec(3) sdec(3) replace label keep($BASELINEROBUSTNESS2) addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) 


* Model (2)
* LLR
* Calculate partial R-squared
regress logtailbetaSL LLR2w1 $BASELINEROBUSTNESS2 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaSL i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL LLR2w1 $BASELINEROBUSTNESS2 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
//global adjusted_r2 = e(r2_a)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPs.xls, bdec(3) sdec(3) replace label keep($BASELINEROBUSTNESS2) addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2) addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) 


* Model (3)
* LLPlag : LLPs by lag-1 TotalLoans
* Calculate partial R-squared
regress logtailbeta LLP2w1 $BASELINEROBUSTNESS2 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbeta i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaSL $BASELINEROBUSTNESS2 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
qui tab rssd9001 if e(sample)
local NoBnks= `r(r)'

* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEROBUSTNESS2) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)

* Model (3)
* Calculate partial R-squared
regress logtailbetaIR $BASELINEROBUSTNESS2 i.time if baselinesample1==1, ro
global model_r2 = e(r2)
regress logtailbetaIR i.time if e(sample), ro
global dummy_r2 = e(r2)
global partial_r2 = ($model_r2 - $dummy_r2) / ( 1 - $dummy_r2)
egen bankscount = group(rssd9001) if e(sample)
qui sum bankscount
global numberofbanks = r(max)
drop bankscount
* Actual regression
xi: cluster2 logtailbetaIR $BASELINEROBUSTNESS2 i.time if baselinesample1==1, fcluster(rssd9001) tcluster(time)
* Output
outreg2 using .\results\rp_wtable_xi_robustALTsLLPs.xls, addtext("Time fixed effects", Yes, "Clustering at bank level", Yes, "Clustering at time level", Yes) bdec(3) sdec(3) keep($BASELINEROBUSTNESS2) append label addstat(Number of Banks, $numberofbanks, Partial R-squared, $partial_r2)
***********************************************

