// File Name: lsms_std_south africa_1993.do

// File Purpose: Create standardized dataset with desired variables from LSMS South Africa survey
// Author: Leslie Mallinger
// Date: 6/10/2010
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
local dat_folder_country "ZAF/1993"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ZAF_LSMS_1993_HH_WATER.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hhid
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ZAF_LSMS_1993_MISC_BASIC_CROSS_VARIABLES.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** hhid
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/za94cdta/STRATA2", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
use `hhweight', clear
merge 1:m hhid using `hhserv'
drop if _merge != 3
drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
replace wsource_ = . if wsource_ == -1
replace toilet_c = . if toilet_c == -1

label define wsource 1 "piped - internal" 2 "piped - yard tap" 3 "water carrier/tanker" /// 
	4 "piped - public tap/kiosk (free)" 5 "piped - public tap/kiosk (paid for)" 6 "borehole" ///
	7 "rainwater tank" 8 "flowing river/stream" 9 "dam/stagnant water" 10 "well (non-borehole)" ///
	11 "protected spring" 12 "other (specify)"
label values wsource_ wsource

label define ttype 1 "flish toilet" 2 "improved pit latrine - with ventilation (VIP)" ///
	3 "other pit latrine" 4 "bucket toilet" 5 "chemical toilet" 6 "none"
label values toilet_c ttype


** save
cd "`dat_folder_lsms_merged'"
save "south africa_1993", replace
