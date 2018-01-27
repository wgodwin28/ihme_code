// File Name: hbs_std_yemen_2005.do

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
local dat_folder "J:\DATA\YEM\HH_BUDGET_SURVEY\2005_2006"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/YEM_HBS_2005_2006_S00_HHOLD.DTA", clear
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
gen water = Q0305 if inlist(Q0305, 1, 2, 3)
replace water = 4 if Q0306 == 1	// well with pump
replace water = 5 if Q0306 == 2	// well without pump
replace water = 6 if Q0306 == 3	// stream/spring water
replace water = 7 if Q0306 == 4	// covered pond
replace water = 8 if Q0306 == 5	// open pond
replace water = 9 if Q0306 == 6	// backstop
replace water = 10 if Q0306 == 7	// traditional way for collecting water
replace water = 11 if Q0306 == 8	// other

label define water 1 "public network" 2 "cooperative network" 3 "private owned water source" ///
	4 "well with pump" 5 "well without pump" 6 "stream/spring water" 7 "covered pond" ///
	8 "open pond" 9 "backstop" 10 "traditional way for collecting water" 11 "other"
label values water water

label variable Stratum "psu"


** save
cd "`dat_folder_other_merged'"
save "hbs_yemen_2005", replace


capture log close