// File Name: mxfls_std_mexico_2002.do

// File Purpose: Create standardized dataset with desired variables from MXFLS Mexico 2002 Survey
// Author: Leslie Mallinger
// Date: 7/21/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder_mxfls "J:/DATA/MEX/FAMILY_LIFE_SURVEY_MXFLS/2002_WAVE_1"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder_mxfls'/MEX_MXFLS_2002_WAVE_1_HH_CONTROL_BOOK_HOUSING_C_CV_Y2010M07D15.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** folio
	
** household weights dataset
	use "`dat_folder_mxfls'/MEX_MXFLS_2002_WAVE_1_HH_CONTROL_BOOK_WEIGHTS_C_Y2010M07D15.DTA", clear
	duplicates drop
	tempfile hhweight
	save `hhweight', replace
		** folio
		
** psu, urban/rural dataset
	use "`dat_folder_mxfls'/MEX_MXFLS_2002_WAVE_1_HH_CONTROL_BOOK_COVER_C_PORTAD_Y2010M07D15.DTA", clear
	keep folio estrato
	duplicates drop
	tempfile hhpsu
	save `hhpsu', replace
		** folio
	

** merge
use `hhweight', clear
merge 1:1 folio using `hhserv'
drop if _merge != 3
drop _merge
merge 1:1 folio using `hhpsu'
keep if _merge == 3
drop _merge


** apply labels
label define wsource 1 "decanter" 2 "tap water inside the dwelling" 3 "tap water outside the dwelling" ///
	4 "water from a truck" 5 "gathered" 6 "other (specify)"
label values cv08_1 wsource

label define osource 1 "tap water inside the dwelling" 2 "tap water outside the dwelling" 3 "water from a truck" ///
	4 "gathering" 5 "other(specify)"
label values cv13_1 osource

gen toilet = .
replace toilet = 1 if cv16 == 1 & cv17_1a == 1	// toilet to piped public drainage
replace toilet = 2 if cv16 == 1 & cv17_1b == 2	// toilet to septic tank
replace toilet = 3 if cv16 == 2 & cv17_1a == 1	// latrine to piped public drainage
replace toilet = 4 if cv16 == 2 & cv17_1b == 2	// latrine to septic tank
replace toilet = 5 if cv16 == 3 & cv17_1a == 1	// black hole or blind well to piped public drainage
replace toilet = 6 if cv16 == 3 & cv17_1b == 2	// black hole or blind well to septic tank
replace toilet = 7 if cv16 == 1 & toilet == .	// toilet to other
replace toilet = 8 if cv16 == 2 & toilet == .	// latrine to other
replace toilet = 9 if cv16 == 3 & toilet == .	// black hole or blind well to other
replace toilet = 10 if cv16 == 4	// does not have sanitary service
label define ttype 1 "toilet to piped public drainage" 2 "toilet to septic tank" /// 
	3 "latrine to piped public drainage" 4 "latrine to septic tank" 5 "black hole or blind well to piped public drainage" ///
	6 "black hole or blind well to septic tank" 7 "toilet to other" 8 "latrine to other" /// 
	9 "black hole or blind well to other" 10 "does not have sanitary service"
label values toilet ttype

label variable estrato "urbanicity"
label define urb 1 "more than 100,000 inhabitants" 2 "15,000 to 100,000 inhabitants" ///
	3 "2,500 to 15,000 inhabitants" 4 "fewer than 2,500 inhabitants"
label values estrato urb


** save
cd "`dat_folder_other_merged'"
save "mxfls_mexico_2002", replace


capture log close