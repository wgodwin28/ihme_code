// File Name: lsms_std_tajikistan_2009.do

// File Purpose: Create standardized dataset with desired variables from LSMS Tajikistan 2009 survey
// Author: Leslie Mallinger
// Date: 7/1/2010
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
local dat_folder_country "TJK/2009"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/TJK_LSMS_2009_M6B_Y2011M03D17", clear
	tempfile hhserv
	save `hhserv', replace
		** HHID
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/TJK_LSMS_2009_WEIGHTS2009_Y2011M03D17", clear
	tempfile hhweight
	save `hhweight', replace
		** HHID
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/Round 1, Module 0_4/r1m0.dta", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** merge
use `hhweight', clear
merge 1:m HHID using `hhserv'
keep if _merge == 3
drop _merge
** merge 1:1 hhid using `hhpsu'
** keep if _merge == 3
** drop _merge


** apply labels



** save
cd "`dat_folder_lsms_merged'"
save "tajikistan_2009", replace

