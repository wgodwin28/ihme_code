// File Name: extract_files_dhs.do

// File Purpose: Extract appropriate survey datasets from DHS surveys
// Author: Leslie Mallinger
// Date: 3/2/10
// Edited on: 12/22/2010 (updated file paths to reflect changes to J:/DATA)

// Additional Comments: 


clear all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_dhs "J:/DATA/MACRO_DHS"
local dat_folder_new_dhs "${data_folder}/DHS"
local codes_folder "J:/Usable/Common Indicators/Country Codes"

cap mkdir "`dat_folder_new_dhs'"


** extract survey file paths into mata, then put them into Stata
	// initialize mata vector
	local maxobs 2000
	mata: filepath_full = J(`maxobs', 1, "")
	mata: filedir = J(`maxobs', 1, "")
	mata: filename = J(`maxobs', 1, "")
	local obsnum = 1

	// loop through directories and extract files and file paths
	local iso_list: dir "`dat_folder_dhs'" dirs "*", respectcase
	foreach i of local iso_list {
		local year_list: dir "`dat_folder_dhs'/`i'" dirs "*", respectcase
		foreach y of local year_list {
			// extract HH surveys
			local filenames: dir "`dat_folder_dhs'/`i'/`y'" files "*HH*DTA", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_dhs'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_dhs'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
			
			// extract WN surveys
			local filenames: dir "`dat_folder_dhs'/`i'/`y'" files "*WN*DTA", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_dhs'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_dhs'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
		}
	}
	
	getmata filepath_full filedir filename
	drop if filepath_full == "" | regexm(filedir, "J:/DATA/MACRO_DHS/CRUDE")
	
	
** parse each part of the filename into informative variables
	local fileregex "^([a-zA-Z]+)[_]+([a-zA-Z]*)[_]*([D][H][S])([0-9]*)[_]+([a-zA-Z]*)[_]*([0-9]+)[_]*([0-9]*)[_]+([a-zA-Z]+)"

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

** designate DHS type (survey version)
	// make startyear a numeric variable
	destring startyear, replace

	gen svyver = .
	// Phase 5 (2003-present)
	replace svyver = 5 if startyear >= 2002
	// Phase 4 (1997-2003)
	replace svyver = 4 if startyear >= 1997 & svyver == .
	// Phase 3 (1992-1997)
	replace svyver = 3 if startyear >= 1992 & svyver == .
	// Phase 2 (1988-1993)
	replace svyver = 2 if startyear >= 1988 & svyver == .
	// Phase 1 (1984-1989)
	replace svyver = 1 if startyear >= 1984 & svyver == .
	
	// make svyver a string variable like in all the other surveys
	tostring svyver, replace
	
** get rid of surveys from provinces in India
drop if region != "" & regexm(filename, "IND")

** remove HHM surveys where we already have HH or WN
duplicates tag iso3 startyear, gen(tag)
drop if module == "HHM" & tag > 0
drop tag
	
** reduce WN surveys to those where the HH survey doesn't exist or doesn't have the necessary information
	// mark surveys that have multiple modules remaining
	duplicates tag iso3 startyear, gen(tag)

	// mark surveys with the given iso3 and startyear
	gen tag2 = 0
	replace tag2 = 1 if (iso3 == "BDI" & startyear == 1987) | ///
		(iso3 == "DOM" & startyear == 1986) | ///
		(iso3 == "IDN" & startyear == 1987) | ///
		(iso3 == "LBR" & startyear == 1986) | ///
		(iso3 == "MLI" & startyear == 1987) | ///
		(iso3 == "MAR" & startyear == 1987) | ///
		(iso3 == "PER" & startyear == 1986) | ///
		(iso3 == "SEN" & startyear == 1986) | ///
		(iso3 == "LKA" & startyear == 1987) | ///
		(iso3 == "THA" & startyear == 1987) | ///
		(iso3 == "TTO" & startyear == 1987) | ///
		(iso3 == "GHA" & startyear == 1988) | ///
		(iso3 == "KEN" & startyear == 1988) | ///
		(iso3 == "SDN" & startyear == 1989) | ///
		(iso3 == "TGO" & startyear == 1988) | ///
		(iso3 == "TUN" & startyear == 1988) | ///
		(iso3 == "UGA" & startyear == 1988) | ///
		(iso3 == "ZWE" & startyear == 1988)
		
	// remove WN surveys if they aren't useful
	drop if module == "WN" & tag > 0 & tag2 == 0
	
	// remove HH surveys if they aren't useful
	drop if module == "HH" & tag > 0 & tag2 == 1
	drop tag
	
	// remove remaining duplicates by hand
	duplicates tag iso3 startyear, gen(tag)
	drop if iso3 == "GHA" & startyear == 2007 &! regexm(filename, "PH2")
	drop if iso3 == "DOM" & startyear == 2007 & svytype_sp == "SP"
	drop tag
	
	
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
compress
	
	
** reduce to only either HH or HHM for each countryyear (prefer HH)
	// tag and number entries that are duplicates by start/end year and country
	duplicates tag iso3 startyear endyear svytype svytype_sp svy, generate(countryyeardup)
	bysort iso3 startyear endyear svytype svytype_sp svy (module): egen num = seq()
	
	// remove entries where the HHM module is the second entry for the country-year
	drop if num == 2 & module == "HHM"
	drop countryyeardup num
	drop if iso3 == "IDN" & startyear == 2002 & svytype_sp == "SP"
	drop if iso3 == "AFG" & startyear == 2010 & regexm(filename, "DEATHS")

	
	
** organize and save
order countryname iso3 ihme_country startyear endyear, first
sort countryname startyear
destring svyver_real, replace

cd "`dat_folder_new_dhs'"
save "datfiles_dhs", replace


capture log close