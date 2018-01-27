clear all
set more off
set maxvar 20000

// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 

// SO in parent script, read in the codebook and count number of rows. Then set up the qsub and loop through each row of the codebook while passing the `a' argument
// In the child script, "keep if _n==`a' and then "

// Directory Locals
	local code_folder		"$j/temp/wgodwin/sga/code/extract_collapse"
	local input_root		"$j/temp/wgodwin/sga/data"
	local output_root 		"$j/temp/wgodwin/sga/data/01_prepped"
	local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
	local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"

// Setting up mata 
    insheet using "`input_root'/microdata_cb.csv", clear

// Begins a loop that looks at each survey individually
	local set_num = _N
	forvalues a = 1/`set_num' { 
		! qsub -N source_num_`a' -pe multi_slot 8 -P proj_custom_models `logs' "`stata_shell'" "`code_folder'/01_prep_sga_child.do" "`input_root' `output_root' `a'"
	}
