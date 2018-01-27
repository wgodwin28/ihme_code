// File Name: supas_std_indonesia_2005.do

// File Purpose: Create standardized dataset with desired variables from SUPAS Indonesia 2005 survey
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
local dat_folder_country "2005"



** water, sanitation dataset
	use "`dat_folder_supas'/`dat_folder_country'/IDN_INTERCENSAL_POPULATION_SURVEY_SUPAS_2005_05A_07B_VITAL_INFO_HH_MEMBERS_MARRIED_WOMEN", clear
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
label variable p522 "water source"
label define wsource 1 "piped water" 2 "covered well" 3 "uncovered well" 4 "covered spring" 5 "uncovered spring" ///
	6 "river" 7 "lake/dam" 8 "rain water" 9 "bottled water" 96 "other (specify)" 99 "don't know"
label values p522 wsource

label variable p525 "toilet facility"
label define ttype 1 "private toilet with septic tank" 2 "private toilet with no septic tank" 3 "shared toilet" ///
	4 "public  toilet" 5 "river" 6 "pit" 7 "yard/bush/forest" 96 "other (specify)" 99 "don't know"
label values p525 ttype

label variable p101 "province"

label variable p102 "regency/municipality"

label variable p105 "village classification"
label define urban 1 "urban" 2 "rural"
label values p105 urban

label variable p109 "selected household number"


** save
cd "`dat_folder_other_merged'"
save "supas_indonesia_2005", replace


capture log close