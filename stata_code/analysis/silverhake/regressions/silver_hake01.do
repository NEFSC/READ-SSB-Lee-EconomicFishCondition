/* code to run some preliminary regressions on Silver Hake.*/
/* Most of these regressions are probably fatally misspecified */
/* but still, it's good to keep a record of them */
cap log close


local logfile "silver_hake01_${vintage_string}.smcl"

global silverhake_results ${my_results}/silverhake
global silverhake_tables ${my_tables}/silverhake


log using ${silverhake_results}/`logfile', replace

version 15.1
pause off
vintage_lookup_and_reset
/* tidy ups */
postutil clear
estimates clear

global working_nespp3 509
local  in_data ${data_main}/dealer_prices_final_spp_${working_nespp3}_${vintage_string}.dta 
local  marketcats ${data_raw}/dealer_nespp4_codes${vintage_string}.dta 

global linear_table1 ${silverhake_tables}/silver_hake1.tex
global linear_table2 ${silverhake_tables}/silver_hake2.tex

local  ster_out ${silverhake_results}/silver_hake01_${vintage_string}.ster 


/* don't show year or month coeficients in outreg */
local months 1.month 2.month 3.month 4.month 5.month 6.month 7.month 8.month 9.month 10.month 11.month 12.month 0.month 0b.month 12o.month
local years 1995.year 1996.year 1997.year 1998.year 1999.year 2000.year 2001.year 2002.year 2003.year 2004.year 2005.year 2006.year 2007.year 2008.year 2009.year 2010.year 2011.year 2012.year 2013.year 2014.year 2015.year 2016.year 2017.year 2018.year 2019.year 2020.year
local dow 1.dow 2.dow 3.dow  4.dow  5.dow  6.dow 


clear
use `in_data' , clear
assert nespp3==${working_nespp3}
cap drop _merge
gen nominal=value/landings

/* pull in market categories*/
merge m:1 nespp4 using `marketcats', keep(1 3)
assert _merge==3
labmask nespp4, value(sp_mkt)
drop _merge






/* Normalize 
Need to deflate */
gen priceR_GDPDEF=valueR_GDPDEF/landings

foreach var of varlist price_noblueEXP price_allEXP price_noblueIMP price_allIMP price_noblueREX price_allREX price_*IMP_lag* {
gen `var'_R_GDPDEF=`var'/fGDP
}

gen ihspriceR=asinh(priceR_GDPDEF)
gen ihsrGDPcapita=asinh(rGDPcapita)

gen ihsimportR=asinh(price_allIMP_R_GDPDEF)
gen ihsimport_lag1=asinh(price_allIMP_lag1_R_GDPDEF)
gen ihsimport_lag12=asinh(price_allIMP_lag12_R_GDPDEF)

/********************************************************/
/********************************************************/
/* you really need to do more data cleaning and look at some descriptive statistics */
/********************************************************/
/********************************************************/

/* mark the estimation sample */
cap drop date
cap drop markin
gen date=mdy(month,day,year)

gen markin=1
replace markin=0 if date==.
replace markin=0 if nominal>8 
replace markin=0 if inlist(nespp4,5097)==1

local ifconditional "if markin==1"
cap drop _merge

/* there will also be a few rows that do not match because there are zero landings. */


/* don't estimate for invalid dates, prices that are too high, or 5097 market category*/



/* Some of these models aren't really well thought out. Here are some ideas for improvement.
We don't really want to estimate a full blown demand system (for whiting).  One specification allows the own-quantity and other-quantity effects to be different.
		However, another way to do it might be to group them into three groups: own, smaller-, and larger-sized

		
	We could allow the condition effects to vary across the market categories : c.meancond_Annual c.stddevcond_Annual)##ib5090.nespp4 
	I'm not sure how to interpret these either.
	
	
	*/

/* market categories changed a bit over time */
/* this is a bad regression, I experiminted with it a bit to figure out how to set up the shift in market categories (mkt_shift) */
gen mkt_shift=date>=mdy(1,1,2004)
reg priceR_GDPDEF lnq rGDPcapita ib1.mkt_shift#ib5090.nespp4 i.year `ifconditional', robust



/* Model OLS00: Basic ols, where real prices are a function of log aggregate quantities, GDP, market category and year dummies.  This is a bad regression.*/
reg priceR_GDPDEF lnq rGDPcapita ib5090.nespp4 i.year `ifconditional', robust
pause
outreg2 using ${linear_table1}, tex(frag) label adds(ll, e(ll), rmse, e(rmse)) addtext(Year effects, Yes, Month Effects, No, Day of week effects, No, Vessel Effects, No,  Model, OLS) drop(`years') replace ctitle("Real Price")

/* Model OLS01:  Same as immediately previous, but with month dummies.  This is a bad regression.*/

reg priceR_GDPDEF lnq rGDPcapita ib5090.nespp4 i.month  i.year  `ifconditional',robust
outreg2 using ${linear_table1}, tex(frag) label adds(ll, e(ll), rmse, e(rmse)) addtext(Year effects, Yes, Month Effects, Yes,  Day of week effects, No, Vessel Effects, No, Model, OLS) drop(`months' `years')  ctitle("Real Price")

/* Model OLS02: Same as immediately previous, but with day-of-week dummies.  This is a bad regression.*/

reg priceR_GDPDEF lnq rGDPcapita ib5090.nespp4 i.month  i.year  i.dow `ifconditional', robust
outreg2 using ${linear_table1}, tex(frag) label adds(ll, e(ll), rmse, e(rmse)) addtext(Year effects, Yes, Month Effects, Yes,  Day of week effects, Yes, Vessel Effects, No, Model, OLS) drop(`months' `years' `dow')  ctitle("Real Price")

/* Model OLS03: Same as immediately previous, but with vessel dummies.  This is a bad regression.*/

areg priceR_GDPDEF lnq rGDPcapita ib5090.nespp4 ib7.month  i.year i.dow  `ifconditional', absorb(permit) robust
outreg2 using ${linear_table1}, tex(frag) label adds(ll, e(ll), rmse, e(rmse)) addtext(Year effects, Yes, Month Effects, Yes, Vessel Effects, Yes, Model,OLS) drop(`months' `years' `dow')  ctitle("Real Price")

/***************************************************************************************/
/******************These IV models are similar to OLS but use lags as instruments for endogenous quantities***************************/
/* MODEL IV01: This is model OLS01, but using lag of quantities as an instrument */
ivregress 2sls priceR_GDPDEF rGDPcapita ib5090.nespp4  i.year (lnq=lnq_lag1)  `ifconditional' , robust
outreg2 using ${linear_table1}, tex(frag) label adds(rmse, e(rmse)) addtext(Year effects, Yes, Month Effects, No,  Day of week effects, No, Model, IV) drop(`years')  ctitle("Real Price")

/* MODEL IV02: This is model OLS02, but using lag of quantities as an instrument */
ivregress 2sls priceR_GDPDEF rGDPcapita ib5090.nespp4 i.month  i.year (lnq=lnq_lag1)  `ifconditional',robust
outreg2 using ${linear_table1}, tex(frag) label adds(rmse, e(rmse)) addtext(Year effects, Yes, Month Effects, Yes,  Day of week effects, No, Model, IV) drop(`months' `years')  ctitle("Real Price")
 
 
 /***************************************************************************************/

 
 /***************************************************************************************/
/******************These IV models are similar to the previous but use the IHS transforms ***************************/
/******************These vary based on the fixed effects ***************************/

 /* MODEL IV11: try the IV model using the inverse hyperbolic sin transform with Year Dummies. This is similar to IV01, but also disaggregates the silver hake landings into "own" and "other */
 ivregress 2sls priceR_GDPDEF ihsrGDPcapita ib5090.nespp4  i.year (ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1)  `ifconditional', cluster(date)

 *outreg2 using ${linear_table1}, tex(frag) label adds(rmse, e(rmse)) addtext(Year effects, Yes, Month Effects, No, Model, IV) drop(`years')  ctitle("Real Price")

 
 
 /* MODEL IV12:try the IV model using the inverse hyperbolic sin transform  with Year and Month Dummies. This is similar to IV02, but also disaggregates the silver hake landings into "own" and "other */

 ivregress 2sls ihspriceR ihsrGDPcapita ib5090.nespp4  i.year i.month (ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1)  `ifconditional', cluster(date)
est store YearDums
 
 outreg2 using ${linear_table2}, tex(frag) label adds(rmse, e(rmse)) addtext(Year effects, Yes, Month Effects, Yes, Day of week effects, No, Vessel Effects, No,  Model, IV) drop(`years' `months' `dow') replace ctitle("IHS Price")

 
 
/* MODEL IV13:try the IV model using the inverse hyperbolic sin transform  with Year and Day-of-week Dummies. This is similar to IV02, but also disaggregates the silver hake landings into "own" and "other */
 ivregress 2sls ihspriceR ihsrGDPcapita ib5090.nespp4  i.year i.dow (ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1)  `ifconditional', cluster(date)
est store YearDums
 
 outreg2 using ${linear_table2}, tex(frag) label adds(rmse, e(rmse)) addtext(Year effects, Yes, Month Effects, No, Day of week effects, Yes, Vessel Effects, No,  Model, IV) drop(`years' `months' `dow') replace ctitle("IHS Price")

 
 
 /* MODEL IV14:try the IV model using the inverse hyperbolic sin transform  with Month and day-of-week Dummies.  */

 ivregress 2sls ihspriceR ihsrGDPcapita ib5090.nespp4  i.month  i.dow (ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1)  `ifconditional', cluster(date)
 outreg2 using ${linear_table2}, tex(frag) label adds( rmse, e(rmse)) addtext(Year effects, No, Month Effects, Yes, Day of week effects, Yes, Vessel Effects, No,  Model, IV) drop(`years' `months' `dow') ctitle("IHS Price")

 est store YearMonthDums
 
 /* MODEL IV14:try the IV model using the inverse hyperbolic sin transform  only day of week dummies.  */
 ivregress 2sls ihspriceR ihsrGDPcapita ib5090.nespp4  i.dow (ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1)  `ifconditional', cluster(date)

 est store Pooled

 
 /***************************************************************************************/
 
 
 
 
/******************These IV models are similar to the previous but use the IHS transforms ***************************/
/******************These vary based on the fixed effects ***************************/

 
gen qtr=quarter(date)
gen quarterly=qofd(date)

  
  
  
  
   /* MODEL IV21:try the IV model using the inverse hyperbolic sin transform  year, quarter, day of week dummies.  */

  ivregress 2sls ihspriceR ihsrGDPcapita ib5090.nespp4  i.year i.qtr i.dow (ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1)  `ifconditional', cluster(date)

  est store YearQtrDums
  
  /* MODEL IV22:try the IV model using the inverse hyperbolic sin transform  quarterly and day-of-week dummies.  */
	 
  /* can't put in GDPcapita AND quarterly dummies */
    ivregress 2sls ihspriceR ib5090.nespp4  i.quarterly i.dow (ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1)  `ifconditional', cluster(date)
  est store QuarterlyDums

    /* MODEL IV23:try the IV model using the inverse hyperbolic sin transform  quarter and day-of-week dummies. (same as IV21, but without year dummies)  */

    ivregress 2sls ihspriceR ihsrGDPcapita ib5090.nespp4  i.qtr i.dow (ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1)  `ifconditional', cluster(date)
  est store QtrDums

  
  est table YearDums YearMonthDums Pooled YearQtrDums QtrDums QuarterlyDums, keep( ihsrGDPcapita ihs_ownq ihs_other_landings 5091.nespp4 5092.nespp4 5093.nespp4 5094.nespp4 5095.nespp4 5096.nespp4) b p
  est table YearDums YearMonthDums Pooled YearQtrDums QtrDums QuarterlyDums, drop( ihsrGDPcapita ihs_ownq ihs_other_landings  5091.nespp4 5092.nespp4 5093.nespp4 5094.nespp4 5095.nespp4 5096.nespp4) b p

	
	
/*models with condition factor */
 
 /* MODEL IV31:try the IV model with Condition Factor.  This is a linear-ish model and probably not well specified.  */

 
 
 ivregress 2sls priceR_GDPDEF rGDPcapita ib5090.nespp4  i.month meancond_Annual stddevcond_Annual (lnq=lnq_lag1)  `ifconditional' , robust
est store IVcondition
 
 
  /* MODEL IV32:try the IV model with Condition Factor.  This is IHS transformed. so it might be a bit better. However, it treats import prices as exogenous, which is probably not good. */

  ivregress 2sls ihspriceR ihsrGDPcapita ib5090.nespp4   meancond_Annual stddevcond_Annual price_allIMP_R_GDPDEF i.dow (ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1)  `ifconditional', cluster(date)
est store IHScondition
 outreg2 using ${linear_table2}, tex(frag) label adds( rmse, e(rmse)) addtext(Year effects, No, Month Effects, no, Day of week effects, Yes, Vessel Effects, No,  Model, IV) drop(`years' `months' `dow') ctitle("IHS Price")


  /* MODEL IV33: try the IV model with Condition Factor.  This is linear. However, it treats import prices as endogenous (instruments with lags) which is a bit better. */

  ivregress 2sls priceR_GDPDEF rGDPcapita ib5090.nespp4##(c.meancond_Annual c.stddevcond_Annual)  i.dow (price_allIMP_R_GDPDEF own4landings other_landings=ownq_lag1 other_landings_lag1 price_allIMP_lag1_R_GDPDEF price_allIMP_lag12_R_GDPDEF )   `ifconditional', cluster(date)
  est store LEVELcondition

 /* MODEL IV34: try the IV model with Condition Factor.  This is IHS transformed.  Out of all the models in this do file, this is the most likely to be reasonably specified.  
 Shortcoming: are 1. Permit fixed effects
 No Year Fixed Effects*/
 ivregress 2sls ihspriceR ihsrGDPcapita ib5090.nespp4   meancond_Annual stddevcond_Annual i.month i.dow (ihsimportR ihs_ownq ihs_other_landings=ihsownq_lag1 ihs_other_landings_lag1 ihsimport_lag1 ihsimport_lag12)  `ifconditional', cluster(date)
 outreg2 using ${linear_table2}, tex(frag) label adds( rmse, e(rmse)) addtext(Year effects, No, Month Effects, Yes, Day of week effects, Yes, Vessel Effects, No,  Model, IV) drop(`years' `months' `dow') ctitle("IHS Price")

 
 log close
