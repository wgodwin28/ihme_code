// File Name: lookfor_vars_dhs.do

// File Purpose: Look for appropriate variables in DHS surveys
// Author: Leslie Mallinger
// Date: 3/2/10 - 3/13/10
// Edited on: 4/1/10 (reduced to just DHS 5); 4/12/10 (changed to just DHS 4); 4/13/10 (changed to just DHS 3);
//	1/3/2011 (updated to reflect new file paths); 6/1/2012 (all DHS at once)
//Edited on: 1/26/2013 to extract data on new variables for water and sanitation: 1) filter use ; 2) sewer connection/flush toilet 

// Additional Comments: 
clear all
set mem 2000m
set maxvar 10000
set more off
capture log close


** create locals for relevant files and folders
local data_folder 			"J:/WORK/05_risk/risks/wash_hygiene/data/exp/me_id/input_data/01_data_audit"
local dat_folder_new_dhs 	"`data_folder'/dhs"


** open dataset and store data in a mata matrix
use "`dat_folder_new_dhs'/datfiles_dhs", clear
tostring svyver_real, replace
mata: files=st_sdata(.,("countryname", "filedir", "filename", "svyver_real"))
local maxobs = _N


** create a vector for each of the variables of interest
local vars psu weight urban w_hwss w_soap w_water t_type
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
	
	// open file (only first 50 observations for speed)
	use "`filedir'/`filename'" if _n < 50, clear
	
	** look for variables of interest and save in appropriate vector
		// primary sampling unit
		if "`svyver'" == "1" lookfor "v001"
		else lookfor "hv021"
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
		if "`svyver'" == "1" lookfor "v005"
		else lookfor "hv005"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "sample weight" "ponder" "poids" "household weight"
			mata: weight[`filenum', 1] = "`r(varlist)'"
		}
		
		// urban/rural
		if "`svyver'" == "1" lookfor "v102"
		else lookfor "hv025"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "type of place of residence" "urban"
			mata: urban[`filenum', 1] = "`r(varlist)'"
			if "`r(varlist)'" == "" {
				lookfor "area" "milieu"
				mata: urban[`filenum', 1] = "`r(varlist)'"
			}
		}
				
		//handwashing station 
		if ("`svyver'"=="4" | "`svyver'"=="5") lookfor "place for hand washing" "hv230"
		else lookfor "hv230a" "place where household members wash their hands" 
		mata: w_hwss[`filenum', 1] = "`r(varlist)'"
		
		//soap or detergent
		if ("`svyver'"=="4" | "`svyver'"=="5") lookfor "items present: soap/other cleansing agent" "hv232"
		else lookfor "hv232" "items present: soap or detergent"
		mata: w_soap[`filenum', 1] = "`r(varlist)'"
		
		//water
		if ("`svyver'"=="4" | "`svyver'"=="5") lookfor "items present: water, tap" "hv231"
		else lookfor "hv230b" "presence of water at hand washing place"
		mata: w_water[`filenum', 1] = "`r(varlist)'"
		
		// type of toilet facility
		if "`svyver'" == "1" lookfor "v116"
		else lookfor "hv205"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "type of toilet" "sanitario" "servicio higienico" "cuarto de" "fezes"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
			if "`r(varlist)'" == "" {
				lookfor "toilet" "toilettes"
				mata: t_type[`filenum', 1] = "`r(varlist)'"
			}
		}
		
}


** move variables from Mata into Stata datset
use "`dat_folder_new_dhs'/datfiles_dhs", clear
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_dhs'/varlist_temp_dhs", replace
	

** mark surveys that are lacking both water filter and toilet information
use "`dat_folder_new_dhs'/varlist_temp_dhs", clear
gen noinfo = (w_hwss=="" & w_soap=="" & w_water==""dr)
foreach var of local vars {
	replace `var' = "NOINFO" if noinfo == 1
}
	
	
** clean up entries with more than one variable listed
	// psu
	replace psu = "hv021" if regexm(psu, "hv021")
	replace psu = "region" if iso3 == "BRA" & startyear == 1986
	replace psu = "hv001" if iso3 == "IND" & startyear == 2005
	replace psu = "v001" if iso3 == "KEN" & startyear == 1988
	replace psu = "mdr" if iso3 == "SEN" & startyear == 1999
	bro psu if regexm(psu, " ")
		** not lacking any entries
	
	// weight
	replace weight = "hv005" if regexm(weight, "hv005")
	replace weight = "qhweight" if iso3 == "BGD" & startyear == 2001
	replace weight = "v005" if iso3 == "KEN" & startyear == 1988
	replace weight = "mpond" if iso3 == "MAR" & startyear == 1995
	replace weight = "pondhog" if iso3 == "MEX" & startyear == 1987
	replace weight = "hv005" if iso3 == "PER" & startyear == 2003
	replace weight = "mpond" if iso3 == "SEN" & startyear == 1999
	replace weight = "qhweight" if iso3 == "UZB" & startyear == 2002
	bro weight if regexm(weight, " ")
		** lacking entries for BRA 1986, ECU 1987, EGY 1988, EGY 1996, GTM 1987
	
	// urban
	replace urban = "hv025" if regexm(urban, "hv025")
	replace urban = "v102" if regexm(urban, "v102")
	replace urban = "qhtype" if iso3 == "AFG" & startyear == 2010
	replace urban = "qhtype2" if iso3 == "BGD" & startyear == 2001
	replace urban = "qhurbrur" if iso3 == "GHA" & startyear == 2007
	replace urban = "murbrur" if iso3 == "MAR" & startyear == 1995
	replace urban = "" if iso3 == "MEX" & startyear == 1987
	bro urban if regexm(urban, " ")
		** lacking entries for EGY 1988, EGY 1996, MEX 1987
	
	//w_hwss
	replace w_hwss = "hv230a" if regexm(w_hwss, "hv230a ") 
	
	//w_soap
	replace w_soap = "hv232" if regexm(w_soap, "hv232 ") 
	replace w_soap = "HV232" if regexm(w_soap, "HV232 ") 
	
	//w_water
	replace w_water = "hv230b" if filename=="CMR_DHS5_2011_HH_Y2013M01D16.DTA"

	// t_type
	replace t_type = "hv205" if regexm(t_type, "hv205")
	replace t_type = "shh19" if iso3 == "IDN" & startyear == 1991
	replace t_type = "sh17" if iso3 == "IDN" & startyear == 1994
	replace t_type = "sh17" if iso3 == "IDN" & startyear == 1997
	replace t_type = "h025" if iso3 == "MEX" & startyear == 1987
	replace t_type = "hv205" if iso3 == "PER" & startyear == 2003
	bro t_type if regexm(t_type, " ")
		** not missing any entries
		
	// education
		** only non-standard missing
	
	// electricity
		** only non-standard missing

** organize
compress
drop if noinfo==1

** save 
save "`dat_folder_new_dhs'/varlist_dhs", replace
