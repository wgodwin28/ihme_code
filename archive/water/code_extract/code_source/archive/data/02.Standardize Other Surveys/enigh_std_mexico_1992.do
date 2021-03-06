// File Name: enigh_std_mexico_1992.do

// File Purpose: Create standardized dataset with desired variables from ENIGH Mexico 1992 Survey
// Author: Leslie Mallinger
// Date: 8/3/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder "J:\DATA\MEX\SURVEY_INCOME_AND_HOUSEHOLD_EXPENDITURE_ENIGH\1992"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/MEX_ENIGH_1992_HOUSEHOLD.DTA", clear
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
destring agua, replace
replace agua = . if agua == 0
label define wsource 1 "agua entubada dentro de la vivienda" /// 
	2 "agua entubada fuera de la vivienda pero si en el edificio, vecindad o terreno" ///
	3 "agua de pozo dentro del terreno" 4 "agua por acarreo" 5 "entrega de agua a domicilio (pipa)"
label values agua wsource

destring estrato, replace


** save
cd "`dat_folder_other_merged'"
save "enigh_mexico_1992", replace


capture log close