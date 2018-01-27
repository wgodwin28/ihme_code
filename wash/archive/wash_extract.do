/***********************************************************************************************************
 Author: Will Godwin (wgodwin@uw.edu)															
 Date: 9/16/16														
 Project: ubCov																
 Purpose: Module: WASH
 																	
***********************************************************************************************************/

////////////////////////////
//	1. Set Up			
///////////////////////////

	if c(os) == "Unix" {
		local prefix "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		local prefix "J:"
	}

// Locals
	// Module
	local current_module "extract_wash"
	// Code Root
	local code_root `1'
	// Survey_root
	local survey_root `2'
	// Survey Nid
	local nid `3'
	// Survey File_path
	local file_path `4'
	// Survey module
	local survey_module `5'
	// Specify project since slightly different extraction specs
	local geospatial 	0	
	local risk			1
	if `geospatial' == 1 & `risk' == 1 {
		di in red "must specify one project at a time"
		BREAK
	}

///////////////////////////////////////////////
//	2. Setting codebook locals
//////////////////////////////////////////////

// Preserve from prep file
preserve

	// Prep codebook
	do "$module_root/prep_codebook.do" 	2 `current_module' `survey_root' `nid' `file_path' `survey_module'

		// Input into mata
		ds
		local mata_col `r(varlist)'
		putmata codebook = (`mata_col'), replace

		// Set Locals
		local count = 1
		foreach col of local mata_col {
			mata: st_local("`col'", codebook[1, `count'])
			local ++count
		}
		mata: mata drop codebook


// Restore to prep file
restore


///////////////////////////////////////////////
//	3. Extract	
//////////////////////////////////////////////

// Binary
if `risk' == 1 {
	local bin_vars w_treat w_filter w_boil w_bleach w_solar w_cloth w_settle shared_san hw_water hw_soap hw_station
}
else if `geospatial' == 1 {
	local bin_vars w_treat w_filter w_boil w_bleach w_solar w_cloth w_settle shared_san hw_water hw_soap
}
// local bin_vars hw_station
foreach var in `bin_vars' {
	cap confirm numeric variable ``var''
	if !_rc {
		gen `var' = . 
		replace `var' = 1 if inlist(``var'', ``var'_yes_vals')
		replace `var' = 0 if inlist(``var'', ``var'_no_vals')
	}
	cap confirm string variable ``var''
	if !_rc & "`var'" != "hw_soap" { // must account for soap string variable in MICS separately
		di in red "`var' is string or missing"
		gen `var' = .
		replace `var' = 1 if inlist(``var'', "``var'_yes_vals'")
		replace `var' = 0 if inlist(``var'', "``var'_no_vals'")
	}
	// if variable is completely missing
	cap confirm variable ``var'' 
	if _rc {
		gen `var' = "missing"
	}
	// If variable is present but has no observations
	if ihme_type == "UNICEF_MICS" & "`var'" != "hw_soap" { // b/c soap has multiple variables in one cell, stata cannot recognize variable
		count if !missing(``var'')
		if `r(N)' == 0 {
			cap drop `var'
			gen `var' = "missing"
		}
	}
	else {
		count if !missing(``var'')
		if `r(N)' == 0 {
			cap drop `var'
			gen `var' = "missing"
		}
	}
}

// Special recode for soap variable in MICS
	if ihme_type == "UNICEF_MICS" {
		cap confirm variable `hw_soap'
		if !_rc {
			local vars "`hw_soap'"
			di "`vars'"
			cap drop hw_soap
			gen hw_soap = .
			local cmd_list = `""A","B","C""'
			// local cmd_list = `"`"hw_soap_yes_vals"'"' ****Not sure how to pull in local and separate into 3 arguments like above

			foreach var in `vars' {
				di in red "`var'"
				replace hw_soap = 1 if inlist(`var', `cmd_list')
				replace hw_soap = 0 if hw_soap != 1 &`var' == ""

			}
		}
	}

// Continuous
local cont_vars mins_ws shared_san_num
foreach var in `cont_vars' {
	// confirm it's numeric
	cap confirm numeric variable ``var''
	if !_rc {
		gen `var' = ``var''
		// Correct for values that are used to represent "water on premise"
		if "`var'" == "mins_ws" {
			// cap confirm variable `mins_ws_zero'
			// if !_rc {
				// if `mins_ws_zero' != . {
				di in red "`mins_ws_zero'"
				di in red "`var'"
				cap replace `var' = 0 if inlist(``var'', `mins_ws_zero')
			// }
		}
		// Correct for values that are used to represent >10 households shared san
		if "`var'" == "shared_san_num" {
			cap replace `var' = 11 if inlist(``var'', ``var'_greater_ten')
		}
		cap assert missing(`var')
		if !_rc {
			cap drop `var'
			gen `var' = "missing"
		}
	}
	else if _rc {
		di in red "`var' variable missing or not numeric"
		gen `var' = "missing"
	}
}

// Categorical string
if `risk' == 1 {
	local string_vars w_source_drink w_source_other t_type fuel_cooking
}
else if `geospatial' == 1 {
	local string_vars w_source_drink w_source_other t_type hw_station fuel_cooking
}

foreach var in `string_vars' {
	// If already string
	cap confirm string variable ``var''
	if !_rc {
		di in red "`var' string variable"
		gen `var' = `var'
		di "`var' poop"
	}

	// If labeled numeric
	cap confirm numeric variable ``var''
	if !_rc {
		cap decode ``var'', gen(`var')
		// if not labeled, just numeric
		if _rc {
			gen `var' = ``var''
		}
	}

	// If variable is missing
	cap confirm variable ``var''
	if _rc {
		di in red "`var' missing"
		gen `var' = "missing"
	}

	// If variable is present but has no observations
	count if !missing(``var'')
	if `r(N)' == 0 {
		cap drop `var'
		gen `var' = "missing" 
	}
}

// Sanity check
local vars `string_vars'
local check 0

foreach var in `vars' {
	cap confirm string variable `var'
	if !_rc {
		if `var' != "missing" {
			local check = `check' + 1
		}
	}
	else {
		cap assert missing(`var')
		if _rc {
			local check = `check' + 1
		}
	}
}

di in red `check'
if `check' == 0 {
	di in red "all variables missing, please check dataset and extraction"
	BREAK
}

///////////////////////////////////////////////
//	4. Error Check
//////////////////////////////////////////////

if "$error_check" == "1" {

	// Errors


} // Close Error Check Toggle

///////////////////////////////////////////////
//	5. Final Steps
//////////////////////////////////////////////

// Variables to keep from module

// global keep_`current_module' w_filter w_boil w_bleach w_solar w_cloth w_settle hw_station hw_soap hw_water mins_ws shared_san shared_san_num w_source_drink w_source_other t_type fuel_cooking

global keep_`current_module' `bin_vars' `cont_vars' `string_vars'
