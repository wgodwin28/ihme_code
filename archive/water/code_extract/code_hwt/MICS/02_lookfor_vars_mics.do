// File Name: lookfor_vars_mics.do

// File Purpose: Look for appropriate variables in MICS surveys
// Author: Leslie Mallinger
// Date: 3/12/10
// Edited on: 1/3/2011 (updated to reflect new file paths)
//Edited on: 1/26/2013 to extract data on new variables for water and sanitation: 1) filter use ; 2) sewer connection/flush toilet 

// Additional Comments: 
clear all
set more off
capture log close

** create locals for relevant files and folders
local data_folder "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/data"
local dat_folder_new_mics "`data_folder'/MICS"

** open dataset and store data in a mata matrix
use "`dat_folder_new_mics'/datfiles_mics", clear
**keep if svyver == "2"
save "`dat_folder_new_mics'/datfiles_mics", replace
mata: files=st_sdata(.,("countryname", "filedir", "filename", "svyver"))
local maxobs = _N

** create a vector for each of the variables of interest
local vars psu weight urban w_srcedrnk w_filter w_boil w_bleach w_solar t_type
foreach var of local vars {
	mata: `var' = J(`maxobs', 1, "")
}

log using MICS.log, replace

** loop through survey files, looking for and saving relevant variables in each one
forvalues filenum = 1(1)`maxobs' {
	// save countryname and filename as locals, then print to keep track of position in the loop
	mata: st_local("countryname", files[`filenum', 1])
	mata: st_local("filedir", files[`filenum', 2])
	mata: st_local("filename", files[`filenum', 3])
	mata: st_local ("svyver", files[`filenum', 4])
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
		
		//source of drinking water
		lookfor "ws1" 
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "main source of drinking water"
			mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		}
		
		// filter use 
		lookfor "water filter" "filter"  
		mata: w_filter[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "ws6d" "WS7D" 
			mata: w_filter [`filenum', 1] = "`r(varlist)'"
		}
		
		// boil water
		lookfor "water boil" "boil"
		mata: w_boil[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "ws6a" "WS7A"
			mata: w_boil [`filenum', 1] = "`r(varlist)'"
		}
		
		//chlorine/bleach
		lookfor "Add bleach/chlorine"
		mata: w_bleach[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "ws6b" "WS7B"
			mata: w_bleach [`filenum', 1] = "`r(varlist)'"
		}
		
		//solar
		lookfor "Solar disinfection"
		mata: w_solar[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "ws6e" "WS7E"
			mata: w_solar [`filenum', 1] = "`r(varlist)'"
		}
		
		// type of toilet facility
		lookfor "kind of toilet facility" "type of toilet" "kind of toilet" "type de toilette" "toilet" "toilettes" /// 
				"servicio sanitario" "toillettes" "tipo de toilet" "banho"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" & "`svyver'"=="4" {
			lookfor "ws8"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
		}
		if "`r(varlist)'" == "" & "`svyver'"=="3" {
			lookfor "ws7" "WS7"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
		}
		if "`r(varlist)'" == "" & "`svyver'"=="2" {
			lookfor "ws3"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
		}
}


** move variables from Mata into Stata datset
use "`dat_folder_new_mics'/datfiles_mics", clear
**keep if svyver == "2"
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_mics'/varlist_temp_mics", replace	
	
** replace variables to mark surveys that are lacking both water and toilet information	
use "`dat_folder_new_mics'/varlist_temp_mics", clear
gen noinfo = (w_filter == "" & w_boil == "" & w_solar == "" & w_bleach == "")
foreach var of local vars {
	replace `var' = "NOINFO" if noinfo == 1
}
	
** clean up entries with more than one variable listed
	// psu
	replace psu = "hi1" if regexm(psu, "hi1")
	replace psu = "psu" if regexm(psu, "psu")
	replace psu = "hh1" if regexm(psu, "hh1")
	bro psu if regexm(psu, " ")
		** still lacking psu for GUY 2000, JAM 2000
	
	// weight
	replace weight = "hhweight" if regexm(weight, "hhweight")
	bro weight if regexm(weight, " ")
		** still lacking weight for LSO 2000
	
	// urban
	replace urban = "hi6" if regexm(urban, "hi6")
	replace urban = "hi6a" if iso3 == "MDG" & startyear == "2000"
	replace urban = "hh6" if regexm(urban, "hh6")
	replace urban = "HH6" if regexm(urban, "HH6")
	bro urban if regexm(urban, " ")
		** still lacking urban for TTO 2000
	
	//w_srcedrnk 
	replace w_srcedrnk = "ws1" if regexm(w_srcedrnk, "ws1 ")
	replace w_srcedrnk = "WS1" if regexm(w_srcedrnk, "WS1 ")
	
	//w_filter
	replace w_filter = "ws6d" if regexm(w_filter, "ws6d")
	replace w_filter = "WS7D" if regexm(w_filter, "WS7D")
	replace w_filter = "" if iso3=="AZE"  /*ws6d is not the right variable in this survey*/
	replace w_filter = "" if iso3=="VNM" & startyear=="2000"
	
	//w_boil
	replace w_boil = "ws6a" if regexm(w_boil, "ws6a")
	replace w_boil = "WS7A" if regexm(w_boil, "WS7A")
	replace w_boil = "" if iso3=="AZE" /*ws6d is not the right variable in this survey*/
	replace w_boil = "" if iso3=="VNM" & startyear=="2000"
	
	//w_bleach
	replace w_bleach = "ws6b" if regexm(w_bleach, "ws6b")
	
	//w_solar
	
	// t_type
	replace t_type = "ws8" if (regexm(t_type, "ws8") & svyver=="4") 
	replace t_type = "WS8" if (regexm(t_type, "WS8") & svyver=="4")
	replace t_type = "ws7" if (regexm(t_type, "ws7") & svyver=="3") 
	replace t_type = "WS7" if (regexm(t_type, "WS7") & svyver=="3")
	replace t_type = "ws3" if (regexm(t_type, "ws3") & svyver=="2") 
	replace t_type = "WS3" if (regexm(t_type, "WS3") & svyver=="2")
	replace t_type = "ectoilfl" if regexm(t_type, "ectoilfl")
	bro t_type if regexm(t_type, " ")

** save 
	compress
	save "`dat_folder_new_mics'/varlist_mics", replace
