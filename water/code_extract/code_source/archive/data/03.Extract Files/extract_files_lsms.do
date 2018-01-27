// File Name: extract_files_lsms.do

// File Purpose: Extract appropriate survey datasets from LSMS surveys
// Author: Leslie Mallinger
// Date: 5/26/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_new_lsms "${data_folder}/LSMS"
local dat_folder_lsms "${data_folder}/LSMS/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"

cap mkdir "`dat_folder_new_lsms'"
cap mkdir "`dat_folder_lsms'"


** create local with household survey filenames in RHS data folder (must contain the letters "HH"), then make 
** one observation per filename
	// designate locals with filenames
	local filenames: dir "`dat_folder_lsms'" files "*", respectcase

	// designate locals with the number of files
	local numfiles: list sizeof filenames
	
	// put each filename into its own observation
	local numobs = `numfiles'
	set obs `numobs'
	local obsnum = 1
	gen filename = ""
	
	foreach file of local filenames {
		replace filename = "`file'" if _n == `obsnum'
		local obsnum = `obsnum' + 1
	}
	
	
** parse each part of the filename into informative variables
	local fileregex "^([a-zA-Z]+)[_]+([a-zA-Z]+)[_]+([a-zA-Z]+)([0-9]+)[_]+([a-zA-Z]+)[-]*([a-zA-Z]*)[_]+([0-9]+)[-]*([0-9]*)[_]+([a-zA-Z]+)"

	// data type
	gen dattype = "CRUDE"
	
	// survey type
	gen svytype = "INT"
	
	// survey
	gen svy = "LSMS"
	
	// countryname
	gen countryname = regexs(0) if regexm(filename, "^([a-zA-Z]+[ ]*[a-zA-Z]+[ ]*[a-zA-Z]+)")
	replace countryname = proper(countryname)
	
	// years
	gen startyear = regexs(0) if regexm(filename, "([0-9][0-9][0-9][0-9])")
	gen endyear = startyear
	
	// filedir
	gen filedir = "`dat_folder_lsms'"
	
	// filepath_full
	gen filepath_full = filedir + "/" + filename
	
	
** match country names with iso3 codes, determine whether IHME country
replace countryname = "Cote d'Ivoire" if countryname == "Cote Divoire"
preserve
use "`codes_folder'/countrycodes_official.dta", clear
drop if countryname == "Burma" & countryname_ihme == "Burma"
tempfile codes
save `codes', replace
restore
merge m:1 countryname using `codes', keepusing(countryname_ihme iso3 ihme_country)
drop if _merge == 2
drop _merge countryname
rename countryname_ihme countryname


** add information about representativeness (from LSMS website)
gen subnational = 0
replace subnational = 1 if iso3 == "IND" & startyear == "1997"
	
	
** organize and save
order countryname iso3 ihme_country startyear endyear, first
sort countryname startyear

cd "`dat_folder_new_lsms'"
save "datfiles_lsms", replace


capture log close