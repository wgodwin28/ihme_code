// File Name: lsms_std_bosnia herzegovina_2003.do

// File Purpose: Create standardized dataset with desired variables from LSMS Bosnia and Herzegovina 2003 survey
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
local dat_folder_country "BIH/2003"



** water dataset
	use "`dat_folder_lsms'/`dat_folder_country'/BIH_LSMS_2003_WAVE3_HH_QUEST.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** bcaseid
		
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/BIH_LSMS_2003_WAVE3_CONTROL_FORM_IND.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** bcaseid
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/bbhcfhh", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** bcaseid
	

** merge
use `hhweight', clear
merge m:1 ccaseid using `hhserv'
keep if _merge == 3
drop _merge
** merge 1:m bcaseid using `hhweight'
** keep if _merge == 3
** drop _merge


** apply labels
label variable c2_q08 "source of drinking water"
label define wsource 1 "running water in the home" 2 "running water in the yard" 3 "public fountain" /// 
	4 "well or spring" 5 "other" 7 "NZ" 8 "BO"
label values c2_q08 wsource

label variable c2_q12 "connection to the sewerage"
label define ttype 1 "yes, public sewer" 2 "yes, septic tank" 3 "no, only Polish WC" 4 "other" 7 "NZ" 8 "BO"
label values c2_q12 ttype

label variable w3final "final wave 3 weight"



** save
cd "`dat_folder_lsms_merged'"
save "bosnia herzegovina_2003", replace

