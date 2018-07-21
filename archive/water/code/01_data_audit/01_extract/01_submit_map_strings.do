/***********************************************************************************************************
 Author: Will Godwin (wgodwin@uw.edu)															
 Date: 9/16/16														
 Purpose: Wash exposure extraction and estimation master script															
 																	
***********************************************************************************************************/

////////////////////////////
//	1. Set Up			
///////////////////////////
clear all
set more off

//Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}


// Locals
local data_dir 			"$j/temp/wgodwin/wash_exposure/01_extract"
local out_dir			"$j/temp/wgodwin/wash_exposure/02_clean"
local keyloc 			"$j/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Label_Keys"
local keyversion 		"assigned_04082014"
local code_folder 		"/snfs2/HOME/wgodwin/rf_code/water/code/01_data_audit/01_extract"
local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors

local map_strings 	1
local gen_means		0

adopath + "$j/WORK/10_gbd/00_library/functions"

// Store all iso3s in a local
	get_location_metadata, location_set_id(9) clear
	keep if level == 3 // Only have surveys at the country level
	levelsof ihme_loc_id, local(iso3s)
// Debugging
// local file "MACRO_DHS(2005).dta"
local iso3s KHM PRY BOL

// Run mapping strings script to generate binary indicator for water source and toilet type
	foreach iso3 of local iso3s {
		cap cd "`data_dir'/`iso3'"
		if !_rc {
			local files : dir "`data_dir'/`iso3'" files "*.dta"
			foreach file of local files {
				! qsub -N stan_string_`iso3' -P proj_custom_models -pe multi_slot 4 `logs' "`stata_shell'" "`code_folder'/02_map_string_labels.do" "`data_dir' `out_dir' `iso3' `file' `keyloc' `keyversion'"
			}
		}
	}
