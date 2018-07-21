**Purpose: Prep prevalence data for modelling
**Date: 05/15/2014
**Author: Astha KC
// Edited: Will Godwin
// Date: 12/10/15

**housekeeping
clear all
set more off

**set relevant locals
local prev_folder  			"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"
local get_demo				"J:/WORK/10_gbd/00_library/functions/get_demographics.ado"
local get_location			"J:/WORK/10_gbd/00_library/functions/get_location_metadata.ado"
local get_covar				"J:/WORK/10_gbd/00_library/functions/get_covariate_estimates.ado"
local merge_2013			"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr output"
local mean					"hwws_pred"
local se					"hwws_pred_se"

**covariates & location variables
// only LDI proved to be a significant covariate
// Prep for spacetime by creating square dataset
	// Generate file with all country years
	run "`get_demo'"
	get_demographics, gbd_team("cov") make_template clear
		
	// Customize for specific risk factor modeling
	duplicates drop location_id year_id, force
	replace age_group_id = 22
	replace sex_id = 3
	tempfile demograph
	save `demograph', replace
	
	// Prep to merge on ihme_loc_id from get_location_metadata central function
	run "`get_location'"
	get_location_metadata, location_set_id(9) clear
	keep location_id ihme_loc_id region_name super_region_id super_region_name location_name
	tempfile loc_id
	save `loc_id', replace
	
	// Merge on ihme_loc_id to demographics square
	use `demograph', clear
	merge m:1 location_id using `loc_id', nogen keep (1 3)
	save `demograph', replace
	
	// Prep literature for model run
	import delimited "J:/WORK/05_risk/risks/wash_hygiene/data/exp/me_id/input_data/01_data_audit/compile/HWWS_lit_clean.csv", clear
	keep if usable==1
	drop usable reason
	
	// Generate ratio to crosswalk self-report handwashing to gold standard of direct observation
	// Ratio calculated from Korean paper "A Nationwide Survey on the Hand Washing Behavior and Awareness" 2007
	local self_report 	.7485
	local direct		.6345
	local hw_ratio 		`direct'/`self_report'
	di in red `hw_ratio'
	replace hwws_prev = hwws_prev * `hw_ratio' if self_report == 1
	tempfile data
	save `data', replace
	
/*	// Prep dataset for merge and merge on nids
	use "`prev_folder'/hygiene_final.dta", clear
	tempfile data
	save `data', replace
*/
	use "`prev_folder'/hygiene_compiled", clear
	keep reference nid year iso3
	rename year year_id
	tempfile nid 
	save `nid', replace
	use `data', clear
	merge 1:1 iso3 year_id reference using `nid', keep (1 3) nogen
	rename iso3 ihme_loc_id
	save `data', replace
	
	// Merge onto square
	use `demograph', clear
	merge 1:m ihme_loc_id year_id using `data', nogen keep (1 3) keepusing(hwws_se hwws_prev nid)
	tempfile final_data
	save `final_data', replace
rename startyear year_id
rename iso3 ihme_loc_id
	// Merge on covariates
	local covariates maternal_educ_yrs_pc sds ldi_pc education_yrs_pc prop_urban
	foreach covar of local covariates {
	preserve
	run "`get_covar'"
	get_covariate_estimates, covariate_name_short("`covar'") clear
	capture duplicates drop location_id year_id, force
	tempfile `covar'
	save ``covar'', replace
	restore
	merge m:1 location_id year_id using "``covar''", nogen keepusing(mean_value) keep(1 3)
	rename mean_value `covar'
	}
	run "`get_covar'"
	get_covariate_estimates, covariate_name_short(maternal_educ_yrs_pc) clear
	capture duplicates drop location_id year_id, force
	tempfile maternal 
	save `maternal', replace

	run "`get_covar'"
	get_covariate_estimates, covariate_name_short(sds) clear
	capture duplicates drop location_id year_id, force
	tempfile sds 
	save `sds', replace

	get_covariate_estimates, covariate_name_short(education_yrs_pc) clear
	capture duplicates drop location_id year_id, force
	tempfile education
	save `education', replace
	
	use `final_data', clear
	merge m:1 location_id year_id using `maternal', nogen keepusing(mean_value) keep(1 3)
	rename mean_value maternal_educ
	merge m:1 location_id year_id using `education', nogen keepusing(mean_value) keep(1 3)
	rename mean_value education_yrs_pc
		
	**save data
		gen me_name = "wash_hwws"
		rename hwws_prev data
		
		// variance calculation
		gen variance = hwws_se^2
		summarize variance, detail
		
		gen sample_size = .
		gen standard_deviation = .
		replace variance = . if data == .
		replace variance = .002 if variance == 0 & data != .
		// replace prop_urban = .9999 if prop_urban == 1
		// replace data = .00001 if data == 0
		// replace data = .9999 if data >= 1 & data <= 2
		// replace data = . if data >= .9999999
		merge m:1 ihme_loc_id year_id using "`merge_2013'/hwws_mean", keep(1 3) nogen
		keep me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation maternal_educ ihme_loc_id
		order me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation maternal_educ ihme_loc_id
		replace nid = . if data == .
		save "J:/temp/wgodwin/gpr_input/run1/wash_hwws4", replace


/*
/**explore covariates
xtmixed hwws_prev ldi_pc || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev year || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev maternal_educ || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev prop_urban || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev piped_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev sanitation_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:

xtmixed hwws_prev ldi_pc year || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev ldi_pc maternal_educ || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev ldi_pc prop_urban || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev ldi_pc piped_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev ldi_pc sanitation_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:

xtmixed hwws_prev ldi_pc year maternal_educ prop_urban piped_mean sanitation_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:*/
*/