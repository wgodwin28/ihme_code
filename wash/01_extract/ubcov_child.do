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
local id `1'

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


		run_extract `id', bypass store_vals
		do "/snfs2/HOME/wgodwin/risk_factors/wash/01_extract/custom_code.do"
		local out_dir "`j'/temp/wgodwin/wash_exposure/extract3"
		cap mkdir "`out_dir'/$ihme_loc_id"
		local survey_name = subinstr("$survey_name", "/", "_", .)
		local year_start $year_start
		cap confirm variable empty
		if _rc {
			save "`out_dir'/$ihme_loc_id/`survey_name'_`year_start'", replace
		}
