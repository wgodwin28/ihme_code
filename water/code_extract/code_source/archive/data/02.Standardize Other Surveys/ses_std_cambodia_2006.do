// File Name: ses_std_cambodia_2006.do

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
local dat_folder "J:\DATA\KHM\SOCIO_ECONOMIC_SURVEY\2006_2007"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** water, sanitation dataset
	use "`dat_folder'/KHM_CSES_2006_2007_HH_HOUSING.DTA ", clear
	gen psu = substr(hhid, 1, 5)
	tempfile hhserv
	save `hhserv', replace
		** hhid
	
** household weights dataset
	use "`dat_folder'/KHM_CSES_2006_2007_HH_WEIGHTS.DTA ", clear
	tempfile hhweight
	save `hhweight', replace
		** hhid
		
** psu, urban/rural dataset
	use "`dat_folder'/KHM_CSES_2006_2007_AREA_INFORMATION.DTA", clear
	tempfile hhpsu
	save `hhpsu', replace
		** hhid
	

** merge
use `hhpsu', clear
merge 1:m psu using `hhserv'
drop if _merge != 3
drop _merge
merge 1:1 hhid using `hhweight'
drop if _merge != 3
drop _merge


** ** apply labels
label variable Q04_12 "water source"
label define water 1 "piped in dwelling or on premises" 2 "public tap" 3 "tubed/piped well or borehole" ///
	4 "protected dug well" 5 "unprotected dug well" 6 "pond, river or stream" 7 "rainwater" ///
	8 "tanker truck, vendor or otherwise bought- vendor brings to hh" ///
	9 "tanker truck, vendor or otherwise bought- hh member goes to collect" 10 "other"
label values Q04_12 water

label variable Q04_19A "toilet type" 
label define toilet 1 "pour flush (or flush) connected to sewerage" 2 "pour flush (or flush) to septic tank or pit" ///
	3 "pit latrine with slab" 4 "pit latrine without slab or open pit" 5 "latrine overhanging field or water" ///
	6 "latrine overhanging water (for hh living on boat)" 7 "none" 8 "other"
label values Q04_19A toilet



** save
cd "`dat_folder_other_merged'"
save "ses_cambodia_2006", replace


capture log close