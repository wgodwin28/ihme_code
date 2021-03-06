// File Name: eih_std_bolivia_1992.do

// File Purpose: Create standardized dataset with desired variables from 1992 Bolivia Integrated Household Survey (EIH)
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
local dat_folder "J:\DATA\BOL\INTEGRATED_HH_SURVEY_EIH\1992"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/BOL_INTEGRATED_HH_SURVEY_EIH_1992_EIH5_INC_HOUSING_Y2011M03D21.DTA", clear
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
gen toilet = H140
replace toilet = 4 if toilet == .
label define toilet 1 "Alcantarillado" 2 "Camara Septica" 3 "Other" 4 "No toilet"
label values toilet toilet

label variable H903 "ponderador (weight)"


** save
cd "`dat_folder_other_merged'"
save "eih_bolivia_1992", replace


capture log close