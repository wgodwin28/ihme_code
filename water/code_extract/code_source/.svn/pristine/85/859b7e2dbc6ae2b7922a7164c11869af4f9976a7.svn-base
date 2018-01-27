// File Name: lsms_std_bulgaria_1995.do

// File Purpose: Create standardized dataset with desired variables from LSMS Bulgaria 1995 survey
// Author: Leslie Mallinger
// Date: 5/7/2012
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
local dat_folder_country "BGR/1995"



** water and sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/BGR_LSMS_1995_HOUSING_3.DTA", clear
	duplicates drop hhnumber, force
	tempfile hhserv
	save `hhserv', replace
		** hhnumber
		
** ** household weights dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/BIH_LSMS_2001_POVERTY_ANNEX.DTA", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** psu
		
** psu, urban/rural dataset
	use "`dat_folder_lsms'/`dat_folder_country'/BGR_LSMS_1995_HH_INFO.DTA", clear
	rename distr psu
	tempfile hhpsu
	save `hhpsu', replace
		** psu
	

** merge
merge 1:m hhnumber using `hhserv', keep(3) nogen

** apply labels
rename typ_h2o water_source
rename typ_wast toilet_type


** save
cd "`dat_folder_lsms_merged'"
save "bulgaria_1995", replace
