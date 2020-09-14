/* this is a wrapper to get some exploratory data for hedonics
I've put in in the aceprice folder, but  there is not good reason for it to be here.*/
version 15.1
#delimit cr



local in_prices ${data_raw}/raw_dealer_prices_${vintage_string}.dta 
local  price_done ${data_main}/dealer_prices_real_lags_condition${vintage_string}.dta 


global trade ${data_external}/whiting_trade${vintage_string}.dta 
global trade_out ${data_main}/whiting_trade_monthly${vintage_string}.dta 


/* Process trade */
do "${processing_code}/A04_imports_month.do"



use `in_prices', replace
merge m:1 year month using $trade_out, keep(1 3)
drop _merge


/* bring deflators and income into the dataset */
do "${processing_code}/A01_add_in_deflators.do"

/* use the dataset to construct daily quantities */
do "${processing_code}/A02_construct_daily_and_lags.do"

/* process and merge fish conditions */
do "${processing_code}/A03_fish_conditions_annual.do"

save `price_done', replace


