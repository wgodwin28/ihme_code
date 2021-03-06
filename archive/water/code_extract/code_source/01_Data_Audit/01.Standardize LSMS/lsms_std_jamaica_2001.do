// File Name: lsms_std_jamaica_2001.do

// File Purpose: Create standardized dataset with desired variables from LSMS Jamaica 2001 survey
// Author: Leslie Mallinger
// Date: 6/1/2010
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
local dat_folder_country "JAM/2001"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/JAM_LSMS_2001_REC020", clear
	tempfile hhserv
	save `hhserv', replace
		** serial
	
** ** household weights dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/POV_GH.DTA", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** nh and clust
		
** psu, urban/rural dataset
	use "`dat_folder_lsms'/`dat_folder_country'/JAM_LSMS_2001_REC001", clear
	tempfile hhpsu
	save `hhpsu', replace
		** serial
	

** merge
use `hhserv', clear
merge 1:1 serial using `hhpsu'
drop if _merge == 2
drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
replace i17 = "" if i17 == "N"
destring i17, replace
replace i04 = "" if i04 == "N"
destring i04, replace

label define wsource 1 "indoor tap/pipe" 2 "outside private pipe/tap" 3 "public standpipe" 4 "well" ///
	5 "river, lake, spring, pond" 6 "rainwater (tank)" 7 "other (specify)"
label values i17 wsource

label define ttype 1 "w.c. linked to sewer" 2 "w.c. not linked" 3 "pit" 4 "other" 5 "none"
label values i04 ttype


** save
cd "`dat_folder_lsms_merged'"
save "jamaica_2001", replace

