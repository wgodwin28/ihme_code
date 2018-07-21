// File Name: lsms_std_tajikistan_2003.do

// File Purpose: Create standardized dataset with desired variables from LSMS Tajikistan 2003 survey
// Author: Leslie Mallinger
// Date: 7/9/2010
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
local dat_folder_country "TJK/2003"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/TJK_LSMS_2003_DWELLING_ASSETS.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** hhid
	
** household weights dataset
	use "`dat_folder_lsms'/`dat_folder_country'/TJK_LSMS_2003_EXPENDITURES.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** hhid
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/taj03dta1/module6", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hhid
	

** merge
use `hhweight', clear
merge 1:m hhid using `hhserv'
keep if _merge == 3
drop _merge
** merge 1:1 hhid using `hhpsu'
** keep if _merge == 3
** drop _merge


** apply labels
label variable m6bq1 "main source of water used by household"
label define wsource_nondrnk 1 "piped water inside dwelling" 2 "piped water outside dwelling" 3 "water truck" ///
	4 "public tap" 5 "spring or well" 6 "river, lake, pond, or similar" 7 "other"
label values m6bq1 wsource_nondrnk

label variable m6bq5 "main source good for drinking?"
label define drinking 1 "good for drinking" 2 "not good for drinking but good for other uses"
label values m6bq5 drinking

label variable m6bq6 "which water source does household use for drinking?"
label define wsource 1 "water truck" 2 "public tap" 3 "spring or well" 4 "river, lake, pond, or similar" ///
	5 "bottled water" 6 "other (specify)"
label values m6bq6 wsource

gen wsource = .
replace wsource = m6bq1 if m6bq5 == 1
replace wsource = 3 if m6bq6 == 1	// water truck
replace wsource = 4 if m6bq6 == 2	// public tap
replace wsource = 5 if m6bq6 == 3	// spring or well
replace wsource = 6 if m6bq6 == 4	// river, lake, pond, or similar
replace wsource = 7 if m6bq6 == 6	// other
replace wsource = 8 if m6bq6 == 5	// bottled water
label define wsource_new 1 "piped water inside dwelling" 2 "piped water outside dwelling" 3 "water truck" ///
	4 "public tap" 5 "spring or well" 6 "river, lake, pond, or similar" 7 "other" 8 "bottled water"
label values wsource wsource_new

label variable m6aq10 "type of toilet in dwelling"
label define ttype 1 "wc inside the house" 2 "two or more wc inside" 3 "wc outside, with piping" /// 
	4 "wc outside, without piping" 5 "no toilet in the house" 6 "other"
label values m6aq10 ttype


** save
cd "`dat_folder_lsms_merged'"
save "tajikistan_2003", replace
