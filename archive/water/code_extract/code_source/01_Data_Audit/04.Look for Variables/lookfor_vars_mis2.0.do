// File Name: lookfor_vars_mis.do

// File Purpose: Look for appropriate variables in MIS surveys
// Author: Leslie Mallinger
// Date: 6/16/10
// Edited on: 1/4/2011 (updated to reflect new file paths)

// Additional Comments: 


clear all
set mem 700m
set maxvar 8000
set more off
capture log close


** create locals for relevant files and folders
local dat_folder_new_mis "J:\WORK\01_covariates\02_inputs\water_sanitation\data\01_Data_Audit\MIS"


** open dataset and store data in a mata matrix
use "`dat_folder_new_mis'/datfiles_mis", clear
// drop if filename == "KEN_MIS_2010_HH_IDENTIFICATION_Y2014M04D11.DTA" | filename == "KEN_MIS_2010_HH_SCHEDULE_Y2014M04D11.DTA"
mata: files=st_sdata(.,("countryname", "filedir", "filename"))
local maxobs = _N


** create a vector for each of the variables of interest
local vars hhid strata psu weight urban region w_srcedrnk w_srcedrnk_other mins_ws w_treat w_filter w_boil w_bleach w_solar t_type shared_san w_hwss w_soap w_water cooking_fuel
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
		lookfor "hhid"
		mata: hhid[`filenum', 1] = "`r(varlist)'"

		// strata
		lookfor "sample stratum number"
		mata: strata[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "strata" "stratum"
			mata: strata[`filenum', 1] = "`r(varlist)'"
		}
		// primary sampling unit
		lookfor "psu" "cluster" "grappe" "conglomerado" "numero du site" "aglomerado" "segmento"
		mata: psu[`filenum', 1] = "`r(varlist)'"
		
		// sample weight
		lookfor "sample weight"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		
		// urban/rural
		lookfor "urban" "milieu" "area" "zona" "classification" "place of residence" /// 
			"lugar de residencia" "urbain" "mileu" "residence"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		
		// region
		lookfor "region"
		mata: region[`filenum', 1] = "`r(varlist)'"

		// source of drinking water
		lookfor "source of drinking water" "source principale eau" "fonte de água" /// 
			"source of water" "source d'eau" "fuente de agua" "abastecimento de água" /// 
			"abastecimiento de agua" "principale source" "fuente principal de agua"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		** if "`r(varlist)'" == "" {
			** lookfor "source of drinking water" "source principale eau" "fonte de água" /// 
				** "source of water" "source d'eau" "fuente de agua" "abastecimento de água" /// 
				** "abastecimiento de agua"
			** mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		** }
		// source of non-drinking water
		lookfor "non-drinking"
		mata: w_srcedrnk_other[`filenum', 1] = "`r(varlist)'"

		// minutes to water source
		lookfor "time to get" "minutes"
		mata: mins_ws[`filenum', 1] = "`r(varlist)'"

		// treatment gateway question- in order to have correct value for total proportion using treatment to use as denominator

		lookfor "make safe to drink"
		mata: w_treat[`filenum', 1] = "`r(varlist)'"

		// filter use 
		lookfor "hv237d" 
		mata: w_filter[`filenum', 1] = "`r(varlist)'"
		
		//boil water
		lookfor "hv237a" "boil"
		mata: w_boil[`filenum', 1] = "`r(varlist)'"
		
		//chlorination/bleaching of water
		lookfor "hv237b" "add bleach/chlorine"
		mata: w_bleach[`filenum', 1] = "`r(varlist)'"
		
		//solar disinfection
		lookfor "hv237e" "solar disinfection"
		mata: w_solar[`filenum', 1] = "`r(varlist)'"

		// type of toilet facility
		lookfor "type of toilet" "kind of toilet" "type de toilette" "tipo de toilet"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		** if "`r(varlist)'" == "" {
			** lookfor "type of toilet" "kind of toilet" "type de toilette" "toilet" "toilettes" /// 
				** "servicio sanitario" "toillettes"
			** mata: t_type[`filenum', 1] = "`r(varlist)'"
		** }

		// shared sanitation
		lookfor "hv225"
		mata: shared_san[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "share"
			mata: shared_san[`filenum', 1] = "`r(varlist)'"
		}

		//handwashing station
		lookfor "hv230a" "hv230" "place where household members wash their hands" 
		mata: w_hwss[`filenum', 1] = "`r(varlist)'"
		
		//soap or detergent
		lookfor "hv232" "items present: soap or detergent"
		mata: w_soap[`filenum', 1] = "`r(varlist)'"
		
		//water
		lookfor "hv230b" "presence of water at hand washing place"
		mata: w_water[`filenum', 1] = "`r(varlist)'"

		// cooking fuel
		lookfor "fuel"
		mata: cooking_fuel[`filenum', 1] = "`r(varlist)'"
}


** move variables from Mata into Stata datset
use "`dat_folder_new_mis'/datfiles_mis", clear
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_mis'/varlist_temp_mis", replace		
	

** replace variables to mark surveys that are lacking both water and toilet information	
use "`dat_folder_new_mis'/varlist_temp_mis", clear
** gen noinfo = (w_srcedrnk == "")
** foreach var of local vars {
	** replace `var' = "NOINFO" if noinfo == 1
** }
	
	
** clean up entries with more than one variable listed
	// psu
	replace psu = "hv001" if regexm(psu, "hv001")
	bro psu if regexm(psu, " ")
		** not lacking any entries
	
	// weight
	replace weight = "hv005" if regexm(weight, "hv005")
	bro weight if regexm(weight, " ")
		** not lacking any entries
	
	// urban
	replace urban = "hv025" if regexm(urban, "hv025")
	bro urban if regexm(urban, " ")
		** not lacking any entries
	
	// w_srcedrnk
	replace w_srcedrnk = "hv201" if regexm(w_srcedrnk, "hv201")
	bro w_srcedrnk if regexm(w_srcedrnk, " ")
		** not lacking any entries
	
	// t_type
	bro t_type if regexm(t_type, " ")
		** not lacking any entries
	
	
** ** create new variable for other relevant variables
** gen w_other = ""
replace psu = "HV001" if filename == "RWA_MIS_2012_2013_HH_Y2014M08D20.DTA"
replace urban = "HV025" if filename == "RWA_MIS_2012_2013_HH_Y2014M08D20.DTA"
** organize
compress


** save 
save "`dat_folder_new_mis'/varlist_mis", replace


capture log close