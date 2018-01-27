// File Name: lsms_std_azerbaijan_1995.do

// File Purpose: Create standardized dataset with desired variables from LSMS Azerbaijan 1995 survey
// Author: Leslie Mallinger
// Date: 6/8/2010
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
local dat_folder_lsms "J:/DATA/WB_LSMS"
local dat_folder_lsms_merged "${data_folder}/LSMS/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"
local dat_folder_country "AZE/1995"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/AZE_LSMS_1995_DWELLING_B.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** ppid
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/AZE_LSMS_1995_POP_POINT_SAMPLING_DATA.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** ppid
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/SEC0A.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
use `hhweight', clear
merge 1:m ppid using `hhserv'
drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
label define wsource 1 "centralized water pipe" 2 "own system of water supply" 3 "well" ///
	4 "river, lake, spring, pond" 5 "rainwater" 6 "other (specify)"
label values water wsource


** save
cd "`dat_folder_lsms_merged'"
save "azerbaijan_1995", replace

