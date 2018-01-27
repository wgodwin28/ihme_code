// File Name: lsms_std_bosnia herzegovina_2001.do

// File Purpose: Create standardized dataset with desired variables from LSMS Bosnia and Herzegovina 2001 survey
// Author: Leslie Mallinger
// Date: 7/8/2010
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
local dat_folder_country "BIH/2001"



** water dataset
	use "`dat_folder_lsms'/`dat_folder_country'/BIH_LSMS_2001_DWELLING.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** muncode gnd hid numist
		
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/BIH_LSMS_2001_POVERTY_ANNEX.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** psu
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/identification_cl", clear
	** rename m0_q00 psu
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** psu
	

** merge
use `hhweight', clear
merge 1:m muncode gnd hid numist using `hhserv'
keep if _merge == 3
drop _merge
** merge 1:1 hhid using `hhpsu'
** keep if _merge == 3
** drop _merge


** apply labels
label define urban 1 "urban" 2 "rural" 3 "mixed"
label values mun_type urban


** save
cd "`dat_folder_lsms_merged'"
save "bosnia herzegovina_2001", replace
