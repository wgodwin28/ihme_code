// ***********************************************************************************************************
//  Author: Patrick Liu (pyliu@uw.edu)																		
//  Date: 7/13/2015
//  Project: ubCov
//  Purpose: Run Script
	//do "/snfs2/HOME/wgodwin/risk_factors2/wash/01_extract/run_wash_local.do"																				
// ***********************************************************************************************************/


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
set more off
set maxvar 10000
set obs 1

// Settings
local central_root "`j'/WORK/01_covariates/common/ubcov_central"
local topics wash

// Load Jun's functions
local jun_root "`j'/temp/jkim118/ubcov_translation"
cd "`jun_root'"
do "`jun_root'/ubcov_translation/get_translated_labels.do"
do "`jun_root'/load_stata_14/load_stata_14.do"

// Load functions
cd "`central_root'"
do "`central_root'/modules/extract/core/load.do"


cd "`central_root'"
// Load the base code for ubCov
local paths  `central_root'/modules/extract/core/ `central_root'/modules/extract/core/addons/
foreach path in `paths' {
	local files : dir "`path'" files "*.do"
	foreach file in `files' {
		if "`file'" != "run.do" do "`path'/`file'"
	}
}

// Make sure you're in central
cd `central_root'

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
// Find sources that haven't been extracted
	local data_dir "`j'/WORK/05_risk/risks/wash_water/data/exp/03_model/best_2016"
	// hap sources
	import delimited "`data_dir'/air_hap.csv", clear
	levelsof nid, l(hap_nids)
	// water sources
	import delimited "`data_dir'/wash_water_piped.csv", clear
	levelsof nid, l(water_nids)
	//sanitation sources
	import delimited "`data_dir'/wash_sanitation_piped.csv", clear
	levelsof nid, l(sani_nids)
	
	//Combine and reduce to unique ones
	local all_nids = "`hap_nids'" + "`water_nids'" + "`sani_nids'"
	local done_nids: list uniq all_nids
	
	//Ubcov nids
	get, codebook
	levelsof nid, l(ub_nids)
	clear
	local num : word count `ub_nids'
	set obs `num'
	gen nid = ""
	
	forvalues n = 1/`num' {
	local ub: word `n' of `ub_nids'
	di "`ub'"
	replace nid = string(`ub') in `n'
	}
	tempfile ub_dt
	save `ub_dt', replace
		
	clear
	local num_done : word count `done_nids'
	set obs `num_done'
	gen nid = ""
	forvalues n = 1/`num_done' {
	local done: word `n' of `done_nids'
	replace nid = string(`done') in `n'
	}
	tempfile done_dt
	save `done_dt', replace
	
	//Merge together!!
	merge 1:1 nid using `ub_dt', keep(2) nogen
	destring nid, replace
	tempfile nids_dt
	save `nids_dt', replace

	// Merge with ubcov codebook and subset to unextracted surveys
	get, codebook
	merge m:1 nid using `nids_dt', keep(3) nogen
	keep if survey_module == "HH"
	keep if year_start > 2010
	drop if regexm(file_path, ".SAV")
	drop if regexm(survey_name, "SP")

//Versioning
local run "run1" //limited to most recent (post 2010 surveys) sources to add important ones for review week

//Set out directory
local outpath = "`j'/LIMITED_USE/LU_GEOSPATIAL/ubCov_extractions/wash_gbd/`run'"
cap mkdir "`outpath'"
cap mkdir "`outpath'/census"

//keep if inlist(ihme_loc_id, "IND", "MEX", "BRA", "CHN", "RUS", "KEN", "ETH", "ZAF")
//local array 6400
//Problem ubcov_ids have issues extracting
drop if ubcov_id == 9083 | ubcov_id == 9065

// drop if ubcov_id <11974
levelsof ubcov_id, l(array)
foreach number in `array'{
	local i `number'
	run_extract `i', bypass store_vals
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
		save "`outpath'/`filename'", replace
	}
}
	// do "`j'/WORK/11_geospatial/07_data extraction/WASH/wash_recodes.do"
