// priming the working environment
clear 
set more off
set maxvar 30000

// discover root
if c(os) == "Unix" {
		global j "/home/j"
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Set locals
local in_dir 			"$j/temp/wgodwin/sga/data/01_prepped"
local out_dir 			"$j/temp/wgodwin/sga/data/02_collapsed"
local code_folder		"$j/temp/wgodwin/sga/code/extract_collapse"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"

// Loop over files with data by location year
		// !qsub -N nothing -pe multi_slot 4 -P proj_custom_models `logs' "`stata_shell'" "`code_folder'/03_collapse_child.do" "`in_dir' `out_dir'" 
		!qsub -N nothing -pe multi_slot 8 -P proj_custom_models `logs' "`stata_shell'" "`code_folder'/03_collapse_child.do" "`in_dir' `out_dir'" 

