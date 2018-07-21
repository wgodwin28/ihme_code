// File Name: lcms_std_zambia_2004.do

// File Purpose: Create standardized dataset with desired variables
// Author: Leslie Mallinger
// Date: 7/14/2011
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder "J:\DATA\ZMB\LCMS\2004_2005"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** water, sanitation dataset
	use "`dat_folder'/ARCHIVE/ZMB_LCMS_2004_2005_HH_HOUSE_AMEN.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hhcode
	
** ** household weights dataset
	** use "`dat_folder'/ZMB_HH_HEALTH_COVERAGE_SURVEY_2008_HH_ID.DTA", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** hhcode
		
** ** psu, urban/rural dataset
	** use "`dat_folder'/PAK_PIH_HIES_1998_1999_ROSTER.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** ** merge
** use `hhserv', clear
** merge m:1 vhclust vhnumber using `hhweight'
** drop if _merge != 3
** drop _merge


** apply labels
destring C007B, replace
label define water 1 "directly from the river/lake/stream/dam" 2 "unprotected well" ///
	3 "pumped (piped) from the river/lake/dam" 4 "protected well" 5 "borehole" 6 "public tap" ///
	7 "own tap" 8 "other tap" 9 "bought from water vendor" 10 "other"
label values C007B water

destring C015_TO, replace
label define toilet 1 "own flush toilet inside the house" 2 "own flush toilet outside the house" ///
	3 "communal/shared flush toilet" 4 "own pit latrine" 5 "communal pit latrine" ///
	6 "neighbour's/another household's pit latrine" 7 "bucket/tin/other container" ///
	8 "aqua privy" 9 "other" 10 "none"
label values C015_TO toilet

label variable sea "SEA no (psu)"


** save
cd "`dat_folder_other_merged'"
save "lcms_zambia_2004", replace


capture log close