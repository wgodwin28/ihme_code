// File Name: lookfor_vars_chns.do

// File Purpose: Look for appropriate variables in CHNS surveys
// Author: Leslie Mallinger
// Date: 5/21/10
// Edited on: 

// Additional Comments: 


clear all
set mem 500m
** set maxvar 6000
set more off
capture log close



** create locals for relevant files and folders
local dat_folder_new_chns "${data_folder}/CHNS"


** open dataset and store data in a mata matrix
use "`dat_folder_new_chns'/datfiles_chns", clear
mata: files=st_sdata(.,("countryname", "filedir", "filename"))
local maxobs = _N



** create a vector for each of the variables of interest
local vars psu weight urban w_srcedrnk t_type education electricity
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
		lookfor "primary sampling unit" "psu" "segment" "grappe" "province"
		mata: psu[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "cluster number" "upm"
			mata: psu[`filenum', 1] = "`r(varlist)'"
		}
		
		// sample weight
		lookfor "sample weight" "ponder" "poids" "household weight"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		
		// urban/rural
		lookfor "type of place of residence" "urban"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "area" "milieu" "urbrur"
			mata: urban[`filenum', 1] = "`r(varlist)'"
		}
		
		// source of drinking water
		lookfor "source of drinking water" "source of other drinking water"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "potable" "abastecimiento" "agua para beber"
			mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		}
		
		// type of toilet facility
		lookfor "type of toilet" "sanitario" "servicio higienico" "cuarto de" "fezes"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "toilet" "toilettes"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
		}
}


** move variables from Mata into Stata datset
use "`dat_folder_new_chns'/datfiles_chns", clear
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_chns'/varlist_temp_chns", replace	
	
	

** replace variables to mark surveys that are lacking both water and toilet information
use "`dat_folder_new_chns'/varlist_temp_chns", clear
gen noinfo = (t_type == "")
foreach var of local vars {
	replace `var' = "NOINFO" if noinfo == 1
}
	
	
** clean up entries with more than one variable listed
	// psu
	replace psu = "commid" if inlist(startyear, "1989", "1991")
	replace psu = "commid93" if startyear == "1993"
	replace psu = "commid97" if startyear == "1997"
	replace psu = "commid00" if startyear == "2000"
	replace psu = "commid04" if startyear == "2004"
	replace psu = "commid06" if startyear == "2006"
	bro psu if regexm(psu, " ")
		** FIXME
	
	// weight
	bro weight if regexm(weight, " ")
		** FIXME
	
	// urban
	bro urban if regexm(urban, " ")
		** FIXME

	// w_srcedrnk
	bro w_srcedrnk if regexm(w_srcedrnk, " ")
		** no missing entries
	
	// t_type
	bro t_type if regexm(t_type, " ")
		** no missing entries
		

** organize
compress


** save 
save "`dat_folder_new_chns'/varlist_chns", replace


capture log close