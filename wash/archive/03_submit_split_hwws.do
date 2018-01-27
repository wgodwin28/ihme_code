// Submit script to prep handwashing draws for save_results
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
local get_location		"$j/WORK/10_gbd/00_library/functions/get_location_metadata.ado"
local input_dir			"$j/temp/wgodwin/save_results/wash_hwws/rough_output"
local location_dir		"/share/epi/risk/temp/wash_hwws/locations"
local code_folder 		"$j/WORK/05_risk/risks/wash_hygiene/code/03_final_prep"
local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"
local save_dir			"/share/epi/risk/temp/wash_hwws/run1"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
local date				04152016

// Prep the country codes file
	run "`get_location'"
	get_location_metadata, location_set_id(9) clear
	keep if level >= 3
	drop if location_id==6 // save_results aggregates up to all of China using mainland China, HK, and Macao.
	levelsof location_id, local(locations)

// Prep location specific files so lower level script doesn't have to load in whole dataset each time
local toggle 0
if `toggle' == 1 {
			foreach loc of local locations {
			! qsub -N save_`loc' -pe multi_slot 8 -P proj_custom_models `logs' "`stata_shell'" "`code_folder'/02_location_split_save.do" "`location_dir' `input_dir' `loc' `date'"
		}
	}	
// save hella files to prep for save_results
local toggle2 1
if `toggle2' == 1 {
	foreach loc of local locations {
		! qsub -N split_`loc' -P proj_custom_models -pe multi_slot 8 `logs' "`stata_shell'" "`code_folder'/03_save_split.do" "`location_dir' `save_dir' `loc'"
		}
	}
