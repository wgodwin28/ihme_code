// File Name: eih_std_bolivia_1993.do

// File Purpose: Create standardized dataset with desired variables from 1993 Bolivia Integrated Household Survey (EIH)
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
local dat_folder "J:\DATA\KHM\SOCIO_ECONOMIC_SURVEY\1996"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** water, sanitation dataset
	use "`dat_folder'/KHM_CSES_1996_PAGE_16_17A.DTA ", clear
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
label variable q19 "water source"
destring q19, replace
label define water 1 "piped in dwelling" 2 "public tap" 3 "tubed/piped well or borehole" 4 "protected dug well"	///
	5 "unprotected dug well" 6 "pond, river, or stream" 7 "rainwater" 8 "tanker truck, vendor, or otherwise bought"	///
	9 "bottled water" 10 "other"
label values q19 water

label variable q20 "toilet type"
destring q20, replace
label define toilet 1 "own flush toilet" 2 "shared flush toilet" 3 "closed latrine" 4 "open latrine" 5 "other" 6 "none"
label values q20 toilet

label variable village "psu"


** save
cd "`dat_folder_other_merged'"
save "ses_cambodia_1996", replace


capture log close