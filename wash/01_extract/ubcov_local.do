/***********************************************************************************************************
 Author: Patrick Liu (pyliu@uw.edu)																		
 Date: 7/13/2015
 Project: ubCov
 Purpose: Run Script
 Run: do "/snfs2/HOME/wgodwin/risk_factors2/wash/01_extract/ubcov_local.do"																					
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

local stata_shell 		"/home/j/temp/wgodwin/save_results/stata_shell.sh"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors

local rerun = 0
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
	drop if ubcov_id == 6 | nid == 153154 | nid == 1098 | nid == 26661
	drop if regexm(file_path, ".SAV") | regexm(file_path, ".sav")
	levelsof ubcov_id, l(i)

}	
	**drop if nid == 106684 | nid == 12104 | nid == 106686 | nid == 11848
if `rerun' == 0 {
	get, codebook
	keep if regexm(survey_module, "HH")
	levelsof ubcov_id, l(i)
}

//Just water treatment variables
**get, codebook
**sort ubcov_id
**keep if regexm(survey_module, "HH")
**keep if w_treat != ""
**keep if ubcov_id > 10863 //10857 //10855, 10854 // 10853 // 9113 // 9109 // 9067 //8274 //7914 
**levelsof ubcov_id, l(i)

//Loop through each source and extract
foreach id of local i {
	run_extract `id', bypass store_vals 
	do "/snfs2/HOME/wgodwin/risk_factors2/wash/01_extract/custom_code.do"
	tostring year_start, gen(year_n)
	tostring year_end, gen(end_year_n)
	tostring nid, gen(nid_n)
	local filename = survey_name + "_" + nid_n + "_" + survey_module + "_" + ihme_loc_id + "_" + year_n + "_" + end_year_n
	local filename = subinstr("`filename'", "/", "_",.)
	drop year_n end_year_n nid_n
	memory
	if r(data_data_u)>5.5e+08{
		save "`outpath'/census/`filename'", replace
	}
	else{
		save "`outpath'/survey/`filename'", replace
	}

	clear
	set obs 1
	gen ubcov_id = `id'
	save "`outpath'/logs/`filename'", replace
}
