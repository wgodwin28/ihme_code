// File Name: ses_std_cambodia_2003.do

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
local dat_folder "J:\DATA\KHM\SOCIO_ECONOMIC_SURVEY\2003_2005"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** water, sanitation dataset
	use "`dat_folder'/KHM_CSES_2003_2005_HH_HOUSING_ECON_ACTIVITY.DTA", clear
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



** save
cd "`dat_folder_other_merged'"
save "ses_cambodia_2003", replace


capture log close