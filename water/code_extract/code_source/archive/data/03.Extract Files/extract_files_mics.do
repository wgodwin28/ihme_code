// File Name: extract_files_mics.do

// File Purpose: Extract appropriate survey datasets from MICS surveys
// Author: Leslie Mallinger
// Date: 3/12/10
// Edited on: 1/3/2011 (updated to reflect new file paths - no longer split into MICS2 and MICS3)

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_mics "J:/DATA/UNICEF_MICS"
local dat_folder_new_mics "${data_folder}/MICS"
local codes_folder "J:/Usable/Common Indicators/Country Codes"

cap mkdir "`dat_folder_new_mics'"


** extract survey file paths into mata, then put them into Stata
	// initialize mata vector
	local maxobs 1000
	mata: filepath_full = J(`maxobs', 1, "")
	mata: filedir = J(`maxobs', 1, "")
	mata: filename = J(`maxobs', 1, "")
	local obsnum = 1

	// loop through directories and extract files and file paths
	local iso_list: dir "`dat_folder_mics'" dirs "*", respectcase
	foreach i of local iso_list {
		local year_list: dir "`dat_folder_mics'/`i'" dirs "*", respectcase
		foreach y of local year_list {
			// extract HH surveys with upper-case DTA
			local filenames: dir "`dat_folder_mics'/`i'/`y'" files "*HH*DTA", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_mics'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_mics'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
			
			// extract HH surveys with lower-case DTA
			local filenames: dir "`dat_folder_mics'/`i'/`y'" files "*HH*dta", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_mics'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_mics'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
		}
	}
	
	getmata filepath_full filedir filename
	drop if filepath_full == ""
	
	
** parse each part of the filename into informative variables (date ranges with a dash)
	local fileregex "^([a-zA-Z]+)[_]+([a-zA-Z]+)([0-9])[_]+([0-9]+)[_]*([0-9]*)[_]+([a-zA-Z]+)"

	// iso3
	gen iso3 = regexs(1) if regexm(filename, "`fileregex'")
	
	// survey
	gen svy = regexs(2) if regexm(filename, "`fileregex'")
	
	// survey version
	gen svyver = regexs(3) if regexm(filename, "`fileregex'")
	
	// years
	gen startyear = regexs(4) if regexm(filename, "`fileregex'")
	gen endyear = regexs(5) if regexm(filename, "`fileregex'")
	replace endyear = startyear if endyear == ""
	
	// module
	gen module = regexs(6) if regexm(filename, "`fileregex'")
	
	// survey type
	gen svytype = "INT"


** reduce to surveys that aren't subnational
drop if iso3 == ""
	
	
** match ISO codes with country names, determine whether IHME country
	// prepare countrycodes database
	preserve
	use "`codes_folder'/countrycodes_official.dta", clear
	keep if countryname == countryname_ihme
	drop if iso3 == ""
	tempfile countrycodes
	save `countrycodes', replace
	restore

	// merge together
	merge m:1 iso3 using `countrycodes', keepusing(countryname ihme_country)
	drop if _merge == 2
	drop _merge
	
	
** organize
order countryname iso3 ihme_country startyear endyear, first
sort countryname startyear module
	
	
** reduce to only either HH or HHM for each countryyear (prefer HH)
	// tag and number entries that are duplicates by start/end year and country
	duplicates tag iso3 startyear endyear svytype svy, generate(countryyeardup)
	bysort iso3 startyear endyear svytype svy (module): egen num = seq()
	
	// remove entries where the HHM module is the second entry for the country-year
	drop if num == 2 & module == "HHM"
	drop countryyeardup num
	
	
** organize and save
order countryname iso3 ihme_country startyear endyear, first
sort countryname startyear

cd "`dat_folder_new_mics'"
save "datfiles_mics", replace


capture log close