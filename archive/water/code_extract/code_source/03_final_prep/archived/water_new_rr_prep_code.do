//Filename: water_new_rr_prep.do
//Date: Oct 13 2014
//Purpose: Prepare and save draws and mean estimates for water Relative Risks new categories that are region specific
//edited 11/18/2014 to remove typhoid/paratyphoid fever as an outcome for WSH risk factors

//Script to run things on the cluster
//do  "/home/j/WORK/01_covariates/02_inputs/water_sanitation/code/03_final_prep/water_new_rr_prep_code.do"

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
	local country_codes 	
	local out_dir_draws		"/clustertmp/WORK/05_risk/02_models/02_results"
	local out_dir_means		"$j/WORK/05_risk/02_models/02_results"
	local rf_new			"wash_water"
	local output_version	6
	
//Prep RRs
	include "$j/WORK/01_covariates/02_inputs/water_sanitation/code/03_final_prep/gen_new_water_rr.do"
			
** Create RR template
	** Risk
	gen risk = "`rf_new'"
	gen gbd_age_start = 0
	gen gbd_age_end = 80
	gen sex = 3
	gen year = 0 
	gen mortality = 1 
	gen morbidity = 1 
	
	**gen causes
	**gen acause = "diarrhea"
	expand 2, gen(copy)
	gen acause = "diarrhea" if copy==0
	replace acause = "intest_paratyph" if copy==1 
	
	drop copy
	expand 2 if acause=="diarrhea", gen(copy)
	replace acause = "intest_typhoid" if copy == 1
	drop copy
	
	//Water categories 
	**piped + boil/filter = cat9 
	**piped + chlorine/solar = cat8
	**piped + no boil/filter/chlorine/solar = piped - hwt = cat7
	**improved(other than piped) + boil/filter = cat6
	**improved(other than piped) + chlorine/solar = cat5
	**improved(other than piped) + no boil/filter/chlorine/solar = improved(other than piped) - hwt = cat4
	**unimproved + boil/filter = cat3
	**unimproved + chlorine/solar = cat2
	**unimproved + no boil/filter/chlorine/solar = unimproved - hwt = cat1
	
	** Create two categories and 1000 draws
	gen sd = ((ln(rr_upper)) - (ln(rr_lower))) / (2*invnormal(.975))
	forvalues draw = 0/999 {
		gen rr_`draw' = exp(rnormal(ln(rr_mean), sd))
	}	
	
	foreach region of local regions {
	
	preserve
	keep if region == "`region'"
	
	***************************
	** Save draws on clustertmp**
	***************************
	cap mkdir "`out_dir_draws'/`rf_new'/rr/`output_version'"
	outsheet risk year gbd_age_start gbd_age_end sex morbidity mortality acause parameter rr* using "`out_dir_draws'/`rf_new'/rr/`output_version'/rr_`region'.csv", comma replace
	
	***************************************
	** Save mean/lower/upper on the J drive**
	***************************************
	cap mkdir "`out_dir_means'/`rf_new'/rr/`output_version'"
	outsheet risk year gbd_age_start gbd_age_end sex morbidity mortality acause parameter rr_mean rr_lower rr_upper using "`out_dir_means'/`rf_new'/rr/`output_version'/rr_`region'.csv", comma replace
	
	restore
	}
*******************************
**********end of code***********
*******************************