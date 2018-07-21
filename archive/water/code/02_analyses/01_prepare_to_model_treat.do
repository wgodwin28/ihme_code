// File Name: prepare_for_spacetime.do
// File Purpose: merge on covariates to prepare for spacetime for HWT categories
// Author: Astha KC 
// Date: 3/13/2014
// Edited: Will Godwin
// Date: 12/14/15

// Additional Comments: 

//Housekeeping
clear all 
set more off

//Set relevant locals
local country_codes 	"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
local compile_folder 	"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/data/compile"
local merge_2013		"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/02_Analyses/data/08072014/gpr_output"
local graphloc			"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/graphs"
local functions			"J:/WORK/10_gbd/00_library/functions"
local get_demo			"`functions'/get_demographics.ado"
local get_location		"`functions'/get_location_metadata.ado"
local get_covar			"`functions'/get_covariate_estimates.ado"
local get_nid			"J:/WORK/01_covariates/common/ubcov_central/_functions/get_nid.ado"

local hwt_spacetime		"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/02_Analyses/data/08062014"
local input_folder		"J:/WORK/05_risk/risks/wash_water/data/exp/2533/input_data"
local it				3

// open dataset
use "`compile_folder'/prev_newcats_all_08062014.dta", clear

	**check to see if categories add up to 100%
	foreach source in "piped" "improved" "unimproved" {
		egen `source'_total = rowtotal(tr_`source'_mean* untr_`source'_mean*)
	}
	
	drop if piped_total==0 &  improved_total==0 & unimproved_total==0
	drop *total

// Clean up and prepare to merge onto square dataset	
	rename startyear year_id
	gen national = 1 
	drop countryname region filepath_full endyear svytype_sp svy svyver_real module version svyver tag2 nopsu noweight svytype national
	rename iso3 ihme_loc_id
	egen filepath_full = concat (filedir filename), p("/")
	tempfile data
	save `data', replace

// Merge on missing nids
	qui run "`get_nid'"
	get_nid, filepath_full(filepath_full)
	rename record_nid nid

// Hard code any sources that didn't match nid
	replace nid = 26998 if filename == "COD_MICS4_2010_HH_FR_Y2012M01D10.DTA"
	replace nid = 165212 if filename == "BTN_MICS4_2010_HH_Y2012M04D05.dta"
	drop filedir filename
	tempfile cit_data
	save `cit_data', replace

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
	merge 1:m ihme_loc_id year_id using `cit_data', nogen keep (1 3)
	tempfile final_data
	save `final_data', replace
 

// Astha just wanted to try out a bunch of covariates. Postulated that water source type might help explain HWT variation. It didn't, the only covariate with enough strength turned out to be LDI.
// merge with spacetime prevalence of any HWT use by water source type  
/* 
rename ihme_loc_id iso3
rename year_id year
foreach source in "piped" "imp" "unimp" {
	merge m:1 iso3 year using "`hwt_spacetime'/w_`source'_t2_B_time_series.dta", keepusing(step2_prev) keep(1 3) nogen
	rename step2_prev `source'_t2_prev
}
rename iso3 ihme_loc_id
rename year year_id
// Generate proportion variables so that each indicator is proportion of specific treatment (boil/filter in this case) by water source type improved, piped, or unimproved
********* I think this step is unnecessary and incorrect because the variables already appear to be in proportion form **************

gen prop_itreat_piped_mean = itreat_piped_mean / piped_t2_prev
gen prop_itreat_improved_mean = itreat_improved_mean / imp_t2_prev
gen prop_itreat_unimp_mean = itreat_unimproved_mean / unimp_t2_prev

gen prop_tr_piped_mean = tr_piped_mean / piped_t2_prev
gen prop_tr_improved_mean = tr_improved_mean / imp_t2_prev
gen prop_tr_unimp_mean = tr_unimproved_mean / unimp_t2_prev

gen prop_itreat_piped_sem = itreat_piped_sem
gen prop_itreat_improved_sem = itreat_improved_sem
gen prop_itreat_unimp_sem = itreat_unimproved_sem
*/
gen prop_itreat_piped_mean = itreat_piped_mean
gen prop_itreat_imp_mean = itreat_improved_mean
gen prop_itreat_unimp_mean = itreat_unimproved_mean

gen prop_itreat_piped_sem = itreat_piped_sem
gen prop_itreat_imp_sem = itreat_improved_sem
gen prop_itreat_unimp_sem = itreat_unimproved_sem

gen prop_tr_piped_mean = tr_piped_mean
gen prop_tr_imp_mean = tr_improved_mean
gen prop_tr_unimp_mean = tr_unimproved_mean

gen prop_tr_piped_sem = tr_piped_sem
gen prop_tr_imp_sem = tr_improved_sem
gen prop_tr_unimp_sem = tr_unimproved_sem

tempfile check
save `check', replace


// use `check', clear

// MERGE ON COVARIATES
local covariates ldi_pc education_yrs_pc prop_urban sds
foreach covar of local covariates {
	preserve
	run "`get_covar'"
	get_covariate_estimates, covariate_name_short("`covar'") clear
	capture duplicates drop location_id year_id, force
	tempfile `covar'
	save ``covar'', replace
	restore
	merge m:1 location_id year_id using ``covar'', nogen keepusing(mean_value) keep(1 3)
	rename mean_value `covar'
	
	}


save "`input_folder'/smoothing_dataset_prop_HWT`it'", replace
// use "`input_folder'/smoothing_dataset_prop_HWT`it'", clear

local exposures itreat_piped itreat_imp itreat_unimp tr_piped tr_imp tr_unimp
	foreach exposure of local exposures {
		preserve
		gen me_name = "wash_water_`exposure'"
		rename prop_`exposure'_mean data
		gen variance = ((prop_`exposure'_sem)^2)
		summarize variance, detail		
		// Excluding state level IND data b/c we only model at the rural/urban level.
			replace data = . if location_id >= 4841 & location_id <= 4875
			replace variance = . if location_id >= 4841 & location_id <= 4875
		// Confirm that all values are between 0-1 for GPR
			replace variance = . if data == .
			replace variance = .002 if variance == 0
			replace data = .01 if data == 0
			replace data = .99 if data >= 1 & data <= 2
			replace prop_urban=.9999 if prop_urban==1
		*** NEED TO CHANGE THIS TO SET APPROPRIATE FLOOR ***
			generate sample_size = (data * (1 - data))/(variance)	
			gen standard_deviation = .
		keep me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation ldi_pc prop_urban education_yrs_pc sds ihme_loc_id
		order me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation ldi_pc prop_urban education_yrs_pc sds ihme_loc_id
		replace nid = . if data == .
		if "`exposure'" == "itreat_piped" {
			merge m:1 ihme_loc_id year_id using "`merge_2013'/piped_treat_mean", keep(1 3) nogen
}
		if "`exposure'" == "itreat_imp" {
			merge m:1 ihme_loc_id year_id using "`merge_2013'/imp_treat_mean", keep(1 3) nogen
}
		if "`exposure'" == "itreat_unimp" {
			merge m:1 ihme_loc_id year_id using "`merge_2013'/unimp_treat_mean", keep(1 3) nogen
}
		if "`exposure'" == "tr_piped" {
			merge m:1 ihme_loc_id year_id using "`merge_2013'/piped_treat2_mean", keep(1 3) nogen
}
		if "`exposure'" == "tr_imp" {
			merge m:1 ihme_loc_id year_id using "`merge_2013'/imp_treat2_mean", keep(1 3) nogen
}
		if "`exposure'" == "tr_unimp" {
			merge m:1 ihme_loc_id year_id using "`merge_2013'/unimp_treat2_mean", keep(1 3) nogen
}	
		save "J:/temp/wgodwin/gpr_input/hwt/wash_water_`exposure'`it'", replace
		restore
}

// Explore covariates
gen lg_itreat_imp= logit(prop_itreat_imp_mean)
gen lg_itreat_piped= logit(prop_itreat_piped_mean)
gen ln_ldi = log(ldi_pc)
xtmixed lg_itreat_imp ln_ldi || super_region_name: || region_name: || location_name:
xtmixed lg_itreat_piped ln_ldi || super_region_name: || region_name: || location_name:

xtmixed lg_itreat_imp sds || super_region_name: || region_name: || location_name:
xtmixed lg_itreat_imp education_yrs_pc || super_region_name: || region_name: || location_name:
xtmixed lg_itreat_imp education_yrs_pc sds || super_region_name: || region_name: || location_name: