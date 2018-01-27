//Filename: water_tmred_prep.do
//July 1, 2014
//Purpose: Prepare and save draws and mean estimates for WSH TMRED 
//updated 07/01/2014 to save draws for new WSH categories

//Script to run things on the cluster
//do  "/home/j/WORK/01_covariates/02_inputs/water_sanitation/code/03_final_prep/water_tmred_prep_code.do"

clear
set more off
set maxvar 30000

// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 
	
//set relevant locals
	local out_dir_draws		"/clustertmp/WORK/05_risk/02_models/02_results"
	local out_dir_means		"$j/WORK/05_risk/02_models/02_results"
	local rf_new			"wash_water"
	local output_version	2
	

//Create variables and format TMRED to match Greg's template
	set obs 1
	gen year = 0 
	gen risk = "`rf_new'"
	gen gbd_age_start = 0
	gen gbd_age_end = 80
	gen sex = 3 
	
	gen parameter = ""
	forvalues n = 1/9 {
		replace parameter = "cat`n'"
		
		if `n'==1 {
			tempfile cats
			save `cats', replace
			}
			
		if `n'!=1 {
			append using `cats'
			save `cats', replace 
		}
			}
			
	duplicates drop 
		
	**generate 1000 draws of TMRED
	forvalues n = 0/999 {
		gen tmred_`n'=.
		replace tmred_`n' = 1 if parameter == "cat9"
		replace tmred_`n' = 0 if parameter != "cat9"
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
	egen tmred_mean = rowmean(tmred_*)
	egen tmred_lower = rowpctile(tmred_*), p(2.5)
	egen tmred_upper = rowpctile(tmred_*), p(97.5)
	keep risk year gbd_age_start gbd_age_end sex parameter tmred_mean tmred_lower tmred_upper

	outsheet risk year gbd_age_start gbd_age_end sex parameter tmred* using "`out_dir_means'/`rf_new'/tmred/`output_version'/tmred_G.csv", comma replace

	
******************************
*******end of code*************
******************************
			