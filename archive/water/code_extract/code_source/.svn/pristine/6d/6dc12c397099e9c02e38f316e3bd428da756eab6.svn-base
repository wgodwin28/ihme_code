// File Name: wfs_std_philippines_1978.do

// File Purpose: Create standardized dataset with desired variables from WFS Philippines 1978 Survey
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
	use "`dat_folder_wfs'/PHL/PHL_WFS_1978_COMPLETE_Y2008M10D10.DTA", clear
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
label define dwater 0 "other" 1 "pipe water" 2 "artesian well" 3 "pump" 4 "open well" ///
	5 "rain water" 6 "spring" 7 "lake, river, etc." 9 "not stated"
label values HC27 HC28 dwater

label define ttype 1 "private toilet, inside house" 2 "private toilet, outside house" 3 "no private toilet" ///
	9 "not stated"
label values HC29 ttype



** save
cd "`dat_folder_other_merged'"
save "wfs_philippines_1978", replace


capture log close