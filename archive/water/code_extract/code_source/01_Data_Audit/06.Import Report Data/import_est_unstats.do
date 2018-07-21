// File Name: import_est_unstats.do

// File Purpose: Import coverage estimates from UN Stats MDG Indicator database
// Author: Leslie Mallinger
// Date: 5/6/10
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local dat_folder_unstats "${data_folder}/UN Stats"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** open WHOSIS database, remove blank observations
insheet using "`dat_folder_unstats'/UN_Stats_MDG_Indicator_Data.csv", clear names
rename country countryname
drop if countryname == ""
rename v6 mean1990
rename v9 mean1995
rename v12 mean2000
rename v15 mean2006
rename series type
replace type = "iwater" if seriescode == 665
replace type = "isanitation" if seriescode == 668


** keep only variables of interest, then generate values for other important variables
keep countryname type mean*
reshape long mean, i(countryname type) j(startyear)
reshape wide mean, i(countryname startyear) j(type) string
rename meanisanitation isanitation_mean
rename meaniwater iwater_mean
drop if iwater_mean == "" & isanitation_mean == ""

gen endyear = startyear
tostring endyear, replace
gen dattype = "REPORT"
gen svy = "UNSTATS"


** convert prevalence estimates to percentages
destring(iwater_mean isanitation_mean), replace
replace iwater_mean = iwater_mean/100
replace isanitation_mean = isanitation_mean/100
	
	
** match country names with iso codes, determine whether IHME country
merge m:1 countryname using "`codes_folder'/countrycodes_official.dta", keepusing(countryname countryname_ihme iso3 ihme_country)
drop if _merge == 2
drop if ihme_country == 0
drop countryname _merge
rename countryname_ihme countryname

	
** organize and save
order countryname iso3 ihme_country startyear endyear dattype svy, first
sort countryname startyear

cd "`dat_folder_unstats'"
save "prev_unstats", replace


capture log close