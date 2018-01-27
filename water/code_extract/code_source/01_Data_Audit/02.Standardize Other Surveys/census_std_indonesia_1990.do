// File Name: census_std_indonesia_1990.do

// File Purpose: Create standardized dataset with desired variables from Indonesia 1990 Census
// Author: Leslie Mallinger
// Date: 7/21/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder_census "J:\DATA\IDN\CENSUS"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"
local dat_folder_specific "1990"




** water, sanitation dataset
	use "`dat_folder_census'/`dat_folder_specific'/IDN_CENSUS_1990_1.DTA", clear
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


** apply labels
label variable b4p11 "source of drinking water"
label variable b4p12 "source of water for bathing/washing"
destring b4p11 b4p12, replace
replace b4p11 = . if b4p11 == 0
replace b4p12 = . if b4p12 == 8
label define wsource 1 "pipe" 2 "well pump" 3 "well" 4 "spring" 5 "river" 6 "rainwater" 7 "other" 9 "unknown"
label values b4p11 b4p12 wsource

label variable b4p14 "type of toilet"
destring b4p14, replace
label define ttype 1 "private with septic tank" 2 "private without septic tank" 3 "share toilet" ///
	4 "public toilet" 5 "other" 9 "unknown"
label values b4p14 ttype

label variable inf_rmt "weight"
destring inf_rmt, replace

label variable b1p5 "urban/rural"
destring b1p5, replace
replace b1p5 = . if b1p5 == 0
label define urb 1 "urban" 2 "rural"
label values b1p5 urb

label variable b1p1 "province"
destring b1p1, replace


** save
cd "`dat_folder_other_merged'"
save "census_indonesia_1990", replace


capture log close