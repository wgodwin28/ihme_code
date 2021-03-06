// File Name: lsms_std_guatemala_2000.do

// File Purpose: Create standardized dataset with desired variables from LSMS Guatemala 2000 survey
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
local dat_folder_lsms "${j}/DATA/WB_LSMS"
local dat_folder_lsms_merged "${data_folder}/LSMS/Merged Original Files"
local codes_folder "${j}/Usable/Common Indicators/Country Codes"
local dat_folder_country "GTM/2000"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/GTM_LSMS_2000_HH_BASICS.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hogar
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/GTM_LSMS_2000_HH_DWELLING.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** hogar
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/SEC0A.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
use `hhweight', clear
merge 1:1 hogar using `hhserv'
drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
	// NONE NEEDED


** save
cd "`dat_folder_lsms_merged'"
save "guatemala_2000", replace

