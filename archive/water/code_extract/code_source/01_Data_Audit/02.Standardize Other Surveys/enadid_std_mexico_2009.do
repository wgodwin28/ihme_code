// File Name: enadid_std_mexico_2009.do

// File Purpose: Create standardized dataset with desired variables from ENADID Mexico 2009 Survey
// Author: Leslie Mallinger
// Date: 7/21/2010
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
local dat_folder_enadid "J:\DATA\MEX\SURVEY_DEMOGRAPHIC_DYNAMICS_ENADID\2009"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** water, sanitation dataset
	use "`dat_folder_enadid'/MEX_ENADID_2009_HOUSINGHOUSEHOLDS.DTA", clear
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
label variable p1_7 "availability of water"
destring p1_7, replace
label define wsource 1 "tiene agua de la red publica dentro de la vivienda" /// 
	2 "tiene agua de la red publica fuera de la vivienda, pero dentro del terreno" ///
	3 "tiene agua de la red publica de otra vivienda" 4 "tiene agua de una llave publica o hidrante" ///
	5 "tiene agua de una pipa" 6 "tiene agua de un pozo" 7 "tiene agua de un rio, arroyo, lago u otro" ///
	9 "no especificado"
label values p1_7 wsource

label variable p1_10_ag "toilet (grouped)"
destring p1_10_ag, replace
label define ttype 1 "servicio sanitario exclusivo con admision directa de agua" ///
	2 "servicio sanitario exclusivo con admision manual de agua" ///
	3 "servicio sanitario exclusivo sin admision de agua" ///
	4 "servicio sanitario exclusivo con admision no especificada" ///
	5 "sin servicio sanitario exclusivo" ///
	6 "servicio sanitario exclusivo no especificado" ///
	7 "no disponen de servicio sanitario" ///
	8 "disposicion de sanitario no especificado"
label values p1_10_ag ttype
	
label variable fac_viv "weight"

label variable upm_dis "upm"
destring upm_dis, replace

label variable tloc "urban"
destring tloc, replace
label define urb 1 "de 100,000 habitantes y mas" 2 "de 15,000 a 99,999 habitantes" ///
	3 "de 2,500 a 14,999 habitantes" 4 "menos de 2,500 habitantes"
label values tloc urb


** save
cd "`dat_folder_other_merged'"
save "enadid_mexico_2009", replace


capture log close