// File Name: lookfor_vars_mics3.do

// File Purpose: Look for appropriate variables in MICS 3 surveys
// Author: Leslie Mallinger
// Date: 3/16/10
// Edited on: 1/3/2011 (updated to reflect new file paths)

// Additional Comments: 


clear all
set mem 500m
** set maxvar 6000
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_new_mics "${data_folder}/MICS"


** open dataset and store data in a mata matrix
use "`dat_folder_new_mics'/datfiles_mics", clear
keep if svyver == "3"
save "`dat_folder_new_mics'/datfiles_mics3", replace
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
		lookfor "psu" "cluster" "grappe" "conglomerado" "numero du site" "aglomerado" "segmento" ///
			"enumer"
		mata: psu[`filenum', 1] = "`r(varlist)'"
		
		// sample weight
		lookfor "sample weight" "household weight" "pondération ménage" "ponderación hogar" ///
			"poids" "hhweight" "household sample weight"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		
		// urban/rural
		lookfor "urban" "milieu" "area" "zona" "classification" "place of residence" /// 
			"lugar de residencia" "urbain" "mileu" "residence"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		
		// source of drinking water
		lookfor "source of drinking water" "source principale eau" "fonte de água" /// 
			"source of water" "source d'eau" "fuente de agua" "abastecimento de água" /// 
			"abastecimiento de agua" "principale source" "fuente principal de agua" ///
			"principal fonte de abastecimento"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		** if "`r(varlist)'" == "" {
			** lookfor "source of drinking water" "source principale eau" "fonte de água" /// 
				** "source of water" "source d'eau" "fuente de agua" "abastecimento de água" /// 
				** "abastecimiento de agua"
			** mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		** }
		
		// type of toilet facility
		lookfor "type of toilet" "kind of toilet" "type de toilette" "tipo de toilet" "banho"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		** if "`r(varlist)'" == "" {
			** lookfor "type of toilet" "kind of toilet" "type de toilette" "toilet" "toilettes" /// 
				** "servicio sanitario" "toillettes"
			** mata: t_type[`filenum', 1] = "`r(varlist)'"
		** }
}


** move variables from Mata into Stata datset
use "`dat_folder_new_mics'/datfiles_mics", clear
keep if svyver == "3"
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_mics'/varlist_temp_mics3", replace	
	
** replace variables to mark surveys that are lacking both water and toilet information	
use "`dat_folder_new_mics'/varlist_temp_mics3", clear
** gen noinfo = (w_srcedrnk == "")
** foreach var of local vars {
	** replace `var' = "NOINFO" if noinfo == 1
** }
	
	
** clean up entries with more than one variable listed
	// psu
	replace psu = "hh1" if regexm(psu, "hh1")
	bro psu if regexm(psu, " ")
		** not lacking any entries
	
	// weight
	replace weight = "hhweight" if regexm(weight, "hhweight")
	bro weight if regexm(weight, " ")
		** not lacking any entries
	
	// urban
	replace urban = "hh6" if regexm(urban, "hh6")
	replace urban = "HH6" if regexm(urban, "HH6")
	replace urban = "milieu" if iso3 == "BFA" & startyear == "2006"
	replace urban = "" if iso3 == "SRB" & startyear == "2005"
	bro urban if regexm(urban, " ")
		** lacking entries for SRB 2005, SUR 2006, TTO 2006
	
	// w_srcedrnk
	replace w_srcedrnk = "ws1" if regexm(w_srcedrnk, "ws1")
	replace w_srcedrnk = "WS1" if regexm(w_srcedrnk, "WS1")
	bro w_srcedrnk if regexm(w_srcedrnk, " ")
		** not lacking any entries
	
	// t_type
	replace t_type = "ws7" if regexm(t_type, "ws7")
	replace t_type = "WS7" if regexm(t_type, "WS7")
	bro t_type if regexm(t_type, " ")
		** not lacking any entries
	
	
** save 
compress
save "`dat_folder_new_mics'/varlist_mics3", replace
