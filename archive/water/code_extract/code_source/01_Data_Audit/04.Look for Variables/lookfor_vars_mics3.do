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
local dat_folder_new_mics "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/MICS"


** open dataset and store data in a mata matrix
use "`dat_folder_new_mics'/datfiles_mics", clear
keep if svyver == "3"
save "`dat_folder_new_mics'/datfiles_mics3", replace
mata: files=st_sdata(.,("countryname", "filedir", "filename"))
local maxobs = _N


** create a vector for each of the variables of interest
local vars hhid strata psu weight urban w_srcedrnk w_filter w_boil w_bleach w_solar t_type shared_san w_hwss w_barsoap w_liqsoap w_detergent w_water
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
		
		// household id
		lookfor "hid"
		mata: hhid[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "household identification" "hhid"
		}

		// strata
		lookfor "hi7"
		mata: strata[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "strata" "stratum" "local government area"
			mata: strata[`filenum', 1] = "`r(varlist)'"
		}

		// primary sampling unit
		lookfor "psu" "cluster" "grappe" "conglomerado" "numero du site" "aglomerado" "segmento" ///
			"enumer"
		mata: psu[`filenum', 1] = "`r(varlist)'"
		
		// sample weight
		lookfor "sample weight" "household weight" "pond�ration m�nage" "ponderaci�n hogar" ///
			"poids" "hhweight" "household sample weight"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		
		// urban/rural
		lookfor "urban" "milieu" "area" "zona" "classification" "place of residence" /// 
			"lugar de residencia" "urbain" "mileu" "residence"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		
		// source of drinking water
		lookfor "source of drinking water" "source principale eau" "fonte de �gua" /// 
			"source of water" "source d'eau" "fuente de agua" "abastecimento de �gua" /// 
			"abastecimiento de agua" "principale source" "fuente principal de agua" ///
			"principal fonte de abastecimento"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		** if "`r(varlist)'" == "" {
			** lookfor "source of drinking water" "source principale eau" "fonte de �gua" /// 
				** "source of water" "source d'eau" "fuente de agua" "abastecimento de �gua" /// 
				** "abastecimiento de agua"
			** mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		** }
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
		lookfor "type of toilet" "kind of toilet" "type de toilette" "tipo de toilet" "banho"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		** if "`r(varlist)'" == "" {
			** lookfor "type of toilet" "kind of toilet" "type de toilette" "toilet" "toilettes" /// 
				** "servicio sanitario" "toillettes"
			** mata: t_type[`filenum', 1] = "`r(varlist)'"
		** }
		// shared sanitation
		lookfor "shared"
		mata: shared_san[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "ws8" "WS8" "partagez" "compart" "share"
			mata: shared_san[`filenum', 1] = "`r(varlist)'"
		}

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
		lookfor "HW3A"
		mata: w_barsoap[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "Bar soap" "Liquid soap" "Detergent (Powder / Liquid / Paste)"
			mata: w_barsoap [`filenum', 1] = "`r(varlist)'"
		}
		
		//liquid soap
		lookfor "HW3B" 
		mata: w_liqsoap[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "Liquid soap" 
			mata: w_liqsoap [`filenum', 1] = "`r(varlist)'"
		}
		
		//detergent (Powder/liquid/Paste)
		lookfor "HW3C"
		mata: w_detergent[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "Detergent (Powder / Liquid / Paste)"
			mata: w_detergent [`filenum', 1] = "`r(varlist)'"
		}
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
