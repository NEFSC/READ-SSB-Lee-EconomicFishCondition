/* code to merge in fish condition data  */
cap log close


local logfile "exploratory_condition${vintage_string}.smcl"
global common_results ${my_results}/common
global common_tables ${my_tables}/common
global common_images ${my_images}/common

log using ${common_results}/`logfile', replace




version 15.1
pause off
timer on 1
vintage_lookup_and_reset


/* files for Relative condition data, which one are you using?*/
local  in_relcond ${data_raw}/annual_condition_indexEPU_${vintage_string}.dta 
local  in_relcond_leng ${data_raw}/annual_condition_indexEPU_length_${vintage_string}.dta 
local in_relcond_Year ${data_raw}/annual_condition_index_${vintage_string}.dta 


local prices ${data_raw}/annual_nespp4_${vintage_string}.dta 
local deflators $data_external/deflatorsY_${vintage_string}.dta
/* bring in deflators and construct real compensation */


local outfile explore_price_condition_${vintage_string}.dta

local regress_out price_condition_reg.tex


use `prices', clear

collapse (sum) landings value, by(nespp3 year)
merge m:1 year using `deflators', keep(1 3)
assert _merge==3
drop _merge

gen valueR_GDPDEF=value/fGDP

gen priceR_GDPDEF=valueR_GDPDEF/landings

bysort nespp3: egen pbar=mean(priceR_GDPDEF)
gen delp=(priceR_GDPDEF-pbar)/pbar
tempfile p2
save `p2'



use  `in_relcond_Year',clear
bysort nespp3: gen N=_N
tsset nespp3 year

egen t=tag(nespp3)
browse if t==1 & N<=27
tsfill, full
bysort nespp3: replace svspp=l1.svspp if svspp==.
bysort nespp3: replace species=species[_n-1] if strmatch(species,"")
browse if meancond==.

labmask svspp, values(species)
labmask nespp3, values(species)

gen upper=meancond+stddev
gen lower=meancond-stddev

bysort nespp3: egen mm=mean(meancond) 
replace mm=. if meancond==.
label var mm "mean condition over time series"
xtline meancond  mm if nespp3~=344, tmtick(##5) cmissing(n)
graph export ${common_images}/fish_conditions_${vintage_string}.png, replace as(png)  width(2000)


gen del=10*(meancond-mm)/mm
xtline del, tmtick(##5) cmissing(n)
graph export ${common_images}/delta_conditions_${vintage_string}.png, replace as(png)  width(2000)

merge 1:m nespp3 year using `p2'

xtline del delp, tmtick(##5) cmissing(n) legend(order( 1 "deviations in condition factor" 2 "deviations in real prices"))
graph export ${my_images}/common/delta_conditions_and_prices_${vintage_string}.png, replace as(png) width(2000)

sepscatter delp del if inlist(nespp3,250,366)==0, separate(nespp3) legend(off) name(sepscatter,replace) ytitle("Deviation in real prices" ) xtitle("Deviations in condition factor")
graph export ${common_images}/scatter_conditions_and_prices_${vintage_string}.png, replace as(png) width(2000)



sepscatter delp del if inlist(nespp3,250,366)==0 & nespp3<=168, separate(nespp3) name(sepscatterA,replace) ytitle("Deviation in real prices" ) xtitle("Deviations in condition factor") legend(cols(4))
graph export ${common_images}/scatter_conditions_and_pricesA_${vintage_string}.png, replace as(png) width(2000)


sepscatter delp del if inlist(nespp3,250,366)==0 & nespp3>168, separate(nespp3) name(sepscatterB,replace) ytitle("Deviation in real prices" ) xtitle("Deviations in condition factor") legend(cols(4))
graph export ${common_images}/scatter_conditions_and_pricesB_${vintage_string}.png, replace as(png) width(2000)


/* do a regression of price on condition at the annual level.*/

statsby _b _se N, by(nespp3) saving(${common_results}/`outfile', replace): regress delp del

use ${common_results}/`outfile', clear
rename _eq2_stat_1 N
gen significant =abs(_b_del/_se_del)>1.31
gsort - _b_del
rename _b_del beta_condition
rename _se_del se_condition
decode nespp3, gen(species)
order specie beta_condition se_condition signif


mkmat beta_condition se_condition signif, matrix(output) rownames(species)
estout matrix(output, fmt(a3 a3 a1)) using  ${common_tables}/`regress_out', style(tex) title("") replace substitute("_" " ")
save ${common_results}/`outfile', replace


graph close _all
log close
