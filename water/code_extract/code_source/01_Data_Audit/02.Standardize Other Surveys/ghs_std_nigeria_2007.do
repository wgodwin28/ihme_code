// File Name: ghs_std_nigeria_2007.do

// File Purpose: Create standardized dataset with desired variables from GHS Nigeria 2007 Survey
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
local dat_folder "J:\DATA\NGA\GENERAL_HOUSEHOLD_SURVEY\2006_2007"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/NGA_GHS_2006_2007_PARTA__IDENTIFICATION.DTA", clear
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
destring swater, replace
label define wsource 1 "pipe borne water treated" 2 "pipe borne water not treated" 3 "borehole/hand pump" ///
	4 "protected well/spring" 5 "unprotected well/spring" 6 "rainwater" 7 "stream/pond/river" 8 "tanker/truck/vendor" ///
	9 "other sources"
label values swater wsource

destring tfclties, replace
label define ttype 1 "none" 2 "toilet on water" 3 "flush to sewage" 4 "flush to septic tank" 5 "pail/bucket" ///
	6 "covered pit latrine" 7 "uncovered pit latrine" 8 "VIP latrine" 9 "other types"
label values tfclties ttype

replace eacode = "0204" if eacode == "02O4"
replace eacode = "0151" if eacode == "015l"
replace eacode = "0211" if eacode == "021I"
replace eacode = "0454" if eacode == "04t4"
replace eacode = "0428" if eacode == "0r28"
replace eacode = "0150" if eacode == "015O"
replace eacode = "0104" if eacode == "01O4"
replace eacode = "0105" if eacode == "01O5"
destring eacode, replace

destring sector, replace
label define urb 1 "urban" 2 "rural"
label values sector urb

** save
cd "`dat_folder_other_merged'"
save "ghs_nigeria_2007", replace


capture log close