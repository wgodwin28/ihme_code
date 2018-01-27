// Date: 8/1/16
// Author: Will Godwin
// Edited on: 12/14/15

// Additional Comments: 
clear all
set more off
capture log close
capture restore, not

** create locals for relevant files and folders
local dat_folder_compiled 		"J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Compiled"
local input_folder 				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/smoothing/spacetime input"
local functions					"J:/WORK/10_gbd/00_library/functions"
local get_demo					"`functions'/get_demographics.ado"
local get_location				"`functions'/get_location_metadata.ado"
local get_covar					"`functions'/get_covariate_estimates.ado"
local get_nid					"J:/WORK/01_covariates/common/ubcov_central/_functions/get_nid.ado"
local output_folder				"H:/wash/source_sanitation"
local hwws_input				"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"

adopath + "J:/WORK/10_gbd/00_library/functions"

** open dataset with compiled prevalence estimates; remove unnecessary entries and variables
	// open file
	use "`dat_folder_compiled'/prev_all_final_with_citations.dta", clear
	drop if iso3 == "XIU" | iso3 == "XIR"
	keep nid iso3 startyear endyear filepath_full ipiped_mean ipiped_sem location_name
	drop if regexm(filepath_full, "ROMA")
	duplicates drop nid, force
	tempfile piped
	save `piped', replace

	//open and prep handwashing availability data
	foreach svy in mics dhs {
		use "`hwws_input'/`svy'/`svy'_all_m_tab_2015", clear
			rename file filepath_full
			drop if hwws_mean == 0
			merge 1:1 filepath_full using "`hwws_input'/`svy'/datfiles_`svy'", keepusing(startyear endyear iso3 location_name) keep (1 3) nogen
			cap destring startyear, replace
		tempfile `svy'
		save ``svy'', replace
	}
		append using `mics', force
		qui run "`get_nid'"
		get_nid, filepath_full(filepath_full)
		rename record_nid nid	
		replace nid = 40028 if iso3 == "BTN" & startyear == 2010
		drop if regexm(filepath_full, "ROMA")
		tempfile hwws
		save `hwws', replace
	
	// Merge on piped data with hwws data
	use `piped', replace
	merge 1:1 nid using `hwws'
	gen cw_tag = 1 if _m == 3
	replace cw_tag = 0 if cw_tag == .
	preserve
		keep if cw_tag == 1
		drop if hwws_mean == 0
		regress hwws_mean ipiped_mean
