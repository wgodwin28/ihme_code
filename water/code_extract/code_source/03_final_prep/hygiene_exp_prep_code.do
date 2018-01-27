**Filename: hygiene_exp_prep_code.do
**Purpose: Save exposure draws for handwashing. Want to calculate the burden of handwashing separately. 
**Date: Dec 3 2014
**Author: Astha KC	

//Script to run things on the cluster
//do  "/home/j/WORK/01_covariates/02_inputs/water_sanitation/code/03_final_prep/hygiene_exp_prep_code.do"

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
	local country_codes 		"$j/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
	local hygiene_prev_draws  	"$j/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr output/gpr_results_hwws.dta"
	local out_dir_draws			"/clustertmp/WORK/05_risk/02_models/02_results"
	local out_dir_means			"$j/WORK/05_risk/02_models/02_results"
	local rf_new				"wash_hygiene"
	local output_version		1

//prep country codes
use "`country_codes'", clear
drop if iso3==""
tostring(location_id), replace
gen new_iso3 = gbd_country_iso3 + "_" + location_id if gbd_country_iso3!=""
replace new_iso3 = iso3 if new_iso3==""
tempfile codes
save `codes', replace

//prep prevalence draws
**keep estimates for GBD years only
use "`hygiene_prev_draws'", clear
keep if year==1990 | year==1995 | year==2000 | year==2005 | year==2010 | year==2013

//order is based on levels of risk
** handwashing = cat 2, no handwashing = cat 1 

	forvalues d = 1/1000 {
		local n = `d'-1
		rename (gpr_draw`d') (exp_cat2_`n')
		gen exp_cat1_`n' = 1 - exp_cat2_`n'
		}
		
**reshape dataset to produce a long dataset
forvalues n = 0/999 {
	preserve
		keep iso3 year *_`n'
		rename (exp_cat2_`n' exp_cat1_`n') (exp_cat2 exp_cat1)
		reshape long exp, i(iso3 year) j(parameter) string
		rename exp exp_`n'
		replace parameter = "cat1" if regexm(parameter, "cat1")
		replace parameter = "cat2" if regexm(parameter, "cat2")
		replace parameter = "cat3" if regexm(parameter, "cat3")
		tempfile draw_`n'
		save `draw_`n'', replace
	restore
		}
	
**compile all draws into a single file
	use `draw_0' , clear
	forvalues i = 1/999 {
	merge 1:1 iso3 year parameter using `draw_`i'', keep(1 3) keepusing(exp_`i') nogen
		}
		
**swap out old iso3s with new iso3s
	merge m:1 iso3 using `codes', keepusing(new_iso3) keep(1 3) nogen
	drop iso3
	rename new_iso3 iso3 
		
//generate necessary variables
	rename iso3 whereami_id
	gen risk = "`rf_new'"
	gen sex= 3 /*both sexes*/
	gen gbd_age_start = 0
	gen gbd_age_end = 80
			
			
//Generate final list of iso3s for which we need to generate estimates
adopath + "$j/WORK/04_epi/01_database/01_code/04_models/prod"
get_demographics, type(epi) subnational(yes)
local iso3 = "$iso3s"

	***************************
	** Save draws on clustertmp**
	***************************
	cap mkdir "`out_dir_draws'/`rf_new'/exp/`output_version'"
	order risk whereami_id year gbd_age_start gbd_age_end sex parameter
	
	foreach loc of local iso3 	{
	outsheet risk year gbd_age_start gbd_age_end sex parameter exp* using "`out_dir_draws'/`rf_new'/exp/`output_version'/exp_`loc'.csv" if whereami_id == "`loc'", comma replace
	}
		
	***************************************
	** Save mean/lower/upper on the J drive**
	***************************************
	cap mkdir "`out_dir_means'/`rf_new'/exp/`output_version'"
	egen exp_mean = rowmean(exp_*)
	egen exp_lower = rowpctile(exp_*), p(2.5)
	egen exp_upper = rowpctile(exp_*), p(97.5)
	keep risk whereami_id year gbd_age_start gbd_age_end sex parameter exp_mean exp_lower exp_upper
	
	foreach loc of local iso3  {
	outsheet risk year gbd_age_start gbd_age_end sex parameter exp* using "`out_dir_means'/`rf_new'/exp/`output_version'/exp_`loc'.csv" if whereami_id == "`loc'", comma replace
	}
	
****************
***end of code***
****************