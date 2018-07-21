/***********************************************************************************************************
 Author: Patrick Liu (pyliu@uw.edu)																		
 Date: 7/13/2015
 Project: ubCov
 Purpose: Run Script
 Run: do "/snfs2/HOME/wgodwin/risk_factors2/wash/01_extract/ubcov_master.do"																					
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

//Versioning
//limited to most recent (post 2010 surveys) sources to add important ones for review week
local run "run1" 
//batch extract with geospatial strings
local run "run2"
//revisions to custom code
local run "run3"
//more strings mapped correctly
local run "run4"
//and more strings mapped correctly
local run "run5"
//just extract water treatment vars
local run "run6"

//Set out directory
local outpath = "`j'/LIMITED_USE/LU_GEOSPATIAL/ubCov_extractions/wash_gbd/`run'"
cap mkdir "`outpath'"
cap mkdir "`outpath'/survey"
cap mkdir "`outpath'/census"
cap mkdir "`outpath'/logs"

local stata_shell 		"/share/code/wash/04_save_results/stata_shell.sh"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors

local rerun = 1
if `rerun' == 1 {
	local allfiles : dir "`outpath'/logs" files "*.dta"
	gen ubcov_id = .
	tempfile all
	save `all', replace
	foreach f in `allfiles'{
		use "`outpath'/logs/`f'", clear
		append using `all'
		save `all', replace
	}
	duplicates drop ubcov_id, force
	save `all', replace
	get, codebook
	merge 1:1 ubcov_id using `all'
	keep if _merge == 1
	keep if regexm(survey_module, "HH")
	levelsof ubcov_id, l(i)
}	
	**drop if nid == 106684 | nid == 12104 | nid == 106686 | nid == 11848
if `rerun' == 0 {
	get, codebook
	keep if regexm(survey_module, "HH")
	levelsof ubcov_id, l(i)
}

foreach id of local i {
	! qsub -N extract_`id' -pe multi_slot 1 -P proj_paf `logs' "`stata_shell'" "/snfs2/HOME/wgodwin/risk_factors2/wash/01_extract/ubcov_child.do" "`id' `outpath'"
}
