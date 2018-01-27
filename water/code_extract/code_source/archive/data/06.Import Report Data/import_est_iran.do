// File Name: import_est_iran.do

// File Purpose: Import coverage estimates from Iran
// Author: Leslie Mallinger
// Date: 6/11/10
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_other "${data_folder}/Other"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** open database, rename variables for clarity
insheet using "`dat_folder_other'/Iran_estimates.csv", clear
rename year startyear
rename proportionofpopulationwithaccess iwater_mean
rename standarderror iwater_sem
rename v7 isanitation_mean
rename v8 isanitation_sem
rename nationallyrepresentativeyesno national
rename typeofsourcesurveyorreportorothe sourcetype


** keep only variables of interest, then generate values for other important variables
keep startyear iwater_mean iwater_sem isanitation_mean isanitation_sem national sourcetype
drop if startyear == .

gen countryname = "Iran"
gen endyear = startyear
tostring endyear, replace
gen dattype = "REPORT"
gen svytype = "OTHER"

gen svy = ""
replace svy = "ADMIN" if sourcetype == "report"
replace svy = "WHO" if sourcetype == "report(WHO)"
replace svy = "DHS" if sourcetype == "survey(DHS)"
replace svy = "MDG" if sourcetype == "survey(MDG)"
replace svy = "MICS" if sourcetype == "survey(MICS)"
drop sourcetype

gen subnational = (national != "yes")
drop national


** convert prevalence estimates to percentages
replace iwater_mean = subinstr(iwater_mean, "%", "", .)
replace iwater_sem = subinstr(iwater_sem, "%", "", .)
replace isanitation_mean = subinstr(isanitation_mean, "%", "", .)

destring iwater_mean iwater_sem isanitation_mean, replace

replace iwater_mean = iwater_mean/100
replace iwater_sem = iwater_sem/100
replace isanitation_mean = isanitation_mean/100
replace isanitation_sem = isanitation_sem/100
	
	
** match country names with iso codes, determine whether IHME country
preserve
	use "`codes_folder'/countrycodes_official", clear
	drop if countryname == "Burma" & countryname_ihme == "Burma"
	tempfile codes
	save `codes', replace
restore

merge m:1 countryname using `codes', keepusing(countryname countryname_ihme iso3 ihme_country)
drop if _merge == 2
drop if ihme_country == 0
drop countryname _merge
rename countryname_ihme countryname

	
** organize and save
order countryname iso3 ihme_country startyear endyear dattype svy svytype , first
sort countryname startyear

cd "`dat_folder_other'"
save "prev_iran", replace


capture log close