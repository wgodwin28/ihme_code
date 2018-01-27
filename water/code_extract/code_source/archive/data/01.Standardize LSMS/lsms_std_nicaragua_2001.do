// File Name: lsms_std_nicaragua_2001.do

// File Purpose: Create standardized dataset with desired variables from LSMS Nicaragua 2001 survey
// Author: Leslie Mallinger
// Date: 6/1/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
if "`c(os)'" == "Windows" {
	global j "J:"
}
else {
	global j "/home/j"
	set odbcmgr unixodbc
}


** create locals for relevant files and folders
local dat_folder_lsms "${j}/DATA/WB_LSMS"
local dat_folder_lsms_merged "${data_folder}/LSMS/Merged Original Files"
local codes_folder "${j}/Usable/Common Indicators/Country Codes"
local dat_folder_country "NIC/2001"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/NIC_LSMS_2001_HOUSING.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** nh and clust
	
** ** household weights dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/POV_GH.DTA", clear
	** tempfile hhweight
	** save `hhweight', replace
		** ** nh and clust
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/SEC0A.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
use `hhserv', clear
** merge 1:1 nh clust using `hhserv'
** drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
label define wsource 1 "Tuberia dentro de la vivienda" 2 "Tuberia fuera de la vivienda, pero dentro del terreno" ///
	3 "Puesto publico" 4 "Pozo publico o privado" 5 "Rio, manantial o quebrada" 6 "Camion, carreta o pipa" ///
	7 "De otra vivienda, vecino/empresa" 8 "Otro, cual"
label values s1p20 wsource

label define ttype 1 "Excusado o letrina sin tratar" 2 "Excvusado o letrina con tratamiento" ///
	3 "Inodoro, conectado a tuberias de aguas negras" 4 "Inodoro, conectado a sumidero o pozo septico" ///
	5 "Inodoro, que descarga en rio o quebrada" 6 "No tiene"
label values s1p29 ttype


** save
cd "`dat_folder_lsms_merged'"
save "nicaragua_2001", replace

