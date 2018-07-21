//Filename: sanitation_rr_prep.do
//July 1, 2014
//Purpose: Prepare and save draws and mean estimates for WSH Relative Risks 
//updated 07/01/2014 to save draws for new WSH categories
//updated 12/03/2014 to save draws for sanitation without hygiene for diarrhea ONLY. Removing typhoid and paratyphoid as outcomes
//updated 03/10/2015 added typhoid and paratyphoid fevers as outcomes

//Script to run things on the cluster
//do  "/home/j/WORK/01_covariates/02_inputs/water_sanitation/code/03_final_prep/sanitation_rr_prep_code.do"

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
	local rf_new			"wash_sanitation"
	local output_version	6
	
** Create RR template
	** Make up a few causes
	clear
	set obs 3
	
	** Risk
	gen risk = "`rf_new'"
	gen gbd_age_start = 0
	gen gbd_age_end = 80
	gen sex = 3
	gen year = 0 
	gen mortality = 1 
	gen morbidity = 1 
	
	**gen parameter
	gen id = _n
	tostring(id), replace
	gen parameter = "cat" + id
	drop id 
	
	gen acause = "diarrhea" 
	
	**gen causes
	expand 2, gen(copy)
	replace acause = "intest_paratyph" if copy==1 
	
	drop copy
	expand 2 if acause=="diarrhea", gen(copy)
	replace acause = "intest_typhoid" if copy == 1
	drop copy

	//Sanitation Categories//
	
	**sewer 
	gen rr_mean = 1 if parameter == "cat3"
	gen rr_lower = 1 if parameter == "cat3"
	gen rr_upper = 1 if parameter == "cat3"
	
	**improved (other than sewer)
	replace rr_mean = 2.709677419 if parameter == "cat2"
	replace rr_lower = 2.527777778 if parameter == "cat2"
	replace rr_upper = 2.851851852 if parameter == "cat2"
	
	**unimproved 
	replace rr_mean = 3.225806452 if parameter == "cat1"
	replace rr_lower = 2.777777778 if parameter == "cat1"
	replace rr_upper = 3.703703704 if parameter == "cat1"
	
	** Create two categories and 1000 draws
	gen sd = ((ln(rr_upper)) - (ln(rr_lower))) / (2*invnormal(.975))
	forvalues draw = 0/999 {
		gen rr_`draw' = exp(rnormal(ln(rr_mean), sd))
	}	
	
	***************************************
	** Save mean/lower/upper on the J drive**
	***************************************
	cap mkdir "`out_dir_means'/`rf_new'/rr/`output_version'"
	outsheet risk year gbd_age_start gbd_age_end sex morbidity mortality acause parameter rr_mean rr_lower rr_upper using "`out_dir_means'/`rf_new'/rr/`output_version'/rr_G.csv", comma replace

	***************************
	** Save draws on clustertmp**
	***************************
	cap mkdir "`out_dir_draws'/`rf_new'/rr/`output_version'"
	drop *mean *lower *upper 
	outsheet risk year gbd_age_start gbd_age_end sex morbidity mortality acause parameter rr* using "`out_dir_draws'/`rf_new'/rr/`output_version'/rr_G.csv", comma replace
	
*******************************
**********end of code***********
*******************************