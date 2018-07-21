// File Name: supas_std_indonesia_1995.do

// File Purpose: Create standardized dataset with desired variables from SUPAS Indonesia 1995 survey
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
local dat_folder_country "1995"



** water, sanitation dataset
	use "`dat_folder_supas'/`dat_folder_country'/IDN_INTERCENSAL_POPULATION_SURVEY_SUPAS_1995_03_HH_MEMBERS_LIST", clear
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
label variable p416 "water source"
label define wsource 1 "piped water" 2 "pump" 3 "well" 4 "spring" 5 "river" 6 "rainwater" 96 "other"
label values p416 wsource

label variable p420 "toilet facility"
label define ttype 1 "private, with septic tank" 2 "private, without septic tank" 3 "shared" ///
	4 "public" 5 "direct on cesspool" 6 "bushes/forest/yard" 7 "pond" 8 "river/stream" 96 "other"
label values p420 ttype

label variable prop "province"
destring prop, replace

label variable kab "regency/municipality"

label variable kec "sub-regency/sub-district"

label variable desa "village"

label variable kp "area (urban/rural)"
destring kp, replace
label define urban 1 "urban" 2 "rural"
label values kp urban

label variable nks "sample code number"
label variable nus "number of segment group/number of segment"



** save
cd "`dat_folder_other_merged'"
save "supas_indonesia_1995", replace


capture log close