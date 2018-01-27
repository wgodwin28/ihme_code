// File Name: wfs_std_mexico_1976.do

// File Purpose: Create standardized dataset with desired variables from WFS Mexico 1976 Survey
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
local dat_folder_wfs "J:\DATA\ISI_WFS"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder_wfs'/MEX/MEX_WFS_1976_1977_COMPLETE_Y2008M10D10.DTA", clear
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
label define pwater 1 "piped water" 2 "no piped water" 99 "not stated"
label values S048 pwater


** save
cd "`dat_folder_other_merged'"
save "wfs_mexico_1976", replace


capture log close