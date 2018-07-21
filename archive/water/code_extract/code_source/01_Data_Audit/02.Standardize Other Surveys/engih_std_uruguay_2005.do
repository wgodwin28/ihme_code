// File Name: engih_std_uruguay_2005.do

// File Purpose: Create standardized dataset with desired variables from 2005 National Household Income and Expenditure Survey (ENGIH) in Uruguay
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
local dat_folder "J:\DATA\URY\NATIONAL_HH_INCOME_AND_EXPENDITURE_SURVEY_ENGIH\2005_2006\"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/URY_NATIONAL_HH_INCOME_AND_EXPENDITURE_SURVEY_ENGIH_2005_2006_HOUSING_VIVIENDA_Y2010M10D01.DTA ", clear
	tempfile hhserv
	save `hhserv', replace
		** dpto loc est mes sem viv
		
	use "`dat_folder'/URY_NATIONAL_HH_INCOME_AND_EXPENDITURE_SURVEY_ENGIH_2005_2006_HH_ASSETS_FACILITIES_HOGAR_Y2010M10D01.DTA", clear
	duplicates drop dpto loc est mes sem viv C121, force
	duplicates tag dpto loc est mes sem viv, gen(tag)
	drop if tag != 0
	drop tag
	tempfile hhserv2
	save `hhserv2', replace
	
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
	

** merge
use `hhserv', clear
merge 1:1 dpto loc est mes sem viv using `hhserv2'
drop if _merge != 3
drop _merge


** ** apply labels
label variable B81 "source of drinking water"
label define water 1 "general network" 2 "surging well (drilled and cased)" 3 "cistern/tank" 4 "stream/river" 5 "other"
label values B81 water

label variable C121 "toilet type"
label define toilet_type 1 "flush" 2 "no flush" 3 "no toilet"
label values C121 toilet_type

label variable facexp "household weight"
label variable est "psu"



** save
cd "`dat_folder_other_merged'"
save "engih_uruguay_2005", replace


capture log close