**Filename: compile_surveys.do
**Author: Astha KC
**Purpose: Compile a singular dataset combining literature and survey extractions
clear all
set more off

	//Set relevant locals
	local data_audit 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"
	local functions			"J:/WORK/10_gbd/00_library/functions"
	local get_demo			"`functions'/get_demographics.ado"
	local get_location		"`functions'/get_location_metadata.ado"
	local get_covar			"`functions'/get_covariate_estimates.ado"
	local source_dir		"J:/DATA/Incoming Data/WORK/05_risk/1_ready/final_risk_citation_lists"
	local get_nid			"J:/WORK/01_covariates/common/ubcov_central/_functions/get_nid.ado"
	local merge_2013		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr output"

	
	**DHS**
	use "`data_audit'/DHS/dhs_all_m_tab_2015.dta", clear
	rename (file hwws_mean) (filepath_full hwws_prev)
	compress
	merge 1:1 filepath_full using "`data_audit'/DHS/datfiles_dhs.dta", keep(1 3) nogen
	rename (iso3 countryname) (ihme_loc_id location_name)
	drop tag2
	tempfile dhs
	save `dhs', replace

	**MICS**
	use "`data_audit'/MICS/mics_all_m_tab_2015.dta", clear
	merge 1:1 file using "`data_audit'/MICS/mics_all_m_tab.dta", keep(1 3)
	replace hwws_mean = handwashing_1 if _m!=1
	replace hwws_se = handwashing_se if _m!=1
	drop _m
	rename (file hwws_mean) (filepath_full hwws_prev)
	merge 1:1 filepath_full using "`data_audit'/MICS/datfiles_mics.dta", keep(1 3) nogen
	append using `dhs', force

	**merge nids
	qui run "`get_nid'"
	get_nid, filepath_full(filepath_full)
	rename record_nid nid
	rename endyear year
	destring year, replace

	**fill in missing nids from other 
		**Benin DHS 2011-2012**
		replace nid = 79839 if ihme_loc_id == "BEN" & year == 2011
		
		**Indonesia DHS 2012**
		replace nid = 76705 if ihme_loc_id == "IDN" & year==2012
		
		**Senegal DHS 2012-2013**
		replace nid = 111432 if ihme_loc_id == "SEN" & year==2013
		
		**Tunisia MICS 2011-2012**
		replace nid = 76709 if ihme_loc_id == "TUN" & year==2011

		**Bhutan MICS 2010**
		replace nid = 40028 if ihme_loc_id == "BTN" & year==2010

	rename year year_id
	tempfile all_estimates
	save `all_estimates', replace

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
		keep location_id ihme_loc_id
		tempfile loc_id
		save `loc_id', replace
	
	// Merge on ihme_loc_id to demographics square
		use `demograph', clear
		merge m:1 location_id using `loc_id', nogen keep (1 3)
		save `demograph', replace
	
	// Merge onto square
		merge 1:m ihme_loc_id year_id using `all_estimates', nogen keep (1 3)
		tempfile final_data
		save `final_data', replace


local covariates health_system_access2 sanitation_prop SBA_coverage_prop SEV_agestd_scalar_Diarrhea SEV_wash_sanitation prop_urban SEV_scalar_Maternal
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
 	// Merge on covariates
	local covariates education_yrs_pc maternal_educ_yrs_pc sds ldi_pc health_system_access2 sanitation_prop SBA_coverage_prop SEV_agestd_scalar_Diarrhea
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

	// Generate necessary modeling variables
		gen me_name = "wash_hwws_dhs"
		rename hwws_prev data
		
	// Variance calculation
		gen variance = hwws_se^2
		summarize variance, detail
		
	// Clean up and save
		// replace data = . if data==0
		gen standard_deviation = .
		replace variance = . if data == .
		replace variance = .002 if variance == 0 & data != .
		replace data = . if data == 0
		// replace data = .00001 if data == 0
		replace data = .9999 if data >= 1 & data <= 2
		merge m:1 ihme_loc_id year_id using "`merge_2013'/hwws_mean", keep(1 3) nogen
		keep me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation education_yrs_pc maternal_educ_yrs_pc sds ldi_pc ihme_loc_id
		order me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation education_yrs_pc maternal_educ_yrs_pc sds ldi_pc ihme_loc_id
		replace nid = . if data == .
		save "J:/temp/wgodwin/gpr_input/run1/wash_hwws_dhs2", replace


// Covariate exploration
gen lg_hwws = logit(data)
gen ln_ldi = log(ldi_pc)
gen ln_hsa = log(health_system_access2)
gen lg_san = logit(sanitation_prop)
gen lg_SBA = logit(SBA_coverage_prop)
gen lg_SEV_san = logit(SEV_wash_sanitation)
gen lg_urban = logit(prop_urban)
regress lg_hwws ln_ldi education_yrs_pc
xtmixed lg_hwws ln_ldi || super_region_name: || region_name: || ihme_loc_id:
xtmixed lg_hwws maternal_educ_yrs_pc || super_region_name: || region_name: || location_name:
xtmixed lg_hwws education_yrs_pc || super_region_name: || region_name: || location_name:
xtmixed lg_hwws sds || super_region_name: || region_name: || location_name:
xtmixed lg_hwws sanitation_prop || super_region_name: || region_name: || location_name:
xtmixed lg_hwws ln_hsa || super_region_name: || region_name: || location_name:
xtmixed lg_hwws lg_san || super_region_name: || region_name: || location_name:
xtmixed lg_hwws lg_SBA || super_region_name: || region_name: || location_name:
xtmixed lg_hwws SEV_agestd_scalar_Diarrhea || super_region_name: || region_name: || location_name:
xtmixed lg_hwws lg_SEV_san || super_region_name: || region_name: || location_name:
xtmixed lg_hwws lg_urban || super_region_name: || region_name: || location_name:
xtmixed lg_hwws SEV_scalar_Maternal || super_region_name: || region_name: || location_name:




xtmixed isanitation_mean urban ldi education_yrs_pc || super_region_name: || region_name: || ihme_loc_id:

/*use "`data_audit'/hygiene_compiled.dta", clear
gen logit_hwws_prev = logit(hwws_prev)

xtmixed logit_hwws_prev reference_data || gbd_analytical_superregion_name: || gbd_analytical_region_name: || location_name: || reference: 
replace reference_data = 1

gen logit_hwws_pred = logit_hwws_prev* `e(b)' if reference==0
predict logit_hwws_pred, stdp

matrix m = e(b)
matrix m = m[1,1]

matrix C = e(V)
matrix C = C[1,1]

local beta
drawnorm beta, n(1000) means(m) cov(C)*/
