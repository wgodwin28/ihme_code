// File Name: cwiq_std_tanzania_2005.do

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
local dat_folder "J:\DATA\WB_CWIQ\TZA\2005\"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** water, sanitation dataset
	use "`dat_folder'/TZA_CWIQ_2005_HH_Y2011M06D20.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hhcode
	
** ** household weights dataset
	** use "`dat_folder'/ZMB_HH_HEALTH_COVERAGE_SURVEY_2008_HH_ID.DTA", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** hhcode
		
** ** psu, urban/rural dataset
	** use "`dat_folder'/PAK_PIH_HIES_1998_1999_ROSTER.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** ** merge
** use `hhserv', clear
** merge m:1 vhclust vhnumber using `hhweight'
** drop if _merge != 3
** drop _merge


** apply labels
label variable wt "weight"



** save
cd "`dat_folder_other_merged'"
save "cwiq_tanzania_2005", replace


capture log close