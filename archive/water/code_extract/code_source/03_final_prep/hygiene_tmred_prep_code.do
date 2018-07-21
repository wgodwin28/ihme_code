**Filename: hygiene_tmred_prep_code.do
**Purpose: Save TMRED distribution for handwashing. Want to calculate the burden of handwashing separately. 
**Date: Dec 3 2014
**Author: Astha KC	

**script to run this from the cluster
**do "/home/j/WORK/01_covariates/02_inputs/water_sanitation/code/03_final_prep/hygiene_tmred_prep_code.do"

//housekeeping
clear
set more off
set maxvar 30000
set obs 2

// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 

**Set relevant locals
	local out_dir_draws		"/clustertmp/WORK/05_risk/02_models/02_results"
	local out_dir_means		"$j/WORK/05_risk/02_models/02_results"
	
	local rf_new			"wash_hygiene" 
	local output_version	1

**Fix TMRED 
	
	**Prep data
	gen risk = "`rf_new'"
	gen gbd_age_start = 0 
	gen gbd_age_end = 80 
	gen sex = 3
	gen year = 0
	
	gen id = _n 
	gen parameter = "cat1" if id==1
	replace parameter = "cat2" if id==2
	drop id

	gen tmred_mean = 1 if parameter=="cat2"
	gen tmred_lower = 1 if parameter=="cat2"
	gen tmred_upper = 1 if parameter=="cat2"
	
	replace tmred_mean = 0 if parameter=="cat1" 
	replace tmred_lower = 0 if parameter=="cat1" 
	replace tmred_upper = 0 if parameter=="cat1"
	
	**generate 1000 draws of TMRED
	forvalues n = 0/999 {
		gen tmred_`n'=.
		replace tmred_`n' = 1 if parameter == "cat3"
		replace tmred_`n' = 0 if parameter != "cat3"
	}
	
	***************************
	** Save draws on clustertmp**
	***************************
	cap mkdir "`out_dir_draws'/`rf_new'/tmred/`output_version'"
	outsheet risk year gbd_age_start gbd_age_end sex parameter tmred* using "`out_dir_draws'/`rf_new'/tmred/`output_version'/tmred_G.csv", comma replace
	
	***************************************
	** Save mean/lower/upper on the J drive**
	***************************************
	cap mkdir "`out_dir_means'/`rf_new'/tmred/`output_version'"
	keep risk year gbd_age_start gbd_age_end sex parameter tmred_mean tmred_lower tmred_upper

	outsheet risk year gbd_age_start gbd_age_end sex parameter tmred* using "`out_dir_means'/`rf_new'/tmred/`output_version'/tmred_G.csv", comma replace

******************************	
**********end of code**********
******************************