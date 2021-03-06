// File Name: papfam_std_all_multiyear.do

// File Purpose: Create standardized dataset with desired variables from PAPFAM family surveys
// Author: Leslie Mallinger
// Date: 6/30/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder_papfam "J:/Project/PAPFAM/papfam from EMRO 062110"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder_papfam'/HH_papfam", clear
	tempfile hhserv
	save `hhserv', replace
		** hhid
	
** ** household weights dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/za94cdta/STRATA2", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** hhid
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/za94cdta/STRATA2", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
** use `hhweight', clear
** merge 1:m hhid using `hhserv'
** drop if _merge != 3
** drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** split into country-specific datasets
decode hid100, generate(countryname)
replace countryname = subinstr(countryname, " - papfam", "", .)

levelsof countryname, local(country)
foreach c of local country {
	preserve
	keep if countryname == "`c'"
	if "`c'" == "morocco" {
		local year 2003
	}
	else {
		levelsof hid107y, local(year)
	}
	cd "`dat_folder_other_merged'"
	save "papfam_`c'_`year'", replace	
	restore
}


capture log close