// File Name: lookfor_vars_whs.do

// File Purpose: Look for appropriate variables in WHS surveys
// Author: Leslie Mallinger
// Date: 5/25/10 (modified from "J:\Project\COMIND\Water and Sanitation\Data Audit\Code\lookfor_vars_whs.do")
// Edited on:

// Additional Comments: 


clear all
set mem 500m
** set maxvar 6000
set more off
capture log close


** create locals for relevant files and folders
local dat_folder_new_whs "${data_folder}/WHS"


** open dataset and store data in a mata matrix
use "`dat_folder_new_whs'/datfiles_whs", clear
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
		lookfor "primary sampling unit" "psu" "region" "grappe"
		mata: psu[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "cluster number" "upm" "primaria" "segment"
			mata: psu[`filenum', 1] = "`r(varlist)'"
		}
		
		// sample weight
		lookfor "sample weight" "pesomef" "poids" "household weight"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "weight" "ponder" "peso"
			mata: weight[`filenum', 1] = "`r(varlist)'"
		}
		
		// urban/rural
		lookfor "type of place of residence" "urban" "area"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "milieu" "urbrur"
			mata: urban[`filenum', 1] = "`r(varlist)'"
		}
		
		// source of drinking water
		lookfor "drinking water" "fuente principal" "donde obtienen agua"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "potable" "abastecimiento" "agua para beber" "agua beber" "servicio de agua" /// 
				"obtiene el agua" "tipo de agua"
			mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
			if "`r(varlist)'" == "" {
				lookfor "water" "agua" "eau"
				mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
			}
		}
		
		// type of toilet facility
		lookfor "type of toilet" "sanitario" "servicio higienico" "cuarto de" "fezes"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "toilet" "toilettes" "higi�nico" "desague de aguas servidas"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
		}
}


** move variables from Mata into Stata datset
use "`dat_folder_new_whs'/datfiles_whs", clear
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_whs'/varlist_temp_whs", replace	
	

** replace variables to mark surveys that are lacking both water and toilet information	
use "`dat_folder_new_whs'/varlist_temp_whs", clear
gen noinfo = (w_srcedrnk == "")
foreach var of local vars {
	replace `var' = "NOINFO" if noinfo == 1
}
	
	
** clean up entries with more than one variable listed
	// psu
	bro psu if regexm(psu, " ")
		** not missing any entries
	
	// weight
	replace weight = "HHweight" if regexm(weight, "HHweight")
	replace weight = "" if (iso3 == "GTM" & startyear == "2003") | (iso3 == "SVN" & startyear == "2003")
	bro weight if regexm(weight, " ")
		** missing entries for GTM 2003, SVN 2003
	
	** // urban
	** replace urban = "area" if regexm(urban, "area")
	** replace urban = "strata" if _n == 1 | _n == 18
	** replace urban = "mharea" if _n == 14
	** replace urban = "estrato" if _n == 15
	** replace urban = "" if _n == 3 | _n == 23
	** bro urban if regexm(urban, " ")
		** ** FIXME

	// w_srcedrnk
	bro w_srcedrnk if regexm(w_srcedrnk, " ")
		** no missing entries
	
	// t_type
	bro t_type if regexm(t_type, " ")
		** no missing entries

		
** save 
compress
save "`dat_folder_new_whs'/varlist_whs", replace
