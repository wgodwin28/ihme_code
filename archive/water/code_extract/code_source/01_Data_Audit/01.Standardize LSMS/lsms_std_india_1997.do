// File Name: lsms_std_india_1997.do

// File Purpose: Create standardized dataset with desired variables from LSMS India 1997 survey
// Author: Leslie Mallinger
// Date: 6/9/2010
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
local dat_folder_country "IND/UTTAR_PRADESH_BIHAR_1997_1998"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/IND_UTTAR_PRADESH_BIHAR_LSMS_1997_1998_HH_HOUSING_UTILITIES.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** village
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/IND_UTTAR_PRADESH_BIHAR_LSMS_1997_1998_PSU_LIST.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** village
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/SEC0A.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
use `hhweight', clear
merge 1:m village using `hhserv'
drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
label define wsource 1 "tap" 2 "well" 3 "tubewell/handpump" 4 "tank/pond/reservoir" 5 "river/canal/lake/pond" ///
	6 "other"
label values v03b01 wsource

label define ttype 1 "no latrine" 2 "flush system" 3 "septic tank" 4 "service latrine" 5 "other latrine"
label values v03b09 ttype



** save
cd "`dat_folder_lsms_merged'"
save "india_1997", replace

