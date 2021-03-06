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
local data_folder 			"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"
local dat_folder_new_mics 	"`data_folder'/MICS"

** open dataset and store data in a mata matrix
use "`dat_folder_new_mics'/datfiles_mics", clear
**keep if svyver == "2"
// save "`dat_folder_new_mics'/datfiles_mics", replace
mata: files=st_sdata(.,("location_name", "filedir", "filename", "svyver"))
local maxobs = _N

** create a vector for each of the variables of interest
local vars psu weight urban w_hwss w_barsoap w_liqsoap w_detergent w_water t_type
foreach var of local vars {
	mata: `var' = J(`maxobs', 1, "")
}

log using MICS.log, replace

** loop through survey files, looking for and saving relevant variables in each one
forvalues filenum = 1(1)`maxobs' {
	// save location_name and filename as locals, then print to keep track of position in the loop
	mata: st_local("location_name", files[`filenum', 1])
	mata: st_local("filedir", files[`filenum', 2])
	mata: st_local("filename", files[`filenum', 3])
	mata: st_local ("svyver", files[`filenum', 4])
	di _newline _newline "**********************************************************************************"
	di "location_name: `location_name'" _newline "filename: `filename'"
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
gen noinfo = (w_hwss=="" & w_barsoap=="" & w_liqsoap=="" & w_detergent=="" & w_water=="")
foreach var of local vars {
	replace `var' = "NOINFO" if noinfo == 1
}

drop if noinfo==1
	
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
	replace urban = "hi6a" if ihme_loc_id == "MDG" & startyear == "2000"
	replace urban = "hh6" if regexm(urban, "hh6")
	replace urban = "HH6" if regexm(urban, "HH6")
	bro urban if regexm(urban, " ")
		** still lacking urban for TTO 2000
		
	//w_hwss
	replace w_hwss = "HW1" if regexm(w_hwss, " HW1") 
	
	//w_barsoap
	replace w_barsoap = "HW3A" if regexm(w_barsoap, "HW3A") 
	replace w_barsoap = "HW3_A" if filename=="MNG_MICS4_2010_HH_Y2013M12D16.DTA"
	
	//w_liqsoap
	replace w_liqsoap = "HW3_B" if filename=="MNG_MICS4_2010_HH_Y2013M12D16.DTA"

	//w_detergent
	replace w_detergent = "HW3_C" if filename=="MNG_MICS4_2010_HH_Y2013M12D16.DTA"
	
	//w_water
	replace w_water = "HW2" if regexm(w_water, "HW2 ")
	
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
