// /////////////////////////////////////////////////
// CONFIGURE ENVIRONMENT
// /////////////////////////////////////////////////

	if c(os) == "Unix" {
		global prefix "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global prefix "J:"
	}

// /////////////////////////////////////////////////
// CONFIGURATION COMPLETE 
// /////////////////////////////////////////////////
clear all
set more off

//Set appropriate locals
	**local CHN_national 				"C:/Users/asthak/Documents/Covariates/Water and Sanitation/model/gpr_output/gpr_results_w_covar.dta"
	local CHN_national				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output/gpr_results_w_covar_with_orig_data.dta"
	local CHN_subnational 			"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/CHN"
	local CHN_statistical_yearbook 	"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/CHN/CHN_water_statistical_yearbook.csv"
	local CHN_urbanicity 			"J:/WORK/01_covariates/02_inputs/malnutrition/subnational/CHN/data/CHN_urbanicity.dta"
	local country_codes 			"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
	local graph_folder 				"J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/subnational/chn/model"
	local data_folder 				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/CHN"

// Load provincial  estimates

	**NHSS**
	insheet using "`CHN_subnational'/CHN_subnational_covariates.csv", names clear
	keep iso3s year water_mean_mean
	order iso3s year water_mean_mean
	rename (iso3s year water_mean_mean) (iso3 year water_mean_prov)
	replace water_mean_prov=water_mean_prov/100
	gen source_name = "National Health Services Survey" 
	
	tempfile water_prov
	save `water_prov', replace
	
	**statistical yearbook**
	insheet using "`CHN_statistical_yearbook'", names clear
	keep iso3 year percentofruralpopulationwithacce source_name 
	rename percentofruralpopulationwithacce water_mean_prov
	replace water_mean_prov = water_mean_prov/100 
	append using `water_prov'
	
	drop if water_mean_prov==.
	save `water_prov', replace

***Covariates***
// load urbanicity data
	use "`CHN_urbanicity'", clear
	keep iso3 year prop_urban
	duplicates drop iso3 year prop_urban, force

	**fill in missing urbanicity numbers
	expand 2 if iso3=="XCB" & year==1989, gen(id)
	replace year = 1990 if id == 1 
	drop id 
	
	expand 2 if iso3=="XCB" & year==1994, gen(id)
	replace year = 1995 if id == 1 
	drop id 
	
	tempfile urbanicity
	save `urbanicity', replace
	
//load ldi pc
	use "J:/WORK/01_covariates/02_inputs/LDI_pc/model/subnational/CHN_ldi_pc.dta", clear
	keep iso3 year LDI_id
	drop if year<1980 | year>2013
	gen ln_LDI = ln(LDI_id)	
	tempfile ldi
	save `ldi', replace

//location/country codes
	use "`country_codes'", clear
	drop if iso3==""
	tempfile codes
	save `codes', replace

	
//weighting the rural coverage prop to estimate national
	use `water_prov', clear
	merge m:1 iso3 year using `urbanicity', keep(1 3) nogen
	
	replace water_mean_prov = (prop_urban*water_mean_prov) + ((1-prop_urban)*1) if regexm(source_name, "China Health") 
	
// Load national Water and Sanitation prevalence estimates 
	use "`CHN_national'", clear
	keep if iso3 == "CHN"
	keep iso3 year gpr_draw*
	duplicates drop
	tempfile national
	save `national', replace
	
	forvalues d = 1/1000 {
	preserve
	keep iso3 year gpr_draw`d'
	rename gpr_draw`d' water_mean_natl`d'
	duplicates drop

	tempfile water_chn
	save `water_chn', replace
	
	//merge with national and subnational estimates for coverage	
	use `ldi', clear
	merge m:1 year using `water_chn', keep(1 3) nogen
	merge m:1 iso3 year using `urbanicity', keep(1 3) nogen
	merge m:m iso3 year using `water_prov', keep(1 3) nogen
	**merge 1:1 iso3 year using `urbanicity', keep(1 3) nogen
	
	gen logit_water_mean_natl`d' = logit(water_mean_natl`d')
	gen logit_water_mean_prov = logit(water_mean_prov)
	
	//merge with location names
	merge m:1 iso3 using `codes', keepusing(location_name location_id)
	drop if _merge==2
	drop _merge
	order location_name iso3 year, first
	
	//Run mixed effect regression with: fixed effect - national coverage, ln_LDI, urbanicity ; random slope: ln_LDI, urbanicity; intercept: subnational iso3 - 
	//[BEST MODEL THUS FAR]

	xtmixed logit_water_mean_prov logit_water_mean_natl`d' ln_LDI prop_urban || iso3: ln_LDI prop_urban, iter(1000)
	predict logit_pred`d', fit
		
	gen pred`d' = invlogit(logit_pred`d')
	
	//save individual draws
	if `d'==1 {
	keep iso3 year pred`d'
	duplicates drop 
	tempfile draws
	save `draws', replace
		} 
	else
		{
	keep iso3 year pred`d'
	duplicates drop 
	merge 1:1 iso3 year using `draws', keep(1 3) nogen
	save `draws', replace
	}
	
	restore
}

//save draws for subnational estimates
use `draws', clear
merge m:1 iso3 using `codes', keepusing(location_name location_id) keep(1 3) nogen
merge m:1 year using `national', keepusing(gpr_draw*) keep(1 3) nogen
merge m:m iso3 year using `water_prov', keep(1 3) nogen

egen water_prov_pred_mean = rowmean(pred*)
egen water_prov_pred_upper = rowpctile(pred*), p(97.5)
egen water_prov_pred_lower = rowpctile(pred*), p(2.5)

egen natl_mean = rowmean(gpr_draw*)

**drop pred*
sort iso3 year
save "`data_folder'/water_chn.dta", replace

**save for covariates database** /*TEMPORARY SOLUTION*/
replace water_prov_pred_mean = natl_mean

keep iso3 year location_id water_prov_pred_mean
rename water_prov_pred_mean mean_value
tostring(location_id), replace
replace iso3 = "CHN" + "_" + location_id
destring(location_id), replace

replace mean_value = 0.9355126 if iso3=="CHN_496" & year==1990
replace mean_value = 0.9593528 if iso3=="CHN_496" & year==1995

save "`data_folder'/water_chn_cov.dta", replace

//GRAPH RESULTS with draws
	
	// Graph regression 
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graph_folder'/compare_water_CHN_draws_new.pdf"

			levelsof location_name, local(locs)
			preserve
			foreach loc of local locs {
				keep if location_name == "`loc'"
					twoway line water_prov_pred_mean year, lcolor(teal) lpattern(solid) || ///
					line water_prov_pred_lower year, lcolor(teal) lpattern(dash) || ///
					line water_prov_pred_upper year, lcolor(teal) lpattern(dash) || ///
					scatter water_mean_prov year, mcolor(black) ///
					ylabel(0(0.2)1) xlabel(1980(5)2010) title("Improved Water") subtitle("`loc'") xtitle("Year", size(small)) ytitle("Proportion with coverage", size(small))legend(size(small)) 	
				
				pdfappend
				
				restore, preserve
			}
			
		pdffinish
		
		restore


***********************************************
***************Graph Data**********************
***********************************************

		// Graph regression 
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graph_folder'/compare_water_CHN_data.pdf"

			levelsof location_name, local(locs)
			preserve
			foreach loc of local locs {
				keep if location_name == "`loc'"
					scatter water_mean_prov year if source_name == "National Health Services Survey", mcolor(black) || ///
					scatter water_mean_prov year if source_name != "National Health Services Survey", mcolor(pink)  ///
					ylabel(0(0.2)1) xlabel(1980(5)2010) title("Improved Water") subtitle("`loc'") xtitle("Year", size(small)) ytitle("Proportion with coverage", size(small))legend(size(small)) 	
				
				pdfappend
				
				restore, preserve
			}
			
		pdffinish
		
		restore

// END OF FILE 