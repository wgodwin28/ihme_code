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
local input_dir			"/share/epi/risk/temp/wash_sanitation/run3"
local location_dir		"/share/epi/risk/temp/wash_sanitation/run3/locations"
local code_folder 		"/snfs2/HOME/wgodwin/rf_code/sanitation/code/03_final_prep"
local save_dir 			"/share/epi/risk/temp/wash_sanitation/review_week"
local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
adopath + "/home/j/temp/central_comp/libraries/current/stata"

local date 04102016

// Prep the country codes file
	get_location_metadata, location_set_id(22) clear
	keep if level >= 3
	drop if location_id == 6
	levelsof location_id, local(locations)

// Prep location specific files so lower level script doesn't have to load in whole dataset each time
local toggle 1
if `toggle' == 1 {
	foreach loc of local locations {
		foreach exp of local exposures {
			! qsub -N split_`loc'_`exp' -P proj_custom_models -pe multi_slot 4 `logs' "`stata_shell'" "`code_folder'/02_location_split_save.do" "`location_dir' `input_dir' `loc' `exp'"
		}
	}	
}
// save hella files to prep for save_results
local toggle2 0
if `toggle2' == 1 {
foreach exp of local exposures {
	foreach loc of local locations {
		// local loc 6
		! qsub -N `exp'_`loc' -P proj_custom_models -pe multi_slot 8 `logs' "`stata_shell'" "`code_folder'/03_save_split.do" "`location_dir' `save_dir' `exp' `loc'"
		}
	}
}
