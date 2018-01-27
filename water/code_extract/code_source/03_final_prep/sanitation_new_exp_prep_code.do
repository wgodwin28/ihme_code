// Ella Sanman
// March 1, 2012
// water exposure prep code
//updated 07/01/2014 to save draws for new WSH categories

//Script to run things on the cluster
//do  "/home/j/WORK/01_covariates/02_inputs/water_sanitation/code/03_final_prep/sanitation_new_exp_prep_code.do"

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
	local date				"07302014"
	
	local country_codes 	"$j/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
	local san_prev_draws 	"$j/WORK/01_covariates/02_inputs/water_sanitation/hygiene/output/final/san_final_draws_10032014.dta"
	local out_dir_draws		"/clustertmp/WORK/05_risk/02_models/02_results"
	local out_dir_means		"$j/WORK/05_risk/02_models/02_results"
	local rf_new			"wash_sanitation"
	local output_version	4

//prep prevalence draws for water

**keep estimates for GBD years only
use "`san_prev_draws'", clear
keep if year==1990 | year==1995 | year==2000 | year==2005 | year==2010 | year==2013

//Sanitation Categories - order is based on levels of risk and should match the categories specified in the relative risks file
	**sewer +  handwashing = cat 6
	**sewer - handwashing = cat5
	**improved (other than sewer) + handwashing = cat4
	**unimproved + handwashing = cat3	
	**improved (other than sewer) - handwashing = cat2
	**unimproved - handwashing = cat1

	forvalues d = 1/1000 {
		local n = `d'-1
		rename (hw_improved_`d' nohw_improved_`d' hw_unimproved_`d' nohw_unimproved_`d' hw_sewer_`d' nohw_sewer_`d') ///
			(exp_cat4_`n' exp_cat3_`n' exp_cat2_`n' exp_cat1_`n' exp_cat5_`n' exp_cat6_`n') 
	
		}
		
**reshape dataset to produce a long dataset
forvalues n = 0/999 {
	preserve
		keep iso3 year *_`n'
		rename (exp_cat3_`n' exp_cat2_`n' exp_cat1_`n') (exp_cat3 exp_cat2 exp_cat1)
		reshape long exp, i(iso3 year) j(parameter) string
		rename exp exp_`n'
		replace parameter = "cat1" if regexm(parameter, "cat1")
		replace parameter = "cat2" if regexm(parameter, "cat2")
		replace parameter = "cat3" if regexm(parameter, "cat3")
		replace parameter = "cat4" if regexm(parameter, "cat4")
		replace parameter = "cat5" if regexm(parameter, "cat5")
		replace parameter = "cat6" if regexm(parameter, "cat6")
		tempfile draw_`n'
		save `draw_`n'', replace
	restore
		}
	
**compile all draws into a single file
	use `draw_0' , clear
	forvalues i = 1/999 {
	merge 1:1 iso3 year parameter using `draw_`i'', keep(1 3) keepusing(exp_`i') nogen
		}
		
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