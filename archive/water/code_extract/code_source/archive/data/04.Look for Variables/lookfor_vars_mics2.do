// File Name: lookfor_vars_mics2.do

// File Purpose: Look for appropriate variables in MICS 2 surveys
// Author: Leslie Mallinger
// Date: 3/12/10
// Edited on: 1/3/2011 (updated to reflect new file paths)

// Additional Comments: 


clear all
set mem 500m
** set maxvar 6000
set more off
capture log close


** create locals for relevant files and folders
local dat_folder_new_mics "${data_folder}/MICS"


** open dataset and store data in a mata matrix
use "`dat_folder_new_mics'/datfiles_mics", clear
keep if svyver == "2"
save "`dat_folder_new_mics'/datfiles_mics2", replace
mata: files=st_sdata(.,("countryname", "filedir", "filename"))
local maxobs = _N


** create a vector for each of the variables of interest
local vars psu weight urban w_srcedrnk t_type
foreach var of local vars {
	mata: `var' = J(`maxobs', 1, "")
}


** loop through survey files, looking for and saving relevant variables in each one
forvalues filenum = 1(1)`maxobs' {
	// save countryname and filename as locals, then print to keep track of position in the loop
	mata: st_local("countryname", files[`filenum', 1])
	mata: st_local("filedir", files[`filenum', 2])
	mata: st_local("filename", files[`filenum', 3])
	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'" _newline "filename: `filename'"
	di "**********************************************************************************"
	
	// open file (only first 50 observations for speed), then lookfor variables of interest and save in appropriate vector
	use "`filedir'/`filename'" if _n < 50, clear
	
		// primary sampling unit
		lookfor "psu" "cluster" "grappe" "conglomerado" "numero du site" "aglomerado" "segmento"
		mata: psu[`filenum', 1] = "`r(varlist)'"
		
		// sample weight
		lookfor "weight"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		
		// urban/rural
		lookfor hi6
		mata: urban[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "urban" "milieu" "area" "zona" "classification" "place of residence" /// 
				"lugar de residencia" "urbain"
			mata: urban[`filenum', 1] = "`r(varlist)'"
		}
		
		// source of drinking water
		lookfor ws1
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "source of drinking water" "source principale eau" "fonte de água" /// 
				"source of water" "source d'eau" "fuente de agua" "abastecimento de água" /// 
				"abastecimiento de agua"
			mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		}
		
		// type of toilet facility
		lookfor ws3
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "type of toilet" "kind of toilet" "type de toilette" "toilet" "toilettes" /// 
				"servicio sanitario" "toillettes"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
		}
}


** move variables from Mata into Stata datset
use "`dat_folder_new_mics'/datfiles_mics", clear
keep if svyver == "2"
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_mics'/varlist_temp_mics2", replace	
	

** replace variables to mark surveys that are lacking both water and toilet information	
use "`dat_folder_new_mics'/varlist_temp_mics2", clear
gen noinfo = (w_srcedrnk == "")
foreach var of local vars {
	replace `var' = "NOINFO" if noinfo == 1
}
	
	
** clean up entries with more than one variable listed
	// psu
	replace psu = "hi1" if regexm(psu, "hi1")
	bro psu if regexm(psu, " ")
		** still lacking psu for GUY 2000, JAM 2000
	
	// weight
	replace weight = "hhweight" if regexm(weight, "hhweight")
	bro weight if regexm(weight, " ")
		** still lacking weight for LSO 2000
	
	// urban
	replace urban = "hi6" if regexm(urban, "hi6")
	replace urban = "hi6a" if iso3 == "MDG" & startyear == "2000"
	bro urban if regexm(urban, " ")
		** still lacking urban for TTO 2000
	
	// w_srcedrnk
	replace w_srcedrnk = "ws1" if regexm(w_srcedrnk, "ws1")
	bro w_srcedrnk if regexm(w_srcedrnk, " ")
	
	// t_type
	replace t_type = "ws3" if regexm(t_type, "ws3")
	bro t_type if regexm(t_type, " ")


** save 
compress
save "`dat_folder_new_mics'/varlist_mics2", replace
