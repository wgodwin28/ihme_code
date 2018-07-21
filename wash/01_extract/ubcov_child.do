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
local outpath "`2'"

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
		do "/home/j/temp/wgodwin/wash_exposure/custom_code.do"
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
//end
