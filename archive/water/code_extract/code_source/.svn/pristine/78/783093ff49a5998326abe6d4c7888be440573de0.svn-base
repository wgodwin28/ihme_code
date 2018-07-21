// File Name: extract_files_mis.do

// File Purpose: Extract appropriate survey datasets from MIS surveys
// Author: Leslie Mallinger
// Date: 6/16/10
// Edited on: 1/4/2011 (updated to reflect new file paths - no longer split into mis2 and mis3)

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_mis "J:/DATA/MACRO_MIS"
local dat_folder_new_mis "${data_folder}/MIS"
local codes_folder "J:/Usable/Common Indicators/Country Codes"

capture mkdir "`dat_folder_new_mis'"


** extract survey file paths into mata, then put them into Stata
	// initialize mata vector
	local maxobs 500
	mata: filepath_full = J(`maxobs', 1, "")
	mata: filedir = J(`maxobs', 1, "")
	mata: filename = J(`maxobs', 1, "")
	local obsnum = 1

	// loop through directories and extract files and file paths
	local iso_list: dir "`dat_folder_mis'" dirs "*", respectcase
	foreach i of local iso_list {
		local year_list: dir "`dat_folder_mis'/`i'" dirs "*", respectcase
		foreach y of local year_list {
			// extract HH surveys with upper-case DTA
			local filenames: dir "`dat_folder_mis'/`i'/`y'" files "*HH*DTA", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_mis'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_mis'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
			
			// extract HH surveys with lower-case DTA
			local filenames: dir "`dat_folder_mis'/`i'/`y'" files "*HH*dta", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_mis'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_mis'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
		}
	}
	
	getmata filepath_full filedir filename
	drop if filepath_full == ""
	
	
** parse each part of the filename into informative variables
	local fileregex "^([a-zA-Z]+)[_]+([a-zA-Z]+)([0-9]*)[_]+([0-9]+)[_]*([0-9]*)[_]+([a-zA-Z]+)"
	
	// iso code
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
sort countryname startyear


** reduce to only either HH or HHM for each countryyear (prefer HH)
	// tag and number entries that are duplicates by start/end year and country
	duplicates tag iso3 startyear endyear svy, generate(countryyeardup)
	bysort iso3 startyear endyear svy (module): egen num = seq()
	
	// remove entries where the HHM module is the second entry for the country-year
	drop if num == 2 & module == "HHM"
	drop countryyeardup num
	

** save
cd "`dat_folder_new_mis'"
save "datfiles_mis", replace


capture log close