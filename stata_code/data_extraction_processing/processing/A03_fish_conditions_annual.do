/* code to merge in fish condition data  */




version 15.1
pause off

timer on 1

/* files for Relative condition data, which one are you using?*/
local  in_relcond ${data_raw}/annual_condition_indexEPU_${vintage_string}.dta 
local  in_relcond_leng ${data_raw}/annual_condition_indexEPU_length_${vintage_string}.dta 
local in_relcond_Year ${data_raw}/annual_condition_index_${vintage_string}.dta 


local  price_raw ${data_main}/dealer_prices_real_lags${vintage_string}.dta 
local  price_done ${data_main}/dealer_prices_real_lags_condition${vintage_string}.dta 


use `price_raw', replace
merge m:1 nespp3 year using `in_relcond_Year', keep(1 3)
assert _merge==3
drop _merge
save `price_done', replace
