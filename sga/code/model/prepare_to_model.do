// File Purpose: Prepare small for gestational age data for older two gestational groups for ST-GPR
// Author: Will Godwin
// Date: 6/15/2016

// Additional Comments: 
clear all
set more off
capture log close
capture restore, not

** create locals for relevant files and folders
local input_folder 				"J:/temp/wgodwin/sga/data/04_get_estimates"
local functions					"J:/WORK/10_gbd/00_library/functions"
local get_demo					"`functions'/get_demographics.ado"
local get_location				"`functions'/get_location_metadata.ado"
local get_covar					"`functions'/get_covariate_estimates.ado"
local get_nid					"J:/WORK/01_covariates/common/ubcov_central/_functions/get_nid.ado"

// Prep and clean data
import excel "`input_folder'/sga_lit.xlsx", firstrow clear

// Drop any implausible values. 
//Note that we're not able to generate sex-specific models b/c the ratios/sga thresholds calculated from microdata to crosswalk were average between male/female.
	replace sga_est_bin3= . if sga_est_bin3 > .5 | sga_est_bin3 < 0.0004
	replace sga_est_bin4= . if sga_est_bin4 > .5 | sga_est_bin4 < 0.0004
	keep location_id country year_end birthweightbin sga_est_bin3 sga_est_bin4 nid sex_id
	rename (country year_end) (location_name year_id)
	tempfile data
	save `data', replace

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
	
	// Prep dataset for merge
	use `data', clear
	tempfile data
	save `data', replace
	
	// Merge onto square
	use `demograph', clear
	merge 1:m location_id year_id using `data', nogen keep (1 3)
	tempfile final_data
	save `final_data', replace

// merge on covariates
local covariates smoking_prev_repro 
// ldi_pc prop_urban sds health_system_access2 pct_births_in_over35s smok_prev_agestd_f maternal_educ_yrs_pc
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
forvalues x = 3/4 {
preserve
gen me_name = "sga_group_`x'"
gen sample_size = .
gen standard_deviation = .
rename sga_est_bin`x' data
gen variance = (data * (1-data))/1000 // assume sample size of 1000
keep me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation smoking_prev_repro ihme_loc_id region_name super_region_name location_name
order me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation smoking_prev_repro ihme_loc_id region_name super_region_name location_name

save "J:/temp/wgodwin/gpr_input/sga/sga_group_`x'", replace
restore
}

// Regression and covariates exploration
gen lg_smoke_repro = logit(smoking_prev_repro)
gen logit_sga_group_3 = logit(data)
xtmixed logit_sga_group_3 lg_smoke_repro || super_region_name: || region_name: || location_name: 
predict re*, reffect
table super_region_name, c(mean re1 mean re2 mean re3)

gen ln_sga3 = logit(sga_est_bin3)
gen ln_sga4 = logit(sga_est_bin4)
gen ln_ldi = ln(ldi_pc)
gen logit_urban = logit(prop_urban)
gen logit_smk_repro = logit(smoking_prev_repro)
gen logit_smk_fem = logit(smok_prev_agestd_f)
gen logit_pct_brth_35 = logit(pct_births_in_over35s)
gen logit_sds = logit(sds)
regress ln_sga3 maternal_educ_yrs_pc
regress ln_sga3 logit_smk_fem
regress ln_sga3 logit_smk_repro
xtmixed ln_sga3 logit_smk_fem || super_region_name: || region_name:
xtmixed ln_sga3 logit_smk_repro || super_region_name: || region_name:
regress ln_sga3 health_system_access2
regress ln_sga3 logit_pct_brth_35
regress ln_sga3 ln_ldi
regress ln_sga3 logit_sds
regress ln_sga4 maternal_educ_yrs_pc
regress ln_sga4 logit_smk_fem
regress ln_sga4 logit_smk_repro
xtmixed ln_sga4 logit_smk_fem || super_region_name: || region_name:
xtmixed ln_sga4 logit_smk_repro || super_region_name: || region_name:
regress ln_sga4 health_system_access2
regress ln_sga4 logit_pct_brth_35
regress ln_sga4 ln_ldi
regress ln_sga4 logit_sds


// Prep for Kelly's gpr viz by adding ihme_loc_id and me_name
local functions					"J:/WORK/10_gbd/00_library/functions"
local get_demo					"`functions'/get_demographics.ado"
local get_location				"`functions'/get_location_metadata.ado"
	
	// run get_locations to merge on ihme_loc_id
	run "`get_location'"
	get_location_metadata, location_set_id(9) clear
	keep location_id ihme_loc_id
	tempfile loc_id
	save `loc_id', replace

	import delimited "J:/temp/wgodwin/gpr_output/sga/group_4_0623.csv", clear
	merge m:1 location_id using `loc_id', nogen keep (1 3)
	gen me_name = "sga_group_4"
	export delimited "J:/temp/wgodwin/gpr_output/sga/group_4_0623.csv", replace
