// File Name: lookfor_vars_mics5.do

// File Purpose: Look for appropriate variables in MICS 5 surveys
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
local dat_folder_new_mics "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/MICS"

** open dataset and store data in a mata matrix
use "`dat_folder_new_mics'/datfiles_mics", clear
// keep if svyver == "5"
// save "`dat_folder_new_mics'/datfiles_mics5", replace
mata: files=st_sdata(.,("countryname", "filedir", "filename", "svyver"))
local maxobs = _N


** create a vector for each of the variables of interest
local vars hhid strata psu weight urban w_srcedrnk w_other w_treat w_filter w_boil w_bleach w_solar t_type shared_san shared_num w_hwss w_barsoap w_liqsoap w_detergent w_water
foreach var of local vars {
	mata: `var' = J(`maxobs', 1, "")
}


** loop through survey files, looking for and saving relevant variables in each one
forvalues filenum = 1(1)`maxobs' {
	// save countryname and filename as locals, then print to keep track of position in the loop
	mata: st_local("countryname", files[`filenum', 1])
	mata: st_local("filedir", files[`filenum', 2])
	mata: st_local("filename", files[`filenum', 3])
	mata: st_local("svyver", files[`filenum', 4])
	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'" _newline "filename: `filename'"
	di "**********************************************************************************"
	
	// open file (only first 50 observations for speed), then lookfor variables of interest and save in appropriate vector
	use "`filedir'/`filename'" if _n < 50, clear
		// household id
		lookfor "household number" "cluster number"
		mata: hhid[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "hh1" "hh2" "household identification" "hhid" "household number"
		}

		// strata
		lookfor "stratum"
		mata: strata[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "hi7" "strata" "local government area"
			mata: strata[`filenum', 1] = "`r(varlist)'"
		}
		
		// primary sampling unit
		lookfor "psu" 
		mata: psu[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "cluster" "grappe" "conglomerado" "numero du site" "aglomerado" "segmento" "enumer"
			mata: psu[`filenum', 1] = "`r(varlist)'"
		}
		// sample weight
		lookfor "sample weight" "household weight" "pondération ménage" "ponderación hogar" ///
			"poids" "hhweight" "household sample weight"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		
		// urban/rural
		lookfor "HH6" "area"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "urban" "milieu" "area" "zona" "classification" "place of residence" /// 
				"lugar de residencia" "urbain" "mileu" "residence"
			mata: urban[`filenum', 1] = "`r(varlist)'"
		}
		
		// source of drinking water
		lookfor "main source of drinking water"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "source principale eau" "fonte de água" /// 
				"source of water" "source d'eau" "fuente de agua" "abastecimento de água" /// 
				"abastecimiento de agua" "principale source" "fuente principal de agua" ///
				"principal fonte de abastecimento" "Source principale d'eau potable" ///
				"Fuente principal de agua potable"		
			mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		}

		// water for other purposes
		lookfor "other purposes"
		mata: w_other[`filenum', 1] = "`r(varlist)'"

		// treatment gateway question- in order to have correct value for total proportion using treatment to use as denominator
		if "`svyver'" == "3" {
		lookfor "ws5" "WS5"
		mata: w_treat[`filenum', 1] = "`r(varlist)'"
		}

		if "`svyver'" == "5" | "`svyver'" == "4" {
		lookfor "ws6" "WS6"
		mata: w_treat[`filenum', 1] = "`r(varlist)'"
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
		lookfor "WS8" "type of toilet" "ws8"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
		lookfor "kind of toilet facility" "type of toilet" "kind of toilet" "type de toilette" "toilet" "toilettes" /// 
				"servicio sanitario" "toillettes" "tipo de toilet" "banho"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
		}
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

		// shared sanitation
		lookfor "WS9" "toilet facility shared"
		mata: shared_san[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "ws8" "WS8" "partagez" "compart" "share"
			mata: shared_san[`filenum', 1] = "`r(varlist)'"
		}
		
		// number of HH using facility
		lookfor "households using"
		mata: shared_num[`filenum', 1] = "`r(varlist)'"

		//handwashing station 
		lookfor "HW1"
		mata: w_hwss[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "Place where household members most often wash their hands"
			mata: w_hwss[`filenum', 1] = "`r(varlist)'"
		}
		
		//water at handwashing station
		lookfor "HW2" 
		mata: w_water[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "Water available at the place for handwashing"
			mata: w_water [`filenum', 1] = "`r(varlist)'"
		}
		
		//bar soap at handwashing station
		lookfor "HW3BA"
		mata: w_barsoap[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "Bar soap" "Liquid soap" "Detergent (Powder / Liquid / Paste)"
			mata: w_barsoap [`filenum', 1] = "`r(varlist)'"
		}
		
		//liquid soap
		lookfor "HW3BC" 
		mata: w_liqsoap[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "Liquid soap" 
			mata: w_liqsoap [`filenum', 1] = "`r(varlist)'"
		}
		
		//detergent (Powder/liquid/Paste)
		lookfor "HW3BB"
		mata: w_detergent[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "Detergent" "(Powder / Liquid / Paste)"
			mata: w_detergent [`filenum', 1] = "`r(varlist)'"
		}
}

** move variables from Mata into Stata datset
use "`dat_folder_new_mics'/datfiles_mics", clear
keep if svyver == "5"
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
replace w_srcedrnk = "WS1" if w_srcedrnk == "WS1 WS2 WS3"
replace urban = "HH6" if urban != "HH6"
save "`dat_folder_new_mics'/varlist_temp_mics5", replace	
	