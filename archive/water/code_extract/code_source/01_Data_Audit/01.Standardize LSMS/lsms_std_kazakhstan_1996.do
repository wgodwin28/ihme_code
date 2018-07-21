// File Name: lsms_std_kazakhstan_1996.do

// File Purpose: Create standardized dataset with desired variables from LSMS Kazakhstan 1996 survey
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
local dat_folder_country "KAZ/1996"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/KAZ_LSMS_1996_HH_SEC_B_HOUSING.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** respond
	
** ** household weights dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/POV_GH.DTA", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** nh and clust
		
** psu, urban/rural dataset
	use "`dat_folder_lsms'/`dat_folder_country'/KAZ_LSMS_1996_HH_SEC_A_HH_INFO.DTA", clear
	tempfile hhpsu
	save `hhpsu', replace
		** respond
	

** merge
use `hhserv', clear
merge 1:1 respond using `hhpsu'
drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** create cohesive variables and apply labels
gen wsource = .
replace wsource = 1 if b24_01 == 1	// running water in apartment/house
replace wsource = 5 if b24_05 == 1 & wsource == .	// public pump
replace wsource = 6 if b24_06 == 1 & wsource == .	// public well
replace wsource = 2 if b24_02 == 1 & wsource == .	// water supply is close to the building
replace wsource = 3 if b24_03 == 1 & wsource == .	// have a well in your yard
replace wsource = 4 if b24_04 == 1 & wsource == .	// take from other private well
replace wsource = 7 if b24_07 == 1 & wsource == .	// spring
replace wsource = 8 if b24_08 == 1 & wsource == .	// river, lake, pond, irrigation channel
replace wsource = 9 if b24_09 == 1 & wsource == .	// water trucks
replace wsource = 10 if b24_10 == 1 & wsource == .	// buy mineral water
replace wsource = 11 if b24_11 == 1 & wsource == .	// other source
label define wsource 1 "running water in apartment/house" 2 "water supply is close to the building" ///
	3 "have a well in your yard" 4 "take from other private well" 5 "public pump" 6 "public well" ///
	7 "spring" 8 "river, lake, pond, irrigation channel" 9 "water trucks" 10 "buy mineral water" ///
	11 "other source"
label values wsource wsource

gen othersource = .
replace othersource = 1 if b24_01 == 1	// running water in apartment/house
replace othersource = 5 if b24_05 == 1 & othersource == .	// public pump
replace othersource = 6 if b24_06 == 1 & othersource == .	// public well
replace othersource = 2 if b24_02 == 1 & othersource == .	// water supply is close to the building
replace othersource = 3 if b24_03 == 1 & othersource == .	// have a well in your yard
replace othersource = 4 if b24_04 == 1 & othersource == .	// take from other private well
replace othersource = 7 if b24_07 == 1 & othersource == .	// spring
replace othersource = 8 if b24_08 == 1 & othersource == .	// river, lake, pond, irrigation channel
replace othersource = 9 if b24_09 == 1 & othersource == .	// water trucks
replace othersource = 11 if b24_11 == 1 & othersource == .	// other source
label define othersource 1 "running water in apartment/house" 2 "water supply is close to the building" ///
	3 "have a well in your yard" 4 "take from other private well" 5 "public pump" 6 "public well" ///
	7 "spring" 8 "river, lake, pond, irrigation channel" 9 "water trucks" 11 "other source"
label values othersource othersource

label define ttype 1 "flush toilet" 2 "letrine" 3 "open toilet"
label values b11 ttype


** save
cd "`dat_folder_lsms_merged'"
save "kazakhstan_1996", replace

