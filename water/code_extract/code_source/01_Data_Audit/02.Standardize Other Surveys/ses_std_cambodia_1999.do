// File Name: ses_std_cambodia_1999.do

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
local dat_folder "J:\DATA\KHM\SOCIO_ECONOMIC_SURVEY\1999"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** water, sanitation dataset
	use "`dat_folder'/KHM_CSES_1999_CORE_PAGE_9.DTA ", clear
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
label variable p9q12 "water source"
destring p9q12, replace
label define water 1 "Piped in dwelling" 2 "Public tap" 3 "Tubed/piped well or borehole" 4 "Protected dug well" ///
	5 "Unprotected dug well" 6 "Pond, river or stream" 7 "Rainwater" 8 "Tanker truck, vendor or otherwise bought" 9 "Other (Specify)"
label values p9q12 water

label variable p9q14 "toilet type"
destring p9q14, replace
label define toilet 1 "Connected to sewerage" 2 "Septic tank" 3 "Pit latrine" 4 "Other without septic tank" ///
	5 "Public toilet" 6 "None" 7 "Other (Specify)"
label values p9q14 toilet

label variable weig "weight"
label variable vil "psu"
label variable sec "urban/rural"


** save
cd "`dat_folder_other_merged'"
save "ses_cambodia_1999", replace


capture log close