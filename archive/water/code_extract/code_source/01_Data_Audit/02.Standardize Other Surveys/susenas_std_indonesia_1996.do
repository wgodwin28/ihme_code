// File Name: susenas_std_indonesia_1996.do

// File Purpose: Create standardized dataset with desired variables from SUSENAS Indonesia 1996 survey
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
local dat_folder_country "1996"



** water, sanitation dataset
	use "`dat_folder_survey'/`dat_folder_country'/IDN_SOCIOECONOMIC_SURVEY_SUSENAS_1996_CORE_HH", clear
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
label variable k8r8 "water source"
destring k8r8, replace
label define wsource 1 "pipe" 2 "pump" 3 "protected well" 4 "unprotected well" 5 "protected spring" ///
	6 "unprotected spring" 7 "river water" 8 "rainwater" 9 "other"
label values k8r8 wsource

label variable k8r10a "toilet shared"
destring k8r10a, replace
label define tshare 1 "private" 2 "shared" 3 "public" 4 "other"
label values k8r10a tshare

label variable k8r10b "toilet type"
destring k8r10b, replace
label define ttype  1 "capped septic tank/western toiliet" 2 "unsealed tank or pit" 3 "pit or hole" 4 "don't use a toilet"
label values k8r10b ttype

label variable k8r10c "toilet disposal"
destring k8r10c, replace
label define tdisp 1 "septic tank" 2 "pond/field rice" 3 "river/lake/ocean" 4 "hole" 5 "shore/open field" 6 "other"
label values k8r10c tdisp

gen ttype = .
replace ttype = 1 if k8r10b == 1
replace ttype = 2 if k8r10b == 2
replace ttype = 3 if k8r10b == 3
replace ttype = 4 if k8r10b == 4 & k8r10c == 1
replace ttype = 5 if k8r10b == 4 & k8r10c != 1
label define toilet 1 "capped septic tank/western toilet" 2 "unsealed tank or pit" 3 "pit or hole" ///
	4 "other, to septic tank" 5 "don't use a toilet"
label values ttype toilet

label variable k1r1 "province"
destring k1r1, replace

label variable k1r2 "regency/municipality"

label variable k1r3 "district"

label variable k1r4 "village/kelurahan"

label variable kir5 "area"
destring kir5, replace
label define urban 1 "urban" 2 "rural"
label values kir5 urban

label variable inflate "weight"
destring inflate, replace


** save
cd "`dat_folder_other_merged'"
save "susenas_indonesia_1996", replace


capture log close