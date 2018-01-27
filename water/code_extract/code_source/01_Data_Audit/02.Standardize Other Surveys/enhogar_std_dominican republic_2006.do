// File Name: enhogar_std_dominican republic_2006.do

// File Purpose: Create standardized dataset with desired variables from ENHOGAR Dominican Republic 2006 survey
// Author: Leslie Mallinger
// Date: 6/23/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder_enhogar "J:\DATA\DOM\HOUSEHOLD_SURVEY"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"
local dat_folder_country "2006"



** water, sanitation dataset
	use "`dat_folder_enhogar'/`dat_folder_country'/DOM_HH_SURVEY_2006_HH_Y2009M12D09", clear
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
label define wsource 1 "del acueducto dentro de la casa" 2 "del acueducto del patio de la casa" ///
	3 "del acueducto fuera de la casa(acera)" 4 "del acueducto,  llave publica" 5 "agua de funditas plasticas" ///
	6 "manantial, rio, arroyo, canal" 7 "pozo" 8 "lluvia" 9 "camion tanque" 10 "camion tanque (para tomar)" ///
	11 "agua de botellones (procesada)" 12 "otro" 98 "no sabe" 99 "sin informacion"
label values p3012 wsource

label define ttype 1 "inodoro privado" 2 "inodoro compartido" 3 "letrina privada con cajon" /// 
	4 "letrina privada sin cajon" 5 "letrina compartida con cajon" 6 "letrina compartida sin cajon" ///
	7 "no hay servicio" 9 "sin informacion"
label values p3018 ttype


** save
cd "`dat_folder_other_merged'"
save "enhogar_dominican republic_2006", replace


capture log close