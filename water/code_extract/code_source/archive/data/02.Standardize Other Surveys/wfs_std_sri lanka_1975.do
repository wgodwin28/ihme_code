// File Name: wfs_std_sri lanka_1975.do

// File Purpose: Create standardized dataset with desired variables from WFS Sri Lanka 1975 Survey
// Author: Leslie Mallinger
// Date: 7/19/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder_wfs "J:/DATA/ISI_WFS"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder_wfs'/LKA/LKA_WFS_1975_COMPLETE_Y2008M10D10.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hhid
	
** ** household weights dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/za94cdta/STRATA2", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** hhid
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/za94cdta/STRATA2", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
** use `hhweight', clear
** merge 1:m hhid using `hhserv'
** drop if _merge != 3
** drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
label define water 1 "private pipe" 2 "private well" 3 "private pump" 4 "common pipe" 5 "common well" ///
	6 "common pump" 7 "other" 9 "not specified"
label values HC16 water

label define toilet 1 "flush" 2 "bucket" 3 "water seal" 4 "cesspit" 5 "none" 9 "not specified"
label values HC17 toilet


** save
cd "`dat_folder_other_merged'"
save "wfs_sri lanka_1975", replace


capture log close