// File Name: supas_std_indonesia_1985.do

// File Purpose: Create standardized dataset with desired variables from SUPAS Indonesia 1985 survey
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
local dat_folder_supas "J:/DATA/IDN/INTERCENSAL_POPULATION_SURVEY_SUPAS"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"
local dat_folder_country "1985"



** water, sanitation dataset
	use "`dat_folder_supas'/`dat_folder_country'/IDN_INTERCENSAL_POPULATION_SURVEY_SUPAS_1985_05_HH_CHARACTERISTICS", clear
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
label variable b6p13 "water source"
destring b6p13, replace
replace b6p13 = . if b6p13 == 9
label define wsource 1 "tap water" 2 "pump" 3 "well" 4 "spring" 5 "river" 6 "rain" 7 "other"
label values b6p13 wsource

label variable b6p17 "place of toilet"
destring b6p17, replace
replace b6p17 = . if b6p17 == 9
label define ttype 1 "private toilet with septic tank" 2 "private toilet without septic tank" ///
	3 "share/public/other toilets"
label values b6p17 ttype

label variable b1p1 "province"
destring b1p1, replace

label variable b1p2 "regency/municipality"

label variable b1p5 "area"
destring b1p5, replace
label define urban 1 "urban" 2 "rural"
label values b1p5 urban

label variable inf_rmt "household weight"
destring inf_rmt, replace

label variable inf_pddk "population weight"
destring inf_pddk, replace


** save
cd "`dat_folder_other_merged'"
save "supas_indonesia_1985", replace


capture log close