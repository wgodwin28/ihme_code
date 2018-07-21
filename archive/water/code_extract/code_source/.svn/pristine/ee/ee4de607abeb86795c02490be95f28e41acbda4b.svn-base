// File Name: extract_files_ais.do

// File Purpose: Extract appropriate survey datasets from AIS surveys
// Author: Leslie Mallinger
// Date: 6/16/10
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_ais "J:/DATA/MACRO_AIS"
local dat_folder_new_ais "${data_folder}/AIS"
local codes_folder "J:/Usable/Common Indicators/Country Codes"

cap mkdir "`dat_folder_new_ais'"


** extract survey file paths into mata, then put them into Stata
	// initialize mata vector
	local maxobs 1000
	mata: filepath_full = J(`maxobs', 1, "")
	mata: filedir = J(`maxobs', 1, "")
	mata: filename = J(`maxobs', 1, "")
	local obsnum = 1

	// loop through directories and extract files and file paths
	local iso_list: dir "`dat_folder_ais'" dirs "*", respectcase
	foreach i of local iso_list {
		local year_list: dir "`dat_folder_ais'/`i'" dirs "*", respectcase
		foreach y of local year_list {
			// extract HH surveys
			local filenames: dir "`dat_folder_ais'/`i'/`y'" files "*HH*", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_ais'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_ais'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
		}
	}
	
	getmata filepath_full filedir filename
	drop if filepath_full == ""
	
	
** parse each part of the filename into informative variables
	local fileregex "^([a-zA-Z]+)[_]+([a-zA-Z]*)[_]*([A][I][S])([0-9]*)[_]+([a-zA-Z]*)[_]*([0-9]+)[_]*([0-9]*)[_]+([a-zA-Z]+)"

	// iso code
	gen iso3 = regexs(1) if regexm(filename, "`fileregex'")
	
	// survey type (special)
	gen svytype_sp = regexs(2) if regexm(filename, "`fileregex'")
	
	// survey
	gen svy = regexs(3) if regexm(filename, "`fileregex'")	
	
	// survey version
	gen svyver_real = regexs(4) if regexm(filename, "`fileregex'")
	
	// region
	gen region = regexs(5) if regexm(filename, "`fileregex'")
	
	// years
	gen startyear = regexs(6) if regexm(filename, "`fileregex'")
	gen endyear = regexs(7) if regexm(filename, "`fileregex'")
	replace endyear = startyear if endyear == ""
	
	// module
	gen module = regexs(8) if regexm(filename, "`fileregex'")
	
	// version
	gen version = regexs(0) if regexm(filename, "([Y][0-9]+[M][0-9]+[D][0-9]+)")
	
	
** match ISO codes with country names, determine whether IHME country
	// prepare countrycodes database
	preserve
	use "`codes_folder'/countrycodes_official.dta", clear
	keep if countryname == countryname_ihme & iso3 != ""
	tempfile countrycodes
	save `countrycodes', replace
	restore

	// merge together
	merge m:1 iso3 using `countrycodes', keepusing(countryname ihme_country) keep(1 3) nogen
	
	
** organize and save
order countryname iso3 ihme_country startyear endyear, first
sort countryname startyear

cd "`dat_folder_new_ais'"
save "datfiles_ais", replace
