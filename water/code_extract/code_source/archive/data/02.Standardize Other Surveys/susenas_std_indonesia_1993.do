// File Name: susenas_std_indonesia_1993.do

// File Purpose: Create standardized dataset with desired variables from SUSENAS Indonesia 2005 survey
// Author: Leslie Mallinger
// Date: 6/16/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder_survey "J:/DATA/IDN/SOCIOECONOMIC_SURVEY_SUSENAS"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"
local dat_folder_country "1993"



** water, sanitation dataset
	use "`dat_folder_survey'/`dat_folder_country'/IDN_SOCIOECONOMIC_SURVEY_SUSENAS_1993_CORE_HH_01", clear
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
label variable b8r7 "water source"
destring b8r7, replace
label define wsource 1 "pipe" 2 "pump" 3 "protected well" 4 "unprotected well" 5 "protected spring" ///
	6 "unprotected spring" 7 "river" 8 "rain water" 9 "other"
label values b8r7 wsource

label variable b8r9 "toilet facility"
destring b8r9, replace
label define ttype 1 "private, with septic tank" 2 "shared, with septic tank" 3 "private, without septic tank" ///
	4 "shared, without septic tank" 5 "public toilet" 6 "pond" 7 "river" 8 "hole" 9 "other"
label values b8r9 ttype

label variable b1r1 "province"
destring b1r1, replace

label variable b1r2 "regency/municipality"

label variable b1r3 "district"

label variable b1r4 "village/kelurahan"

label variable b1r5 "area"
destring b1r5, replace
label define urban 1 "urban" 2 "rural"
label values b1r5 urban

label variable hhrt "household weight"

** save
cd "`dat_folder_other_merged'"
save "susenas_indonesia_1993", replace


capture log close