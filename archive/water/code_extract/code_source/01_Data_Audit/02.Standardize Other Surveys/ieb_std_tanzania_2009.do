// File Name: hbs_std_tanzania_2007.do

// File Purpose: Create standardized dataset with desired variables from Household Budget Survey Tanzania 2007
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
local dat_folder "J:\DATA\TZA\IMPACT_EVALUATION\2009"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/TZA_PEMBA_IMPACT_EVALUATION_2009_HH_DATA_Y2011M07D11.DTA", clear
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
** label variable hh_wt "household weight"

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
save "ieb_tanzania_2009", replace


capture log close