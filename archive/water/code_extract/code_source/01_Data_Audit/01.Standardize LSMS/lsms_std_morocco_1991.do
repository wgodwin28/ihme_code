// File Name: lsms_std_morocco_1991.do

// File Purpose: Create standardized dataset with desired variables from LSMS Morocco 1991 survey
// Author: Leslie Mallinger
// Date: 6/8/2010
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
local dat_folder_country "MAR/1991"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/MAR_LSMS_1991_HH_HOUSING.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** ident
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/MAR_LSMS_1991_HH_ILLNESS_AND_CONSULTATION.DTA", clear
	duplicates drop ident coefmen, force
	tempfile hhweight
	save `hhweight', replace
		** ident
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/SEC0A.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
use `hhweight', clear
merge 1:1 ident using `hhserv'
drop if _merge != 3
drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
label define wsource 1 "puits/source/metfia/duer" 2 "fontaine publique" 3 "vendeur d'eau" /// 
	4 "camion citerne" 5 "autre"
label values s02q40 wsource

label define ttype 1 "egout" 2 "fosse septique" 3 "fosse d'aisance du latrine" 4 "jetces dans la nature" ///
	5 "autres"
label values s02q33 ttype


** create urban/rural, wealth, PSU, and SSU variables from ident
tostring ident, replace
local expression ([0-9])([0-9])([0-9][0-9])([0-9])([0-9])

gen urban = regexs(1) if regexm(ident, "`expression'")
gen econregion = regexs(2) if regexm(ident, "`expression'")
gen psu = regexs(3) if regexm(ident, "`expression'")
gen ssu = regexs(4) if regexm(ident, "`expression'")
gen hnum = regexs(5) if regexm(ident, "`expression'")

destring urban econregion psu ssu hnum, replace

label define urban 1 "urban" 2 "rural"
label values urban urban


** save
cd "`dat_folder_lsms_merged'"
save "morocco_1991", replace
