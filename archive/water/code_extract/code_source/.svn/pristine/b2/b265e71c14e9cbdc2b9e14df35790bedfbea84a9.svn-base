// File Name: lsms_std_nicaragua_2005.do

// File Purpose: Create standardized dataset with desired variables from LSMS Nicaragua 2005 survey
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
local dat_folder_country "NIC/2005"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/NIC_LSMS_2005_HOUSING.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** no linking needed
	
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


** fix labels
label define wsource 1 "tuberia dentro de la vivienda" 2 "tuberia fuera de la vivienda" 3 "puesto publico" ///
	4 "pozo publico o privado" 5 "ojo de agua o manantial" 6 "rio, quebrada, arroyo" 7 "camion, carreta o pipa" ///
	8 "lago, laguna" 9 "de otra vivienda/vecino/empresa" 10 "otro, cual?"
label values s1p20a s1p20b wsource

replace s1p20a = 1 if s1p20b == 1
replace s1p20a = 2 if s1p20b == 2
replace s1p20a = 4 if s1p20b == 4
replace s1p20a = 10 if s1p20b == 10

label define ttype 1 "excusado o letrina sin tratar" 2 "excusado o letrina con tratamiento" ///
	3 "inodoro, conectado a tuberia de aguas negras" 4 "inodoro conectado a sumidero o pozo septico" ///
	5 "inodoro, que descarga en rio o quebrada" 6 "no tiene"
label values s1p32 ttype


** save
cd "`dat_folder_lsms_merged'"
save "nicaragua_2005", replace

