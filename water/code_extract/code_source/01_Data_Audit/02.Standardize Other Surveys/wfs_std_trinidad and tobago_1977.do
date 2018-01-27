// File Name: wfs_std_trinidad and tobago_1977.do

// File Purpose: Create standardized dataset with desired variables from WFS Trinidad and Tobago 1977 Survey
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
	use "`dat_folder_wfs'/TTO/TTO_WFS_1977_COMPLETE_Y2008M10D10.DTA", clear
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
label define water 1 "piped in house" 2 "piped in yard" 3 "private catchment piped" 4 "private catchment not piped" ///
	5 "public standpipe" 6 "spring or well" 7 "stream or river" 8 "truck borne" 9 "other"
label values HC121 water


** save
cd "`dat_folder_other_merged'"
save "wfs_trinidad and tobago_1977", replace


capture log close