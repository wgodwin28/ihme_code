// File Name: lsms_std_timor leste_2001.do

// File Purpose: Create standardized dataset with desired variables from LSMS TLS 2001 survey
// Author: Leslie Mallinger
// Date: 5/20/2010
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
local dat_folder_country "TLS/2001"



** household weights dataset
use "`dat_folder_lsms'/`dat_folder_country'/TLS_LSMS_2001_WEIGHTS.DTA", clear
tempfile hhweight
save `hhweight', replace


** household services dataset
use "`dat_folder_lsms'/`dat_folder_country'/TLS_LSMS_2001_HH_HOUSING_SERVICES.DTA", clear


** merge
merge m:1 id4 using `hhweight'


** save
cd "`dat_folder_lsms_merged'"
save "timor leste_2001", replace

