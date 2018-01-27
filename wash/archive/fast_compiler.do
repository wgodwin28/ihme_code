// Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

local in_dir 	"/ihme/covariates/ubcov//model//output/157/draws_temp"
local out_dir 	"/share/epi/risk/temp/wash_hwws5"
local logs 		-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors

// The super fast compiler. Use for all WaSH models
! qsub -pe multi_slot 4 -P proj_custom_models `logs' "/home/j/temp/wgodwin/save_results/append_sh.sh" "`in_dir'" "`out_dir'" "dhs_v2"
// ! qsub -pe multi_slot 4 -P proj_custom_models `logs' "/home/j/temp/wgodwin/save_results/append_sh.sh" "`in_dir'" "`out_dir'" "itreat_piped_v1"
// arguments are "input directory" "output directory" and "output name"
// just change the run_id in the input directory and the output_dir