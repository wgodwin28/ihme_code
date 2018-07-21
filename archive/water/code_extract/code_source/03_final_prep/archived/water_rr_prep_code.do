//Filename: water_rr_prep.do
//July 1, 2014
//Purpose: Prepare and save draws and mean estimates for WSH Relative Risks 
//updated 07/01/2014 to save draws for new WSH categories

//Script to run things on the cluster
//do  "/home/j/WORK/01_covariates/02_inputs/water_sanitation/code/03_final_prep/water_rr_prep_code.do"

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
	
			
** Create RR template
	** Make up a few causes
	clear
	set obs 9
	
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
	
	**gen causes
	expand 2, gen(copy)
	gen acause = "diarrhea" if copy==0
	replace acause = "intest_paratyph" if copy==1 
	
	drop copy
	expand 2 if acause=="diarrhea", gen(copy)
	replace acause = "intest_typhoid" if copy == 1
	drop copy
	
	**piped + boil/filter
	gen rr_mean = 1 if parameter == "cat9"
	gen rr_upper = 1 if parameter == "cat9"
	gen rr_lower = 1 if parameter == "cat9"
	
	**piped + chlorine/solar
	replace rr_mean = 1.547169811 if parameter == "cat8"
	replace rr_lower = 1.457082593 if parameter == "cat8"
	replace rr_upper = 1.642826862 if parameter == "cat8"
	
	**piped + no boil/filter/chlorine/solar
	replace rr_mean = 1.886792453 if parameter == "cat7"
	replace rr_lower = 1.661189345 if parameter == "cat7"
	replace rr_upper = 2.593761882 if parameter == "cat7"
	
	**improved(other than piped) + boil/filter
	replace rr_mean = 1.155844156 if parameter == "cat6"
	replace rr_lower = 1.12409837 if parameter == "cat6"
	replace rr_upper = 1.188486478 if parameter == "cat6"
	
	**improved(other than piped) + chlorine/solar
	replace rr_mean = 1.788287185 if parameter == "cat5"
	replace rr_lower = 1.625141344 if parameter == "cat5"
	replace rr_upper = 1.967811025 if parameter == "cat5"
	
	**improved(other than piped) + no boil/filter/chlorine/solar
	replace rr_mean = 2.18083803 if parameter == "cat4"
	replace rr_lower = 1.823696999 if parameter == "cat4"
	replace rr_upper = 2.593761882 if parameter == "cat4"
	
	**unimproved + boil/filter
	replace rr_mean = 1.298701299 if parameter == "cat3"
	replace rr_lower = 1.209779197 if parameter == "cat3"
	replace rr_upper = 1.363387656 if parameter == "cat3"
	
	**unimproved + chlorine/solar
	replace rr_mean = 2.009311443 if parameter == "cat2"
	replace rr_lower = 1.733414969 if parameter == "cat2"
	replace rr_upper = 2.294481665 if parameter == "cat2"
	
	**unimproved + no boil/filter/chlorine/solar 
	replace rr_mean = 2.450379809 if parameter == "cat1"
	replace rr_lower = 1.805640593 if parameter == "cat1"
	replace rr_upper = 3.325335746 if parameter == "cat1"
	
	** Create two categories and 1000 draws
	gen sd = ((ln(rr_upper)) - (ln(rr_lower))) / (2*invnormal(.975))
	forvalues draw = 0/999 {
		gen rr_`draw' = exp(rnormal(ln(rr_mean), sd))
	}	
	
	***************************
	** Save draws on clustertmp**
	***************************
	cap mkdir "`out_dir_draws'/`rf_new'/rr/`output_version'"
	outsheet risk year gbd_age_start gbd_age_end sex morbidity mortality acause parameter rr* using "`out_dir_draws'/`rf_new'/rr/`output_version'/rr_G.csv", comma replace
	
	***************************************
	** Save mean/lower/upper on the J drive**
	***************************************
	cap mkdir "`out_dir_means'/`rf_new'/rr/`output_version'"
	outsheet risk year gbd_age_start gbd_age_end sex morbidity mortality acause parameter rr_mean rr_lower rr_upper using "`out_dir_means'/`rf_new'/rr/`output_version'/rr_G.csv", comma replace

	
*******************************
**********end of code***********
*******************************