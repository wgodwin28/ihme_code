// Author: Stephanie Teeple
// Created: 10 Jan 2016
// Edited: Will Godwin
// Description: This script uses Logan Sandar's survey_juicer suite of functions to collapse NBER US VR data for neonatal conditions. The two measures we can
// get from this data are preterm birth prevalence and case fatality of preterm birth for each of the standard gestational age brackets we use (<28 weeks, 28-32 weeks, <=36 weeks).
// Prepped microdata files (assumption applied: all live births at <21 weeks gestational age were dropped b/c that's implausible - Theo) 

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


// set locals
local in_dir 			"$j/temp/wgodwin/sga/data/01_prepped"
local out_dir 			"$j/temp/wgodwin/sga/data/02_collapsed"
local code_folder		"$j/temp/wgodwin/sga/code/extract_collapse"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"

// Loop over files with data by location year
	local filenames: dir "`in_dir'/USA" files "USA*", respectcase
		foreach file of local filenames {
			!qsub -N `file' -pe multi_slot 4 -P proj_custom_models `logs' "`stata_shell'" "`code_folder'/02_collapse_child.do" "`in_dir' `out_dir' `file'" 
		}

/*
	foreach iso3 in URY MEX {
		local filenames: dir "`in_dir'/`iso3'" files "`iso3'*", respectcase
		foreach file of local filenames {
			!qsub -N `file' -pe multi_slot 4 -P proj_custom_models `logs' "`stata_shell'" "`code_folder'/02_collapse_child_URY_MEX.do" "`in_dir' `out_dir' `iso3' `file'" 
	}
}
