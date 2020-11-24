/* this is a wrapper to get some exploratory data for hedonics
I've put in in the aceprice folder, but  there is not good reason for it to be here.*/
version 15.1
#delimit cr


/*args for this wrapper, load and save data*/
local in_prices ${data_raw}/raw_dealer_prices_${vintage_string}.dta 
/*local  price_done ${data_main}/dealer_prices_real_lags_condition${vintage_string}.dta  */
local  price_done ${data_main}/dealer_prices_final_full_${vintage_string}.dta 

local  subset_stub ${data_main}/dealer_prices_final_spp

/*args for do "${processing_code}/A04_imports_month_whiting.do"*/
global trade ${data_external}/whiting_trade${vintage_string}.dta 
global trade_out ${data_main}/whiting_trade_monthly${vintage_string}.dta 


/* args for do "${processing_code}/A01_add_in_deflators.do" */
global deflators $data_external/deflatorsQ_${vintage_string}.dta
global income $data_external/incomeQ_${vintage_string}.dta 
global recession $data_external/recessionM_${vintage_string}.dta


/* args for do do "${processing_code}/A03_fish_conditions_annual.do" */
global in_relcond ${data_raw}/annual_condition_index_${vintage_string}.dta 
/* files for Relative condition data, which one are you using 
could use  
global in_relcond ${data_raw}/annual_condition_indexEPU_${vintage_string}.dta 
global in_relcond_leng ${data_raw}/annual_condition_indexEPU_length_${vintage_string}.dta 
*/

/*args for do "${processing_code}/A06_merge_daily_landings.do"*/
global daily ${data_raw}/raw_entire_fishery_${vintage_string}.dta 



/* 

NOTE, this pulls in very specific trade data for whiting. You will probably want to change this.
I'd suggest copy and renaming this 

do "${processing_code}/A04_imports_month_whiting.do"

to a different place and using it for your code and inserting it here.

Also change the globals above.
*/

/* Process trade */
do "${processing_code}/A04_imports_month_whiting.do"



use `in_prices', replace
replace value=value/1000
replace landings=landings/1000
label var landings "000s of lbs"
label var value "000s of dollars"



/* bring deflators and income into the dataset */
do "${processing_code}/A01_add_in_deflators.do"

/* use the dataset to construct daily quantities */
do "${processing_code}/A02_construct_daily_and_lags.do"

/* process and merge fish conditions */
do "${processing_code}/A03_fish_conditions_annual.do"


/* Bring in monthly recession indicators */
do "${processing_code}/A05_add_in_recession_indicators.do"


/* and add in daily fishery landings and value*/

do "${processing_code}/A06_merge_daily_landings.do"


/* merge in trade data */
merge m:1 year month using $trade_out, keep(1 3)
drop _merge

qui compress
save `price_done', replace


levelsof nespp3, local(species)
foreach sp of local species{
local  savename `subset_stub'_`sp'_${vintage_string}.dta 
di "`savename'"
preserve
keep if nespp3==`sp'
save `savename', replace 
restore
}

/* when you finish this, you'll have 1 "final_full" dataset and many datasets "finall_spp" with just 1 species in it */



