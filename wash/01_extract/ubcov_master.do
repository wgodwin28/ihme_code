/***********************************************************************************************************
 Author: Patrick Liu (pyliu@uw.edu)																		
 Date: 7/13/2015
 Project: ubCov
 Purpose: Run Script
																					
***********************************************************************************************************/


//////////////////////////////////
// Setup
//////////////////////////////////

if c(os) == "Unix" {
	local j "/home/j"
	set odbcmgr unixodbc
}
else if c(os) == "Windows" {
	local j "J:"
}

clear all
set maxvar 10000
set more off
set obs 1

// Settings
local central_root "`j'/WORK/01_covariates/common/ubcov_central"
local topics wash

// Load the base code for ubCov
cd "`central_root'"
do "`central_root'/modules/extract/core/load.do"

// Initialize the system
/* 
	Brings in the databases, after which you can run
	extraction or sourcing functions like: new_topic_rows

	You can view each of the loaded databases by running: get, *db* (eg. get, codebook)
*/

ubcov_path
init, topics(`topics')

// Run extraction
/* Launches extract

	Arguments:
		- ubcov_id: The id of the codebook row
	Optional:
		- keep: Keeps 
		- bypass: Skips the extraction check
		- run_all: Loops through all ubcov_ids in the codebook.
*/
get, codebook
// keep if regexm(survey_name, "DHS") | regexm(survey_name, "MICS") | regexm(survey_name, "AIS") | regexm(survey_name, "MIS")
// keep if survey_module == "HH" & hh_size != "" & cooking_fuel != "" & !regexm(survey_name, "ROMA")
// keep if shared_san != ""
drop if regexm(survey_name, "SP") | regexm(survey_name, "LSMS") | regexm(survey_name, "ROMA") | regexm(survey_name, "IPUMS_CENSUS") 
drop if regexm(file_path, "SAV") | regexm(file_path, "sav")
drop if _n >17
| survey_module != "HH"
	levelsof ubcov_id, l(i)
	// import delimited "`j'/temp/wgodwin/wash_exposure/id2.csv", clear
	// keep if module == "HH"
	// levelsof ids, local(i)
	// local i 2818
		do "H:/risk_factors/wash/01_extract/custom_code.do"
	levelsof ubcov_id, l(i)
	foreach id of local i {
		run_extract `id', bypass store_vals
		local out_dir "`j'/temp/wgodwin/wash_exposure/extract_values"
		cap mkdir "`out_dir'/$ihme_loc_id"
		local survey_name = subinstr("$survey_name", "/", "_", .)
		local year_start $year_start
		local mod $survey_module
		cap confirm variable empty
		if _rc {
			save "`out_dir'/$ihme_loc_id/`survey_name'_`mod'_`year_start'", replace
		}
	}
	
local stata_shell 		"/home/j/temp/wgodwin/save_results/stata_shell.sh"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
	
	drop if nid == 106684 | nid == 12104 | nid == 106686 | nid == 11848
	levelsof ubcov_id, l(i)
	foreach id of local i {
		! qsub -N extract_`id' -P proj_custom_models `logs' "`stata_shell'" "/snfs2/HOME/wgodwin/risk_factors/wash/01_extract/ubcov_child.do" "`id'"
	}
// -pe multi_slot 2
