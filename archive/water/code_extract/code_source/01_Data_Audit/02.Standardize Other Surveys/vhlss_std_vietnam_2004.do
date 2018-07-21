// File Name: vhlss_std_vietnam_2004.do

// File Purpose: Create standardized dataset with desired variables from VHLSS Vietnam 2004 survey
// Author: Leslie Mallinger
// Date: 6/21/2010
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}/02.Standardize Other Surveys"
local dat_folder "J:\DATA\WB_LSMS"
local dat_folder_other_merged "${data_folder}/Other/Merged Original Files"
local codes_folder "J:/Usable/Common Indicators/Country Codes"
local dat_folder_country "VNM\2004"



** water, sanitation dataset
	use "`dat_folder'/`dat_folder_country'/VNM_LSMS_2004_HH_HOUSING_Y2011M01D10.DTA", clear
	tempfile hhserv
	save `hhserv', replace
		** tinh huyen xa diaban
	
** household weights dataset
	use "`dat_folder'/`dat_folder_country'/VNM_LSMS_2004_WGHTS_1.DTA", clear
	tempfile hhweight
	save `hhweight', replace
		** tinh huyen xa diaban
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/za94cdta/STRATA2", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** nh and clust
	

** merge
use `hhweight', clear
merge 1:m tinh huyen xa diaban using `hhserv'
drop if _merge != 3
drop _merge
** merge 1:1 nh clust using `hhpsu'
** drop _merge


** apply labels
label define w_source 1 "private tap water" 2 "public tap water" 3 "bought water (in tank, bottle)" ///
	4 "filtered spring water" 5 "rain water" 6 "water pumped from deep drill wells" ///
	7 "water from hand-dug and reinforcement wells" 8 "water from hand-dug, non-reinforced and covered wells" ///
	9 "water from hand-dug, non-reinforced and uncovered wells" 10 "rivers, lakes, ponds" 11 "others (specify)"
label values m7c26 w_source
label variable m7c26 "main source of cooking/drinking water in household (wsource)"

replace m7c33 = . if m7c33 == 9
label define ttype 1 "flush toilet with septic tank/sewage pipes" 2 "suilabh" 3 "double vault compost latrine" ///
	4 "toilet directly over the water" 5 "others" 6 "no toilet"
label values m7c33 ttype
label variable m7c33 "what type of latrine does your household have? (type of toilet)"


** save
cd "`dat_folder_other_merged'"
save "vhlss_vietnam_2004", replace


capture log close