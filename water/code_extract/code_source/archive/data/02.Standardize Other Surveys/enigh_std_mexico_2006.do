// File Name: enigh_std_mexico_2006.do

// File Purpose: Create standardized dataset with desired variables from ENIGH Mexico 2006 Survey
// Author: Leslie Mallinger
// Date: 8/6/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder "J:\DATA\MEX\SURVEY_INCOME_AND_HOUSEHOLD_EXPENDITURE_ENIGH\2006"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/MEX_ENIGH_2006_HOUSEHOLD.DTA", clear
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
destring agua15, replace
label variable agua15 "en esta vivienda tienen agua de..."
label define wsource 1 "la red publica, dentro de la vivienda" ///
	2 "la red publica, fuera de la vivienda pero dentro del terreno" 3 "un llave publica o hidrante" ///
	4 "otra vivienda" 5 "una pipa" 6 "un pozo" 7 "un rio, arroyo, o lago" 8 "otro fuente"
label values agua15 wsource

destring bano17, replace
label variable bano17 "esta vivienda tiene excusado, retrete, sanitario, letrina u hoyo negro"
label define sino 1 "si" 2 "no"
label values bano17 sino

destring bano18, replace
label variable bano18 "este excusado lo usan solamente las personas que viven en esta vivienda?"
label values bano18 sino

destring bano19, replace 
label variable bano19 "servicio conexion de agua"
label define ttype1 1 "tiene conexion de agua" 2 "le echan agua con cubeta" 3 "no se le puede echar agua"
label values bano19 ttype1

destring drenaje21, replace
label variable drenaje21 "esta vivienda tiene drenaje o desague conectado a ..."
label define ttype2 1 "la red publica" 2 "una fosa septica" 3 "una tuberia que va a dar a una barranca o grieta" ///
	4 "una tuberia que va a dar a un rio, lago o mar" 5 "no tiene drenaje"
label values drenaje21 ttype2

gen ttype = .
replace ttype = 1 if drenaje21 == 1	// conectado a la red publica
replace ttype = 2 if drenaje21 == 2	// conectado a una fosa septica
replace ttype = 3 if bano19 == 1 & ttype == .	// servicio sanitario tiene conexion de agua
replace ttype = 4 if bano19 == 2 & ttype == .	// servicio sanitario tiene le echan agua con cubeta
replace ttype = 5 if (drenaje21 == 3 | drenaje21 == 4) & ttype == .	// tuberia a otra parte
replace ttype = 6 if bano17 == 1 & bano19 == 3 & ttype == .	// servicio sanitario sin conexion de agua
replace ttype = 7 if bano17 == 2 & ttype == .	// no tiene excusado, retrete, sanitario, letrina u hoyo negro

label define ttype 1 "conectado a la red publica" 2 "conectado a una fosa septica" ///
	3 "servicio sanitario tiene conexion de agua" 4 "servicio sanitario tiene le echan agua con cubeta" ///
	5 "tuberia a otra parte" 6 "servicio sanitario sin conexion de agua" ///
	7 "no tiene excusado, retrete, sanitario, letrina u hoyo negro"
label values ttype ttype

destring estrato, replace


** save
cd "`dat_folder_other_merged'"
save "enigh_mexico_2006", replace


capture log close