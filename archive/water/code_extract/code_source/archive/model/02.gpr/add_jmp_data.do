// File Purpose: Add JMP estimates to GPR output
// Author: Leslie Mallinger
// Date: 8/16/2012
// Edited on: 



clear all
macro drop _all
set mem 500m
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
if ("`c(os)'" == "Windows") local prefix "J:"
else local prefix "/home/j"

local jmp_data "`prefix'/Project/COMIND/Water and Sanitation/Data Audit/jmp_estimates_Y2012M08D15.csv"
local gpr_folder "`prefix'/Project/COMIND/Water and Sanitation/Smoothing/GPR Results"
local codes "`prefix'/DATA/IHME_COUNTRY_CODES/IHME_COUNTRYCODES.DTA"


** prep country codes
use "`codes'", clear
keep if iso3 != "" & countryname == countryname_ihme & ihme_country == 1 & gbd_developing == 1
tempfile isos
save `isos', replace


** prep JMP data
insheet using "`jmp_data'", comma clear
drop in 1/4
drop v4 v6 v7
rename v1 countryname
rename v2 year
rename v3 jmp_water
rename v5 jmp_sanitation
carryforward countryname, replace
destring jmp_water jmp_sanitation year, replace
replace jmp_water = jmp_water/100
replace jmp_sanitation = jmp_sanitation/100
merge m:1 countryname using "`codes'", keep(3) keepusing(iso3) nogen
drop countryname
order iso3 year
sort iso3 year
drop if iso3 == ""
tempfile jmp
save `jmp', replace


** calculate JMP MDG progress
keep if year == 1990 | year == 2010
reshape wide jmp*, i(iso3) j(year)
egen test = rowtotal(jmp*)
drop if test == 0
drop test
merge 1:1 iso3 using `isos', keep(3) nogen keepusing(iso3)
foreach i in jmp_water jmp_sanitation {
	gen `i'_change = `i'2010 - `i'1990
	gen no_`i'_1990 = 1 - `i'1990
	gen no_`i'_2010 = 1 - `i'2010
	gen `i'_rate = -100*ln(no_`i'_2010/no_`i'_1990)/(2010-1990)
	gen `i'_goal = 1 - ((no_`i'_1990)/2)
}
gen goal_rate = -100*ln(1/2)/(2015-1990)
count if jmp_water_rate > goal_rate & jmp_water_rate != .
count if jmp_water_rate != .
count if jmp_sanitation_rate > goal_rate & jmp_sanitation_rate != .
count if jmp_sanitation_rate != .


** open GPR data
foreach model in w_thesis s_thesis {
	use "`gpr_folder'/gpr_results_`model'_with_orig_data.dta", clear
	drop _merge
	merge m:1 iso3 year using `jmp', keep(1 3) nogen
	if regexm("`model'", "w") drop jmp_sanitation
	else if regexm("`model'", "s") drop jmp_water
	rename jmp jmp
	save "`gpr_folder'/gpr_results_`model'_with_orig_data_jmp.dta", replace
}


