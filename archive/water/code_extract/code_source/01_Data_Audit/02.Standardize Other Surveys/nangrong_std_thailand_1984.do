// File Name: nangrong_std_thailand_1984.do

// File Purpose: Create standardized dataset with desired variables from Nang Rong Thailand 1984 Survey
// Author: Leslie Mallinger
// Date: 7/30/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder "J:/DATA/THA/NANG_RONG_PROJECTS/1984"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/THA_NANGRONG_1984_HOUSEHOLD", clear
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
gen wsource = .
label variable wsource "drinking water source"
replace wsource = 1 if (hh84_08 == 1 | hh84_08 == 3) // piped water
replace wsource = 2 if (hh84_09 == 1 | hh84_09 == 3) & wsource == .	// rainwater
replace wsource = 3 if (hh84_10 == 1 | hh84_10 == 3) & wsource == .	// hand/pump well
replace wsource = 4 if (hh84_11 == 1 | hh84_11 == 3) & wsource == . 	// dug well
replace wsource = 5 if (hh84_12 == 1 | hh84_12 == 3) & wsource == .	// pond/swamp/reservoir
replace wsource = 6 if (hh84_13 == 1 | hh84_13 == 3) & wsource == . 	// river/canal/weir
label define wsource 1 "piped water" 2 "rainwater" 3 "hand/pump well" 4 "dug well" 5 "pond/swamp/reservoir" ///
	6 "river/canal/weir"
label values wsource wsource

label variable hh84_32 "Type of latrine/toilet"
label define ttype 1 "inside house" 2 "outside house" 3 "ground pit" 4 "public" 5 "other (e.g., temple latrine)" ///
	8 "no latrine" 9 "missing/don't know"
label values hh84_32 ttype

gen psu = 1


** save
cd "`dat_folder_other_merged'"
save "nangrong_thailand_1984", replace


capture log close