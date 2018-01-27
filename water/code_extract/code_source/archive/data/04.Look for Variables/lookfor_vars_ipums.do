// File Name: lookfor_vars_ipums.do

// File Purpose: Look for appropriate variables in IPUMS censuses
// Author: Leslie Mallinger
// Date: 7/11/2011
// Edited on: 

// Additional Comments: 


clear all
set mem 1000m
set maxvar 10000
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local dat_folder_new_ipums "${data_folder}/IPUMS"


** open dataset and store data in a mata matrix
use "`dat_folder_new_ipums'/datfiles_ipums", clear
mata: files=st_sdata(.,("countryname", "filedir", "filename", "startyear"))
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
	mata: st_local("startyear", files[`filenum', 4])
	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'" _newline "year: `startyear'" _newline "filename: `filename'"
	di "**********************************************************************************"
	
	// open file (only first 50 observations for speed)
	use "`filedir'/`filename'" if _n < 50, clear
	
	** look for variables of interest and save in appropriate vector
		// primary sampling unit
		lookfor "primary sampling unit" "psu" "segment" "grappe"
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
			lookfor "area"
			mata: urban[`filenum', 1] = "`r(varlist)'"
		}
		
		// source of drinking water
		lookfor "watsrc" "watsup"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		
		// type of toilet facility
		lookfor "sewage" "toilet"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
}


** move variables from Mata into Stata datset
use "`dat_folder_new_ipums'/datfiles_ipums", clear
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_ipums'/varlist_temp_ipums", replace


use "`dat_folder_new_ipums'/varlist_temp_ipums", clear	// FIXME remove this line eventually	
** replace variables to mark surveys that are lacking both water and toilet information

** gen noinfo = 0
** replace noinfo = 1 if (iso3 == "GHA" & startyear == 2007) | (iso3 == "COL" & startyear == 2009)
	** // variables but not labels for COL 2009
** gen noinfo = (w_srcedrnk == "")

** foreach var of local vars {
	** replace `var' = "NOINFO" if noinfo == 1
** }
	
	
** clean up entries with more than one variable listed
	// psu
	bro psu if regexm(psu, " ")
		** no psu variable
		
	// weight
	bro weight if regexm(weight, " ")
	
	// urban
	replace urban = "urban" if regexm(urban, "urban")
	bro urban if regexm(urban, " ")
		** lacking urban for 21/136 entries
	
	// w_srcedrnk
	replace w_srcedrnk = subinstr(w_srcedrnk, "_watsrc", "wsrc", .)
	replace w_srcedrnk = subinstr(w_srcedrnk, "_watsup", "wsup", .)
	replace w_srcedrnk = "watsrc" if regexm(w_srcedrnk, "watsrc")
	replace w_srcedrnk = "watsup" if regexm(w_srcedrnk, "watsup")
	replace w_srcedrnk = "" if iso3 == "FRA"
	replace w_srcedrn = "" if ! regexm(w_srcedrnk, "watsrc") &! regexm(w_srcedrnk, "watsup")
	bro w_srcedrnk if regexm(w_srcedrnk, " ")
		** lacking entry for GBR 1991
	
	// t_type
	replace t_type = subinstr(t_type, "_toilet", "_toi", .)
	replace t_type = subinstr(t_type, "_sewage", "_sew", .)
	
	replace t_type = "sewage toilet" if regexm(t_type, "sewage") & regexm(t_type, "toilet")
	replace t_type = "sewage" if regexm(t_type, "sewage") &! regexm(t_type, "toilet")
	replace t_type = "toilet" if regexm(t_type, "toilet") &! regexm(t_type, "sewage")
	bro t_type if regexm(t_type, " ")
		** not lacking any entries


** organize
compress


** save 
save "`dat_folder_new_ipums'/varlist_ipums", replace


capture log close