// File Name: import_est_mics1.do

// File Purpose: Import coverage estimates from MICS 1 Reports
// Author: Leslie Mallinger
// Date: 4/22/10
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local dat_folder_mics "${data_folder}/MICS"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** open WHOSIS database, rename variables for clarity
insheet using "`dat_folder_mics'/mics1_reports.csv", clear
rename country countryname
rename year startyear


** keep only variables of interest, then generate values for other important variables
keep countryname startyear iwater_mean isanitation_mean subnational
gen endyear = startyear
tostring endyear, replace
gen dattype = "REPORT"
gen svy = "MICS"
gen svyver = "1"


** convert prevalence estimates to percentages
replace iwater_mean = iwater_mean/100
replace isanitation_mean = isanitation_mean/100
	
	
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
order countryname iso3 ihme_country startyear endyear dattype svy svyver, first
sort countryname startyear

cd "`dat_folder_mics'"
save "prev_mics1", replace


capture log close