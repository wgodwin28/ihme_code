//Append together gpr output for processing. Parallelized by exposure type.
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

set more off


// Set relevant locals	
local output_dir		"$j/temp/wgodwin/save_results/wash_hwws/draws"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
local code_folder 		"$j/WORK/05_risk/risks/wash_hygiene/code/03_final_prep"
local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"

// Loop through each exposure and submit script to append csv's together
local exposures hwws hwws_dhs
foreach exposure of local exposures {
	if "`exposure'" == "hwws" {
		local data_id 567
		local model_id 248
	}
	if "`exposure'" == "hwws_dhs" {
		local data_id 585
		local model_id 265
	}
 		local input_dir /share/covariates/ubcov/04_model/wash_`exposure'/_models/`data_id'/`model_id'/draws
		! qsub -N `exposure' -pe multi_slot 8 -P proj_custom_models `logs' "`stata_shell'" "`code_folder'/01_post_gpr_append.do" "`input_dir' `output_dir' `exposure'"
	}
