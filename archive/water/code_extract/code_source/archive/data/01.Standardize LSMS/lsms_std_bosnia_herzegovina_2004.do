// File Name: lsms_std_bosnia herzegovina_2004.do

// File Purpose: Create standardized dataset with desired variables from LSMS Bosnia and Herzegovina 2004 survey
// Author: Leslie Mallinger
// Date: 7/9/2010
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
local dat_folder_country "BIH/2004"



** water dataset
	use "`dat_folder_lsms'/`dat_folder_country'/BIH_LSMS_2004_WAVE4_HH_QUEST.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hid
		
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/BIH_LSMS_2004_WAVE4_IND_CONTROL_FORM.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** hid
		
** psu, urban/rural dataset
	use "`dat_folder_lsms'/`dat_folder_country'/BIH_LSMS_2004_WAVE4_CONTROL_FORM_ADDRESS_INFO.DTA", clear
	tempfile hhpsu
	save `hhpsu', replace
		** hid
	

** merge
use `hhweight', clear
merge m:1 hid using `hhserv'
keep if _merge == 3
drop _merge
merge m:1 hid using `hhpsu'
keep if _merge == 3
drop _merge


** apply labels
label variable d0f_q02 "psu?"



** save
cd "`dat_folder_lsms_merged'"
save "bosnia herzegovina_2004", replace
