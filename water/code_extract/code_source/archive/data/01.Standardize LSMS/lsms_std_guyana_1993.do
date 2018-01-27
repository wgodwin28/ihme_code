// File Name: lsms_std_guyana_1993.do

// File Purpose: Create standardized dataset with desired variables from LSMS Guyana 1993 survey
// Author: Leslie Mallinger
// Date: 6/2/2010
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
local dat_folder_country "GUY/1992_1993"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/GUY_LSMS_1992_1993_HHCHAR", clear
	duplicates drop newid smpl_hh, force
	tempfile hhserv
	save `hhserv', replace
		** newid smpl_hh
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/GUY_LSMS_1992_1993_WEIGHTID", clear
	duplicates drop newid smpl_hh, force
	tempfile hhweight
	save `hhweight', replace
		** newid smpl_hh
		
** psu, urban/rural dataset
	use "`dat_folder_lsms'/`dat_folder_country'/GUY_LSMS_1992_1993_CONKM03.DTA", clear
	tempfile hhpsu
	save `hhpsu', replace
		** newid smpl_hh
	

** merge
use `hhweight', clear
merge 1:1 newid smpl_hh using `hhserv'
drop if _merge != 3
drop _merge
merge 1:1 newid smpl_hh using `hhpsu'
drop if _merge != 3
drop _merge


** apply labels
label define wsource 1 "private, piped into dwelling" 2 "priv. catchment, not piped" /// 
	3 "public, piped into dwelling" 4 "public, piped into yard" 5 "public standpipe" ///
	6 "public well or tank" 9 "others (specify)"
label values hous6 wsource
replace hous6 = . if hous6 == 0

label define ttype 1 "w.c. linked to sewer" 2 "w.c. cesspit or septic tank" 3 "pit latrine" ///
	4 "none" 9 "others (specify)"
label values hous4 ttype
replace hous4 = . if hous4 == 0


** save
cd "`dat_folder_lsms_merged'"
save "guyana_1993", replace

