// File Name: slms_std_pakistan_2005.do

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
local dat_folder "J:\DATA\PAK\SOCIAL_AND_LIVING_MEASUREMENT_SURVEY\2005_2006"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** water, sanitation dataset
	use "`dat_folder'/PAK_PSLM_HIES_2005_2006_SEC_5.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hhcode
	
** household weights dataset
	use "`dat_folder'/PAK_PSLM_HIES_2005_2006_ROSTER_WITH WEIGHTS.DTA", clear
	keep hhcode psu weight
	duplicates drop
	tempfile hhweight
	save `hhweight', replace
		** hhcode
		
** ** psu, urban/rural dataset
	** use "`dat_folder'/KHM_CSES_2006_2007_AREA_INFORMATION.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** merge
use `hhweight', clear
merge 1:m hhcode using `hhserv'
drop if _merge != 3
drop _merge


** ** apply labels



** save
cd "`dat_folder_other_merged'"
save "slms_pakistan_2005", replace


capture log close