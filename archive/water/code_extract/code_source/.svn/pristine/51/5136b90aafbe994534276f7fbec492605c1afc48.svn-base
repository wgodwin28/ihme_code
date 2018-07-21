// File Name: slms_std_pakistan_2004.do

// File Purpose: Create standardized dataset with desired variables
// Author: Leslie Mallinger
// Date: 7/14/2011
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder "J:\DATA\PAK\SOCIAL_AND_LIVING_MEASUREMENT_SURVEY\2004_2005"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** water, sanitation dataset
	use "`dat_folder'/PAK_PSLM_HIES_2004_2005_SEC_G0.DTA", clear
	tostring hhcode, replace
	gen psu = substr(hhcode, 1, 8)
	destring hhcode, replace
	destring psu, replace
	tempfile hhserv
	save `hhserv', replace
		** hhcode
	
** household weights dataset
	use "`dat_folder'/PAK_PSLM_HIES_2004_2005_WEIGHT.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** hhcode
		
** ** psu, urban/rural dataset
	** use "`dat_folder'/PAK_PSLM_HIES_2004_2005_SEC_A0.DTA ", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** merge
use `hhserv', clear
merge m:1 psu using `hhweight'
drop if _merge != 3
drop _merge


** ** apply labels



** save
cd "`dat_folder_other_merged'"
save "slms_pakistan_2004", replace


capture log close