// Author: Will Godwin
// Purpose: Split observations by location_id, year_id after processing to conform with save_results formatting
clear all
set more off
cap restore, not

// Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}


// Set relevant locals
local exposures 		"imp_t imp_t2 imp_untr unimp_t unimp_t2 unimp_untr piped_t2 piped_untr piped_untr_hq piped_t2_hq"
local get_location 		"$j/WORK/10_gbd/00_library/functions/get_location_metadata.ado"
local location_dir 		"/share/epi/risk/temp/wash_water/locations"
local input_dir 		"$j/temp/wgodwin/save_results/wash_water/rough_output"
local save_dir 			"/share/epi/risk/temp/wash_water"
local code_folder 		"$j/WORK/05_risk/risks/wash_water/code/03_final_prep"
local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"
local logs -o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors

local date 04102016


// Make directory for saved draws, if neccesary

// get location_ids
	run "`get_location'"
	get_location_metadata, location_set_id(9) clear
	keep if level >= 3
	drop if location_id == 6 // Save_results aggregates to location_id 6 on it's own
	levelsof location_id, local(locations)

// Prep location specific files so lower level script doesn't have to load in whole dataset each time
local toggle 1
if `toggle' == 1 {
			foreach loc of locations {
			! qsub -N `loc'_split -P proj_custom_models -pe multi_slot 8 `logs' "`stata_shell'" "`code_folder'/02.5_location_split_save.do" "`location_dir' `input_dir' `loc' `date'"
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
end