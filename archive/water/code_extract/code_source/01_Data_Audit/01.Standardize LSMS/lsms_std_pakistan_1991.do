// File Name: lsms_std_pakistan_1991.do

// File Purpose: Create standardized dataset with desired variables from LSMS Pakistan 1991 survey
// Author: Leslie Mallinger
// Date: 6/10/2010
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
local dat_folder_country "PAK/1991"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/PAK_LSMS_1991_F02C.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** clust
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/PAK_LSMS_1991_WEIGHTS.DTA", clear
	drop if clust == .
	tempfile hhweight
	save `hhweight', replace
		** clust
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/SEC0A.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
use `hhweight', clear
merge 1:m clust using `hhserv'
drop if _merge != 3
drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
label define wsource 1 "tap in house" 2 "outside private tap" 3 "public standpipe" 4 "covered well" ///
	5 "open well" 6 "canal/river" 7 "delivery/water seller" 8 "hand pump in the household" ///
	9 "hand pump outside the household" 10 "motor pump in the household" 11 "motor pump outside the household" ///
	12 "other (specify)"
label values dwater wsource

label define ttype 1 "communal latrine" 2 "household flush (connected to municipal sewer)" ///
	3 "household flush (connected to septic tank)" 4 "household non-flush" 5 "no toilet"
label values toilet ttype



** save
cd "`dat_folder_lsms_merged'"
save "pakistan_1991", replace
