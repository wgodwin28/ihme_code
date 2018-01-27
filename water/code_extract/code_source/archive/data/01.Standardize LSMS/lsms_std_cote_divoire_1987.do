// File Name: lsms_std_cote d'ivoire_1987.do

// File Purpose: Create standardized dataset with desired variables from LSMS Cote d'Ivoire 1987 survey
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
local dat_folder_country "CIV/1987"



** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/CIV_LSMS_1987_WEIGHTS.DTA", clear
	keep clust nh hid allwaitn
	tempfile hhweight
	save `hhweight', replace
		** hid
	
** household services
	// water and sanitation
	use "`dat_folder_lsms'/`dat_folder_country'/CIV_LSMS_1987_HOUSING_B.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hid


** merge
use `hhweight', clear
merge 1:1 hid using `hhserv'
drop _merge


** apply labels
label define wsource 1 "robinet dedans" 2 "revendeur d'eau" 3 "robinet dehors" 4 "puits avec pompe" ///
	5 "puits sans pompe" 6 "riviere, lac, source, marigot" 7 "eau de pluie" 8 "camion citerne" ///
	9 "autre (preciser)"
label values dwater wsource

label define ttype 1 "chasse d'eau" 2 "latrine a fosse" 3 "pas de w.c." 4 "autre (preciser)"
label values toilet ttype


** save
cd "`dat_folder_lsms_merged'"
save "cote divoire_1987", replace

