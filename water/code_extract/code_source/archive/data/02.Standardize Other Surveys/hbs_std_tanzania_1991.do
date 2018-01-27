// File Name: hbs_std_tanzania_1991.do

// File Purpose: Create standardized dataset with desired variables from Household Budget Survey Tanzania 1991
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
local dat_folder "J:\DATA\TZA\HH_BUDGET_SURVEY\1991_1992"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/TZA_HBS_1991_1992_SERVICES_FACILTIES_HH_1CONV_Y2010M12D06.DTA", clear
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


** ** apply labels
** gen toilet = .
** replace toilet = 1 if p01d09 == 1 & p01d11 == 1	// toilet with a water connection
** replace toilet = 2 if p01d09 == 1 & p01d11 == 2	// toilet, pour water bucket
** replace toilet = 3 if p01d09 == 1 & p01d11 == 3	// toilet, no water
** replace toilet = 4 if p01d09 == 2	// no toilet
** label define ttype 1 "toilet with a water connection" 2 "toilet, pour water bucket" 3 "toilet, no water" ///
	** 4 "no toilet"
** label values toilet ttype

** replace upm = "30905" if upm == "3090-5"
** destring upm, replace


** save
cd "`dat_folder_other_merged'"
save "hbs_tanzania_1991", replace


capture log close