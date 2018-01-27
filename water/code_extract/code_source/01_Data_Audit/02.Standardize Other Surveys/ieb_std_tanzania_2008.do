** // File Name: hbs_std_tanzania_2008.do

** // File Purpose: Create standardized dataset with desired variables from Impact Evaluation Baseline Tanzania 2008
** // Author: Leslie Mallinger
** // Date: 7/14/2011
** // Edited on: 

** // Additional Comments: 

************ CAN'T FIGURE OUT HOW TO GET HHID IN THE WEIGHT FILE ******************************


** clear all
** // macro drop _all
** set mem 500m
** set more off
** capture log close
** capture restore, not


** ** create locals for relevant files and folders
** local log_folder "${code_folder}/02.Standardize Other Surveys"
** local dat_folder "J:\DATA\WB_LSMS_ISA\TZA\2008_2009"
** local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
** local codes_folder "J:/Usable/Common Indicators/Country Codes"



** ** water, sanitation dataset
	** use "`dat_folder'/TZA_LSMS_ISA_2008_2009_HH_HOUSING_GOV_FOOD_ASSISTANCE_CRIME_Y2010M02D08.DTA", clear
	** tempfile hhserv
	** save `hhserv', replace
		** ** hhid
	
** ** household weights dataset
	** use "`dat_folder'/TZA_LSMS_ISA_2008_2009_HH_WEIGHTS_Y2010M02D08.DTA", clear
	
	** tostring region, replace
	** tostring district, replace
	** tostring ward, replace
	** tostring ea, replace
	** gen hhid = region + district + ward + ea
	
	** tempfile hhweight
	** save `hhweight', replace
		** ** hhid
		
** ** ** psu, urban/rural dataset
	** ** use "`dat_folder'/TZA_HBS_2000_2001_WGHTS_Y2010M10D06.DTA", clear
	** ** tempfile hhpsu
	** ** save `hhpsu', replace
		** ** ** hhid
	

** ** ** merge
** ** use `hhpsu', clear
** ** merge 1:m hhid using `hhserv'
** ** drop if _merge != 3
** ** drop _merge


** ** ** apply labels
** label variable sjq11 "source of drinking water"
** label variable sjq16 "toilet type"



** ** save
** cd "`dat_folder_other_merged'"
** save "ieb_tanzania_2009", replace


** capture log close