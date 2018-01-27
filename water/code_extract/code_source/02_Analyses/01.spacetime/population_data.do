***Population data***
use "J:/Project/Mortality/GBD Envelopes/04. Lifetables/02. MORTMatch/cluster/results/compiled/GBD_envelope_pop_national_subnational_16 Oct 2013.dta", clear
keep year sex age pop aggregate iso3
drop if iso3==""
drop if sex=="both"
drop if age=="ALL" | age=="under-5" | age=="0" | age=="1" | age=="10" | age=="enn" | age=="lnn" | age=="pnn"
order iso3 year sex age
sort iso3 age sex

preserve
keep if age=="15" | age=="20" 
collapse (sum) pop, by(iso3 year sex)
gen age_group="15"
tempfile 15_24
save `15_24', replace
restore

preserve
keep if age=="25" | age=="30" 
collapse (sum) pop, by(iso3 year sex)
gen age_group="25"
tempfile 25_34
save `25_34', replace
restore

preserve
keep if age=="35" | age=="40" 
collapse (sum) pop, by(iso3 year sex)
gen age_group="35"
tempfile 35_44
save `35_44', replace
restore

preserve
keep if age=="45" | age=="50" 
collapse (sum) pop, by(iso3 year sex)
gen age_group="45"
tempfile 45_54
save `45_54', replace
restore

preserve
keep if age=="55" | age=="60" 
collapse (sum) pop, by(iso3 year sex)
gen age_group="55"
tempfile 55_64
save `55_64', replace
restore

preserve
keep if age=="65" | age=="70" | age=="75" | age=="80" 
collapse (sum) pop, by(iso3 year sex)
gen age_group="65"

append using `15_24' `25_30' `35_40' `45_50' `55_64'
replace sex = "1" if sex=="male"
replace sex = "2" if sex=="female"
destring(sex), replace
destring(age_group), replace

save "C:\Users\asthak\Documents\Covariates\Water and Sanitation\smoothing\spacetime input\pop_data.dta", replace