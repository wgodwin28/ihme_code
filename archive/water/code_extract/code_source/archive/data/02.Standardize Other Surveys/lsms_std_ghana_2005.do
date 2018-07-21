// File Name: lsms_std_ghana_2005.do

// File Purpose: Create standardized dataset with desired variables from LSMS Ghana 2005 Survey
// Author: Leslie Mallinger
// Date: 7/29/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder "J:\Data\WB_LSMS\GHA\2005"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/GHA_LSMS_2005_HOUSING", clear
	tempfile hhserv
	save `hhserv', replace
		** folio
	
** ** household weights dataset
	** use "`dat_folder'/weights/hh02w_bc", clear
	** duplicates drop
	** tempfile hhweight
	** save `hhweight', replace
		** ** folio
		
** ** psu, urban/rural dataset
	** use "`dat_folder'/household data/hh02dta_bc/c_portad", clear
	** keep folio estrato
	** duplicates drop
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** folio
	

** merge
** use `hhweight', clear
** merge 1:1 folio using `hhserv'
** drop if _merge != 3
** drop _merge
** merge 1:1 folio using `hhpsu'
** keep if _merge == 3
** drop _merge


** apply labels



** save
cd "`dat_folder_other_merged'"
save "lsms_ghana_2005", replace


capture log close