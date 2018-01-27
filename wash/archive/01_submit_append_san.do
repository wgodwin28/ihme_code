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


// Set relevant locals	
// local output_dir		"/home/j/WORK/05_risk/risks/wash_water/data/exp/me_id/uploaded/draws"
local output_dir		"$j/temp/wgodwin/save_results/wash_sanitation/draws"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"
local code_folder 		"$j/WORK/05_risk/risks/wash_sanitation/code/03_final_prep"

// Loop through each exposure and submit script to append csv's together
local exposures imp piped
foreach exposure of local exposures {
	if "`exposure'" == "imp" {
		local data_id 571
		local model_id 208
	}
	if "`exposure'" == "piped" {
		local data_id 572
		local model_id 205
	}
 		local input_dir /share/covariates/ubcov/04_model/wash_sanitation_`exposure'/_models/`data_id'/`model_id'/draws
		! qsub -N `exposure' -pe multi_slot 8 -P proj_custom_models `logs' "`stata_shell'" "`code_folder'/01_post_gpr_append.do" "`input_dir' `output_dir' `exposure'"
	}
