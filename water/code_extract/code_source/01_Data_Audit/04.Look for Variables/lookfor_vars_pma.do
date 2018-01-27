// File Name: lookfor_vars_pma.do

// File Purpose: Look for appropriate variables in pma surveys
// Author: Leslie Mallinger
// Date: 3/2/10 - 3/13/10
// Edited on: 6/6/2016

// Additional Comments: 


clear all
set mem 2000m
set maxvar 10000
set more off
capture log close


** create locals for relevant files and folders
local dat_folder_new_pma "J:\WORK\01_covariates\02_inputs\water_sanitation\data\01_Data_Audit/pma"


** open dataset and store data in a mata matrix
use "`dat_folder_new_pma'/datfiles_pma", clear
mata: files=st_sdata(.,("location_name", "filedir", "filename"))
local maxobs = _N


** create a vector for each of the variables of interest
local vars psu weight urban w_srcedrnk t_type education electricity
foreach var of local vars {
	mata: `var' = J(`maxobs', 1, "")
}

** loop through survey files, looking for and saving relevant variables in each one
forvalues filenum = 1(1)`maxobs' {
	// save location_name and filename as locals, then print to keep track of position in the loop
	mata: st_local("location_name", files[`filenum', 1])
	mata: st_local("filedir", files[`filenum', 2])
	mata: st_local("filename", files[`filenum', 3])
	di _newline _newline "**********************************************************************************"
	di "location_name: `location_name'" _newline "filename: `filename'"
	di "**********************************************************************************"
	
	// open file (only first 50 observations for speed)
	use "`filedir'/`filename'" if _n < 50, clear
	
	** look for variables of interest and save in appropriate vector
		// primary sampling unit
		lookfor "hv021"
		mata: psu[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "primary sampling unit" "psu" "segment" "grappe"
			mata: psu[`filenum', 1] = "`r(varlist)'"
			if "`r(varlist)'" == "" {
				lookfor "cluster number" "upm"
				mata: psu[`filenum', 1] = "`r(varlist)'"
			}
		}
		
		// sample weight
		lookfor "hv005"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "sample weight" "ponder" "poids" "household weight"
			mata: weight[`filenum', 1] = "`r(varlist)'"
		}
		
		// urban/rural
		lookfor "hv025"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "type of place of residence" "urban"
			mata: urban[`filenum', 1] = "`r(varlist)'"
			if "`r(varlist)'" == "" {
				lookfor "area" "milieu"
				mata: urban[`filenum', 1] = "`r(varlist)'"
			}
		}
			
		// source of drinking water
		lookfor "main_drinking_rc"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "main source of drinking water"
			mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
			if "`r(varlist)'" == "" {
				lookfor "potable" "abastecimiento" "agua para beber"
				mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
			}
		}
		
		// type of toilet facility
		lookfor "sanitation_main_rc"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "sanitation_main"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
			if "`r(varlist)'" == "" {
				lookfor "toilet" "toilettes"
				mata: t_type[`filenum', 1] = "`r(varlist)'"
			}
		}
		
		// education
		lookfor "hv108_01"
		mata: education[`filenum', 1] = "`r(varlist)'"
		
		// electricity
		lookfor "hv206"
		mata: electricity[`filenum', 1] = "`r(varlist)'"
}

** move variables from Mata into Stata datset
use "`dat_folder_new_pma'/datfiles_pma", clear
getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_pma'/varlist_temp_pma", replace
	

** mark surveys that are lacking both water and toilet information
use "`dat_folder_new_pma'/varlist_temp_pma", clear

gen noinfo = (w_srcedrnk == "" & t_type == "")
foreach var of local vars {
	replace `var' = "NOINFO" if noinfo == 1
}

** organize
compress


** save 
save "`dat_folder_new_pma'/varlist_pma", replace

