// File Name: lsms_std_ecuador_1998.do

// File Purpose: Create standardized dataset with desired variables from LSMS Ecuador 1998 survey
// Author: Leslie Mallinger
// Date: 6/10/2010
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
local dat_folder_country "ECU/1998"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ECU_LSMS_1998_DWELLING.DTA", clear
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
label define wsource 1 "red publica" 2 "red publica y carro repartidor" 3 "pila o llave publica" ///
	4 "otra fuente por tuberia" 5 "carro repartidor/triciclo" 6 "pozo" 7 "rio, vertiente, o acequia" ///
	8 "agua lluvia" 9 "otro, cual"
label values vi18 wsource

label define ttype 1 "excusado y alcantarillado" 2 "excusado y pozo septico" 3 "excusado y pozo ciego" ///
	4 "letrina" 5 "no tiene"
label values vi13 ttype



** save
cd "`dat_folder_lsms_merged'"
save "ecuador_1998", replace
