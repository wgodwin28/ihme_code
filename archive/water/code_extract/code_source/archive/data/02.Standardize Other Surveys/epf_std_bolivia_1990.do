// File Name: census_std_bhutan_2005.do

// File Purpose: Create standardized dataset with desired variables from 2005 Bhutan Census
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
local dat_folder "J:\DATA\BOL\HH_BUDGET_SURVEY_EPF\1990\"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/BOL_HH_BUDGET_SURVEY_EPF_1990_HOUSING_ASSETS_EMP_BOLPF11_Y2010M10D20.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hhid
	
** ** household weights dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/za94cdta/STRATA2", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** hhid
		
** ** psu, urban/rural dataset
	** use "`dat_folder'/TZA_HBS_2000_2001_WGHTS_Y2010M10D06.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** ** merge
** use `hhpsu', clear
** merge 1:m hhid using `hhserv'
** drop if _merge != 3
** drop _merge


** ** apply labels
label variable PF1A13 "Factor de Expansion (household weight)"
label variable PF1A07 "upm (psu)"


** save
cd "`dat_folder_other_merged'"
save "epf_bolivia_1990", replace


capture log close