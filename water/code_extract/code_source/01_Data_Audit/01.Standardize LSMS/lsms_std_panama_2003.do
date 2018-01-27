// File Name: lsms_std_panama_2003.do

// File Purpose: Create standardized dataset with desired variables from LSMS Panama 2003 survey
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
local dat_folder_lsms "${j}/DATA/WB_LSMS/"
local dat_folder_lsms_merged "${data_folder}/LSMS/Merged Original Files"
local codes_folder "${j}/Usable/Common Indicators/Country Codes"
local dat_folder_country "PAN/2003"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/PAN_LSMS_2003_HH_LIVING_CONDITIONS.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** form
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/PAN_LSMS_2003_HH.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** form
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/Round 1, Module 0_4/r1m0.dta", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** merge
use `hhweight', clear
merge 1:m form using `hhserv'
keep if _merge == 3
drop _merge
** merge 1:1 hhid using `hhpsu'
** keep if _merge == 3
** drop _merge


** apply labels



** save
cd "`dat_folder_lsms_merged'"
save "panama_2003", replace

