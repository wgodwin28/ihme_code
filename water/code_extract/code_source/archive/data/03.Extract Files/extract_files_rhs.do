// File Name: extract_files_rhs.do

// File Purpose: Extract appropriate survey datasets from RHS surveys
// Author: Leslie Mallinger
// Date: 4/23/10 (modified from J:\Project\COMIND\Water and Sanitation\Data Audit\Code\extract_files_rhs2.do)
// Edited on: 1/4/2011 (updated to reflect new file paths)

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_rhs "J:/DATA/CDC_RHS"
local dat_folder_new_rhs "${data_folder}/RHS"
local codes_folder "J:/Usable/Common Indicators/Country Codes"

capture mkdir "`dat_folder_new_rhs'"


** extract survey file paths into mata, then put them into Stata
	// initialize mata vector
	local maxobs 1000
	mata: filepath_full = J(`maxobs', 1, "")
	mata: filedir = J(`maxobs', 1, "")
	mata: filename = J(`maxobs', 1, "")
	local obsnum = 1

	// loop through directories and extract files and file paths
	local iso_list: dir "`dat_folder_rhs'" dirs "*", respectcase
	foreach i of local iso_list {
		local year_list: dir "`dat_folder_rhs'/`i'" dirs "*", respectcase
		foreach y of local year_list {
			// extract HH surveys 
			local filenames: dir "`dat_folder_rhs'/`i'/`y'" files "*HH*", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_rhs'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_rhs'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
			
			// extract WN	surveys
			local filenames: dir "`dat_folder_rhs'/`i'/`y'" files "*WN*", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_rhs'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_rhs'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
		}
	}
	
	getmata filepath_full filedir filename
	drop if filepath_full == ""
	keep if regexm(filename, "DTA") | regexm(filename, "dta")
	drop if regexm(filename, "SIB")
	
	
** parse each part of the filename into informative variables
	local fileregex "^([a-zA-Z]+)[_]+([a-zA-Z]+)[_]+([0-9]+)[_]+([0-9]*)[_]*([a-zA-Z]+)[_]*([Y]*[0-9]*[M]*[0-9]*[D]*[0-9]*)"

	// iso code
	gen iso3 = regexs(1) if regexm(filename, "`fileregex'")
	
	// survey
	gen svy = regexs(2) if regexm(filename, "`fileregex'")
		
	// years
	gen startyear = regexs(3) if regexm(filename, "`fileregex'")
	gen endyear = regexs(4) if regexm(filename, "`fileregex'")
	replace endyear = startyear if endyear == ""
	
	// module
	gen module = regexs(5) if regexm(filename, "`fileregex'")
	
	// version
	gen version = regexs(6) if regexm(filename, "`fileregex'")
	
	
** match ISO codes with country names, determine whether IHME country
	// prepare countrycodes database
	preserve
	use "`codes_folder'/countrycodes_official.dta", clear
	keep if countryname == countryname_ihme
	drop if iso3 == ""
	tempfile countrycodes
	save `countrycodes', replace
	restore
	
	// fix ISO code for Guatemala
	replace iso3 = "GTM" if iso3 == "GMT"

	// merge together
	merge m:1 iso3 using `countrycodes', keepusing(countryname ihme_indic_country)
	drop if _merge == 2
	drop _merge
	drop if ihme_indic_country == 0
	
	
** organize
order countryname iso3 ihme_indic_country startyear endyear, first
sort countryname startyear module
compress


** reduce to only either HH or HHM for each countryyear (prefer HH)
	// tag and number entries that are duplicates by start/end year and country
	duplicates tag iso3 startyear endyear svy, generate(countryyeardup)
	bysort iso3 startyear endyear svy (module): egen num = seq()
	
	// remove entries where the HHM module is the second entry for the country-year
	drop if num == 2 & module == "HHM"
	drop countryyeardup num
	
	
** reduce to only one version of each dataset
	replace version = "Z" if version == ""
	duplicates tag iso3 startyear endyear svy module, generate(countryyeardup)
	bysort iso3 startyear endyear svy module (version): egen num = seq()
	drop if num > 1 & version == "Z"
	replace version = "" if version == "Z"
	drop countryyeardup num
	
	duplicates tag iso3 startyear endyear svy, generate(countryyeardup)
	tab countryyeardup
	drop if iso3 == "GEO" & startyear == "2005" & module == "WN"
	drop if iso3 == "SLV" & startyear == "1993" & version == "2"
	drop countryyeardup
	
	duplicates tag iso3 startyear endyear svy, generate(countryyeardup)
	tab countryyeardup
	
	
** TEMPORARILY
** drop if iso3 == "GTM" & startyear == "2008"


** save
cd "`dat_folder_new_rhs'"
save "datfiles_rhs", replace


capture log close