// File Name: encovi_std_honduras_2004.do

// File Purpose: Create standardized dataset with desired variables from Survey of Living Conditions ENCOVI Honduras 2004
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
local dat_folder "J:\DATA\HND\SURVEY_OF_LIVING_CONDITIONS\2004"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/HND_ENCOVI_2004_HOUSING.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hhid
	
** ** household weights dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/za94cdta/STRATA2", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** hhid
		
** ** psu, urban/rural dataset
	** use "`dat_folder'/TZA_HBS_2000_2001_WGHTS_Y2010M10D06.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** ** merge
** use `hhpsu', clear
** merge 1:m hhid using `hhserv'
** drop if _merge != 3
** drop _merge


** ** apply labels
label variable s1p27 "27. �De d�nde obtiene el agua para tomar?  source of drinking water"

gen toilet = s1p31
replace toilet = 9 if s1p31 == . & s1p30 == 2
label define toilet 1 "inodoro conectado a alcantarilla" 2 "inodoro conectado a pozo septico" ///
	3 "inodoro con desague a rio, laguna, mar" 4 "letrina con descarga a rio, laguna, mar" ///
	5 "letrina con cierre hidraulico" 6 "letrina con pozo septico" 7 "letrina con pozo negro" ///
	8 "letrina abonera" 9 "no toilet"
label values toilet toilet

label variable factor "Factor de expansion (weight)"
label variable seg_cen "segmento censal (psu)"



** save
cd "`dat_folder_other_merged'"
save "encovi_honduras_2004", replace


capture log close