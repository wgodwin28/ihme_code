// Ella Sanman
// March 1, 2012
// water exposure prep code
//updated 07/01/2014 to save draws for new WSH categories

//Script to run things on the cluster
//do  "/home/j/WORK/01_covariates/02_inputs/water_sanitation/code/03_final_prep/water_exp_prep_code_new.do"

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
	local date				"08152014"

	local country_codes 	"$j/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
	local water_prev_draws  "$j/WORK/01_covariates/02_inputs/water_sanitation/output_data/risk_factors/newcat_final_prev_water_`date'.dta"
	local out_dir_draws		"/clustertmp/WORK/05_risk/02_models/02_results"
	local out_dir_means		"$j/WORK/05_risk/02_models/02_results"
	local rf_new			"wash_water"
	local output_version	5

	
//prep country codes
	use "`country_codes'", clear
	drop if iso3 == ""
	tostring(location_id), replace
	replace iso3 = gbd_country_iso3 + "_" + location_id if gbd_country_iso3!=""
	tempfile codes
	save `codes', replace
	
//prep prevalence draws for water

**keep estimates for GBD years only
use "`water_prev_draws'", clear
keep if year==1990 | year==1995 | year==2000 | year==2005 | year==2010 | year==2013

	forvalues d = 1/1000 {
		local n = `d'-1
		rename (prev_piped_t_`d' prev_piped_t2_`d' prev_piped_untr_`d' prev_imp_t_`d' prev_imp_t2_`d' prev_imp_untr_`d' ///
			prev_unimp_t_`d' prev_unimp_t2_`d' prev_unimp_untr_`d')  (exp_cat9_`n' exp_cat8_`n' exp_cat7_`n' exp_cat6_`n' ///
			exp_cat5_`n' exp_cat4_`n' exp_cat3_`n' exp_cat2_`n' exp_cat1_`n')
		}
		
merge m:1 iso3 using `codes', keep(1 3) keepusing(gbd_non_developing) nogen 
		
**reshape dataset to produce a long dataset
forvalues n = 0/999 {
	preserve
		keep iso3 year *_`n' gbd_non_developing gbd_analytical_region_name 
		rename (exp_cat9_`n' exp_cat8_`n' exp_cat7_`n' exp_cat6_`n' exp_cat5_`n' exp_cat4_`n' exp_cat3_`n' exp_cat2_`n' exp_cat1_`n') ///
				(exp_cat9 exp_cat8 exp_cat7 exp_cat6 exp_cat5 exp_cat4 exp_cat3 exp_cat2 exp_cat1)
		reshape long exp, i(iso3 year gbd_non_developing gbd_analytical_region_name) j(parameter) string
		rename exp exp_`n'
		replace parameter = "cat1" if regexm(parameter, "cat1")
		replace parameter = "cat2" if regexm(parameter, "cat2")
		replace parameter = "cat3" if regexm(parameter, "cat3")
		replace parameter = "cat4" if regexm(parameter, "cat4")
		replace parameter = "cat5" if regexm(parameter, "cat5")
		replace parameter = "cat6" if regexm(parameter, "cat6")
		replace parameter = "cat7" if regexm(parameter, "cat7")
		replace parameter = "cat8" if regexm(parameter, "cat8")
		replace parameter = "cat9" if regexm(parameter, "cat9")
		tempfile draw_`n'
		save `draw_`n'', replace
	restore
	}
	
**compile all draws into a single file
	use `draw_0' , clear
	forvalues i = 1/999  {
	merge 1:1 iso3 year parameter using `draw_`i'', keep(1 3) keepusing(exp_`i') nogen
	}
			
//generate necessary variables
	rename iso3 whereami_id
	gen risk = "`rf_new'"
	gen sex= 3 /*both sexes*/
	gen gbd_age_start = 0
	gen gbd_age_end = 80

//Generate 10th exposure category for developing countries
	expand 2 if parameter == "cat9" & (gbd_non_developing == 0 & gbd_analytical_region_name!="Southern Latin America" & gbd_analytical_region_name!="Eastern Europe" & gbd_analytical_region_name!="Central Europe"), gen(id) 
	replace parameter = "cat10" if id == 1
	forvalues n = 0/999 {
			replace exp_`n' = 0 if parameter == "cat10"
		}
			
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