// Author: Will Godwin
// Purpose: Split observations by location_id, year_id after processing to conform with save_results formatting
// Date: 2/29/16

// Additional Comments: 

// Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Housekeeping
clear all 
set more off
set maxvar 20000

// Set relevant locals
local exposures			"unimp improved"
local input_dir			"$j/temp/wgodwin/save_results/wash_sanitation/rough_output"
local get_location		"$j/WORK/10_gbd/00_library/functions/get_location_metadata.ado"
local location_dir		"/share/epi/risk/temp/wash_sanitation/locations"
local code_folder 		"$j/WORK/05_risk/risks/wash_sanitation/code/03_final_prep"
local save_dir 			"/share/epi/risk/temp/wash_sanitation"
local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors


local date 02282016

// Prep the country codes file
	run "`get_location'"
	get_location_metadata, location_set_id(9) clear
	keep if level >= 3
	drop if location_id == 6
	levelsof location_id, local(location)

// Prep location specific files so lower level script doesn't have to load in whole dataset each time
local toggle 1
if `toggle' == 1 {
	use "`input_dir'/allcat_prev_san_`date'", clear
	foreach exp of local exposures {
		cap mkdir "`location_dir'/`exp'"
			foreach loc of locations {
				preserve
				keep if location_id == `loc'
				keep age_group_id location_id year_id i`exp'_*
				save "`location_dir'/`exp'/`loc'", replace
				restore
		}
	}	
}

// save hella files to prep for save_results
local toggle2 1
if `toggle2' == 1 {
foreach exp of local exposures {
	foreach loc of local locations {
		// local loc 6
		! qsub -N `exp'_`loc' -P proj_custom_models -pe multi_slot 8 `logs' "`stata_shell'" "`code_folder'/03_save_split.do" "`location_dir' `save_dir' `exp' `loc'"
		}
	}
}
