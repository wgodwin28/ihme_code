// Author: Will Godwin
// Purpose: Split observations by location_id, year_id after processing to conform with save_results formatting
// Date: 2/29/16

// Additional Comments: 
// do /snfs2/HOME/wgodwin/risk_factors2/wash/03_split/wash_hap_master.do

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
	//Risk toggle ****CHANGE EACH TIME*****
		local risk = "wash_sanitation"
		//local risk = "wash_water"
		//local risk = "wash_hwws"
		//local risk = "air_hap"
		local run run1

	if "`risk'" == "wash_sanitation" {
		local exposures 	"improved unimp"
	}
	if "`risk'" == "wash_water" {
		local exposures 	"imp_t imp_t2 imp_untr unimp_t unimp_t2 unimp_untr bas_piped_t bas_piped_t2 bas_piped_untr piped_untr_hq piped_t2_hq"
	}
	if "`risk'" == "wash_hwws" {
		local exposures "wash_hwws"
	}
	if "`risk'" == "air_hap" {
		local exposures "air_hap"
	}

	local input_dir			"/share/epi/risk/temp/`risk'/`run'"
	local location_dir		"`input_dir'/locations"
	local code_folder 		"/snfs2/HOME/wgodwin/risk_factors2/wash/03_split"
	local stata_shell 		"$j/temp/wgodwin/save_results/stata_shell.sh"
	local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
	adopath + "/home/j/temp/central_comp/libraries/current/stata"

// Prep the country codes file
	get_location_metadata, location_set_id(22) clear
	keep if level >= 3
	// drop if location_id == 6
	levelsof location_id, local(locations)

// Prep location specific files so lower level script doesn't have to load in whole dataset each time
	foreach loc of local locations {
		foreach exp of local exposures {
			! qsub -N `exp'_`loc'_split -P proj_custom_models -pe multi_slot 2 `logs' "`stata_shell'" "`code_folder'/location_split_save.do" "`location_dir' `input_dir' `loc' `exp'"
		}
	}	
