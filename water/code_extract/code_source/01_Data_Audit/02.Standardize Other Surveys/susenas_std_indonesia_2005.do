// File Name: susenas_std_indonesia_2005.do

// File Purpose: Create standardized dataset with desired variables from SUSENAS Indonesia 2005 survey
// Author: Leslie Mallinger
// Date: 6/21/2010
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
local dat_folder_country "2005"



** water, sanitation dataset
	use "`dat_folder_survey'/`dat_folder_country'/IDN_SOCIOECONOMIC_SURVEY_SUSENAS_2005_JULY_CORE_HH", clear
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
label variable b6r3a "water source"
destring b6r3a, replace
label define wsource 1 "bottled water" 2 "tap water" 3 "pump" 4 "protected well" 5 "unprotected well" ///
	6 "protected spring" 7 "unprotected spring" 8 "river" 9 "rain water" 0 "other"
label values b6r3a wsource

** label variable b6r10a "toilet shared"
** destring b6r10a, replace
** label define tshare 1 "private" 2 "shared" 3 "public" 4 "other"
** label values b6r10a tshare

** label variable b6r10b "toilet type"
** destring b6r10b, replace
** label define ttype  1 "squatter" 2 "throne" 3 "dry latrine" 4 "other"
** label values b6r10b ttype

** label variable b6r10c "toilet disposal"
** destring b6r10c, replace
** label define tdisp 1 "septic tank" 2 "pond/field rice" 3 "river/lake/ocean" 4 "hole" 5 "shore/open field" 6 "other"
** label values b6r10c tdisp

** gen ttype = .
** replace ttype = 1 if b6r10b == 1
** replace ttype = 2 if b6r10b == 2
** replace ttype = 3 if b6r10b == 3
** replace ttype = 4 if b6r10b == 4 & b6r10c == 1
** replace ttype = 5 if b6r10b == 4 & b6r10c == 2
** replace ttype = 6 if b6r10b == 4 & b6r10c == 3
** replace ttype = 7 if b6r10b == 4 & b6r10c == 4
** replace ttype = 8 if b6r10b == 4 & b6r10c == 5
** replace ttype = 9 if b6r10b == 4 & b6r10c == 6
** label variable ttype "toilet type, including disposal location"
** label define toilet 1 "capped septic tank/western toiliet" 2 "unsealed tank or pit" 3 "pit or hole" 4 "don't use a toilet" ///
	** 5 "other - to pond/field rice" 6 "other - to river/lake/ocean" 7 "other - to hole" ///
	** 8 "other - to shore/open field" 9 "other"
** label values ttype toilet

label variable b1r1 "province"
destring b1r1, replace

label variable b1r2 "regency/municipality"

label variable b1r3 "subregency"

label variable b1r4 "village/kelurahan"

label variable b1r5 "area"
destring b1r5, replace
label define urban 1 "urban" 2 "rural"
label values b1r5 urban

label variable wert "weight"


** save
cd "`dat_folder_other_merged'"
save "susenas_indonesia_2005", replace


capture log close