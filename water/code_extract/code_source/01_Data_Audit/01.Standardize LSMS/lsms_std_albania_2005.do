// File Name: lsms_std_albania_2005.do

// File Purpose: Create standardized dataset with desired variables from LSMS Albania 2005 survey
// Author: Leslie Mallinger
// Date: 7/7/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
if "`c(os)'" == "Windows" {
	global j "J:"
}
else {
	global j "/home/j"
	set odbcmgr unixodbc
}


** create locals for relevant files and folders
local dat_folder_lsms "${j}/DATA/WB_LSMS"
local dat_folder_lsms_merged "${data_folder}/LSMS/Merged Original Files"
local codes_folder "${j}/Usable/Common Indicators/Country Codes"
local dat_folder_country "ALB/2005"



** water dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ALB_LSMS_2005_DWELLING_UTILITIES.DTA", clear
	rename m0_q00 psu
	tempfile hhserv
	save `hhserv', replace
		** psu
		
** sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ALB_LSMS_2005_DWELLING.DTA", clear
	rename m0_q00 psu
	tempfile hhsan
	save `hhsan', replace
		** psu

** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ALB_LSMS_2005_PSU_WEIGHTS.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** psu
		
** psu, urban/rural dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ALB_LSMS_2005_IDENTIFICATION.DTA", clear
	rename m0_q00 psu
	tempfile hhpsu
	save `hhpsu', replace
		** psu
	

** merge
use `hhserv', clear
merge 1:1 hhid using `hhsan'
keep if _merge == 3
drop _merge
merge 1:1 hhid using `hhpsu'
keep if _merge == 3
drop _merge
tempfile hhserv_m
save `hhserv_m', replace

use `hhweight', clear
merge 1:m psu using `hhserv_m'
keep if _merge == 3
drop _merge
** merge 1:1 hhid using `hhpsu'
** keep if _merge == 3
** drop _merge


** apply labels
** M13B_Q01:
           ** 1 Running water inside the dwelling
           ** 2 Running water outside the dwelling
           ** 3 Public Tap
           ** 4 Water truck
           ** 5 Spring or well
           ** 6 River, lake, pond or similar
           ** 7 Other
** M13B_Q06:
           ** 1 Running water inside the dwelling
           ** 2 Running water outside the dwelling
           ** 3 Public tab
           ** 4 Water truck
           ** 5 Spring or well
           ** 6 River, lake, pond  or similar
           ** 7 Bottled water
           ** 8 Other


gen wsource = .
replace wsource = m13b_q01 if m13b_q05 == 1
replace wsource = 1 if m13b_q06 == 1	// running water inside the dwelling
replace wsource = 2 if m13b_q06 == 2	// running water outside the dwelling
replace wsource = 3 if m13b_q06 == 3	// public tap
replace wsource = 4 if m13b_q06 == 4	// water truck
replace wsource = 5 if m13b_q06 == 5	// spring or well
replace wsource = 6 if m13b_q06 == 6	// river, lake, pond, or similar
replace wsource = 7 if m13b_q06 == 8	// other
replace wsource = 8 if m13b_q06 == 7	// bottled water
label define wsource 1 "running water inside the dwelling" 2 "running water outside the dwelling" ///
	3 "public tap" 4 "water truck" 5 "spring or well" 6 "river, lake, pond or similar" 7 "other" ///
	8 "bottled water"
label values wsource wsource
label variable wsource "source of drinking water - complete"


** save
cd "`dat_folder_lsms_merged'"
save "albania_2005", replace

