// File Name: enigh_std_mexico_2000.do

// File Purpose: Create standardized dataset with desired variables from ENIGH Mexico 2000 Survey
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
local dat_folder "J:\DATA\MEX\SURVEY_INCOME_AND_HOUSEHOLD_EXPENDITURE_ENIGH\2000"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"



** water, sanitation dataset
	use "`dat_folder'/MEX_ENIGH_2000_HOUSEHOLD.DTA", clear
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
destring agua19, replace
replace agua19 = . if agua19 == 0
label variable agua19 "la vivienda tiene agua entubada?"
label define running 1 "si" 2 "no"
label values agua19 running

destring agua25, replace
replace agua25 = . if agua25 == 0
label variable agua25 "entonces de donde obtiene el agua?"
label define agua25 1 "agua de llave publica" 2 "agua por pipa del servcio publico" 3 "agua por pipa del servicio particular" ///
	4 "agua de pozo" 5 "agua por acarreo (arroyo, jaguey, rio, etc.)" 6 "otras fuente"
label values agua25 agua25

gen wsource = .
replace wsource = 1 if agua19 == 1	// running water
replace wsource = 2 if agua25 == 1 & wsource == .	// agua de llave publica
replace wsource = 3 if agua25 == 2 & wsource == .	// agua por pipa del servicio publico
replace wsource = 4 if agua25 == 3 & wsource == .	// agua por pipa del servicio particular
replace wsource = 5 if agua25 == 4 & wsource == .	// agua de pozo
replace wsource = 6 if agua25 == 5 & wsource == .	// agua por acarreo (arroyo, jaguey, rio, etc.)
replace wsource = 7 if agua25 == 6 & wsource == .	// otras (especifique)
label define wsource 1 "running water" 2 "agua de llave publica" 3 "agua por pipa del servicio publico" ///
	4 "agua por pipa del servicio particular" 5 "agua de pozo" 6 "agua por acarreo (arroyo, jaguey, rio, etc.)" ///
	7 "otras (especifique)"
label values wsource wsource

destring bano27, replace
replace bano27 = . if bano27 == 0
label variable bano27 "esta vivienda tiene cuarto de bano?"
label define sino 1 "si" 2 "no"
label values bano27 sino

destring bano28, replace
replace bano28 = . if bano28 == 0
label variable bano28 "esta vivienda tiene ... tipo servicio sanitario"
label define ttype1 1 "hoyo negro o pozo ciego" 2 "letrina" 3 "excusado" 4 "no dispone de servicio sanitario"
label values bano28 ttype1

destring bano29, replace
replace bano29 = . if bano29 == 0
label variable bano29 "el excusado tiene conexion de agua?"
label values bano29 sino

destring bano30, replace
replace bano30 = . if bano30 == 0
label variable bano30 "el hoyo negro o pozo ciego, letrina o excusado es exclusivo para los residentes de la vivienda?"
label values bano30 sino

destring drenaje31, replace
replace drenaje31 = . if drenaje31 == 0
label variable drenaje31 "el excusado cuenta con drenaje..."
label define drenaje31 1 "con desague al rio, lago, etc." 2 "conectado a una fosa septica" ///
	3 "conectado al de la calle" 4 "con otro tipo de desague"
label values drenaje31 drenaje31

gen ttype = .
label variable ttype "toilet type"
replace ttype = 1 if bano28 == 1	// hoyo negro o pozo ciego
replace ttype = 2 if bano28 == 2	// letrina
replace ttype = 3 if bano28 == 3 & drenaje31 == 2	// excusado conectado a una fosa septica
replace ttype = 4 if bano28 == 3 & bano29 == 1 & ttype == .	// excusado con conexion de agua
replace ttype = 5 if bano28 == 3 & bano29 == 2 & ttype == .	// excusado sin conexion de agua
replace ttype = 6 if bano28 == 4	// no dispone de servicio sanitario
label define ttype 1 "hoyo negro o pozo ciego" 2 "letrina" 3 "excusado conectado a una fosa septica" ///
	4 "excusado con conexion de agua" 5 "excusado sin conexion de agua" 6 "no dispone de servicio sanitario"
label values ttype ttype

destring estrato, replace


** save
cd "`dat_folder_other_merged'"
save "enigh_mexico_2000", replace


capture log close