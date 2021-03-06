// File Name: lsms_std_albania_2004.do

// File Purpose: Create standardized dataset with desired variables from LSMS Albania 2004 survey
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
local dat_folder_country "ALB/2004"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ALB_LSMS_2004_HH_BASIC_W3.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** chid
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ALB_LSMS_2004_WEIGHTS_W3.DTA", clear
	drop if wt_des == .
	duplicates drop chid wt_des, force
	tempfile hhweight
	save `hhweight', replace
		** chid
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/Round 1, Module 0_4/r1m0.dta", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** merge
use `hhweight', clear
merge 1:m chid using `hhserv'
keep if _merge == 3
drop _merge
** merge 1:1 hhid using `hhpsu'
** keep if _merge == 3
** drop _merge


** apply labels
** ** m2b_q01:
           ** ** 1 running water inside the dwelling
           ** ** 2 running water outside the dwelling
           ** ** 3 public tap
           ** ** 4 water truck
           ** ** 5 spring or well
           ** ** 6 river, lake, pond or similar
           ** ** 7 other
** ** m2b_q06:
           ** ** 1 running water inside the dwelling
           ** ** 2 running water outside the dwelling
           ** ** 3 public tab
           ** ** 4 water truck
           ** ** 5 spring or well
           ** ** 6 river, lake, pond  or similar
           ** ** 7 bottled water
           ** ** 8 other

gen wsource = .
replace wsource = m2b_q01 if m2b_q05 == 1
replace wsource = 1 if m2b_q06 == 1	// running water inside the dwelling
replace wsource = 2 if m2b_q06 == 2	// running water outside the dwelling
replace wsource = 3 if m2b_q06 == 3	// public tap
replace wsource = 4 if m2b_q06 == 4	// water truck
replace wsource = 5 if m2b_q06 == 5	// spring or well
replace wsource = 6 if m2b_q06 == 6	// river, lake, pond, or similar
replace wsource = 7 if m2b_q06 == 8	// other
replace wsource = 8 if m2b_q06 == 7	// bottled water
label define wsource 1 "running water inside the dwelling" 2 "running water outside the dwelling" ///
	3 "public tap" 4 "water truck" 5 "spring or well" 6 "river, lake, pond or similar" 7 "other" ///
	8 "bottled water"
label values wsource wsource
label variable wsource "source of drinking water - complete"


** save
cd "`dat_folder_lsms_merged'"
save "albania_2004", replace

