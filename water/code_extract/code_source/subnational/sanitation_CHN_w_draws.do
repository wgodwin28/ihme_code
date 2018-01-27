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
	local CHN_national 		"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output/gpr_results_s_covar_with_orig_data.dta"
	local CHN_subnational 	"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/CHN"
	local CHN_urbanicity 	"J:/WORK/01_covariates/02_inputs/malnutrition/subnational/CHN/data/CHN_urbanicity.dta"
	local country_codes 	"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
	local graph_folder 		"J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/subnational/chn/model"
	local data_folder 		"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/CHN"

// Load provincial  estimates
	insheet using "`CHN_subnational'/CHN_subnational_covariates.csv", names clear
	keep iso3s year sanitation_mean_mean
	order iso3s year sanitation_mean_mean
	rename (iso3s year sanitation_mean_mean) (iso3 year sanitation_mean_prov)
	replace sanitation_mean_prov=sanitation_mean_prov/100
	
	tempfile sanitation_prov
	save `sanitation_prov', replace

***Covariates***
// load urbanicity data
	use "`CHN_urbanicity'", clear
	keep iso3 year prop_urban
	duplicates drop iso3 year prop_urban, force
	**replace prop_urban = 0.29771885 if year == 1990 & location_name=="Guangdong"
	**replace prop_urban = 0.3908802 if year == 1995 & location_name=="Guangdong"
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

// Load national Water and Sanitation prevalence estimates 
	use "`CHN_national'", clear
	keep if iso3 == "CHN"
	keep iso3 year gpr_draw*
	duplicates drop
	forvalues d = 1/1000 {
	preserve
	keep iso3 year gpr_draw`d'
	rename gpr_draw`d' sanitation_mean_natl`d'
	duplicates drop

	tempfile sanitation_chn
	save `sanitation_chn', replace
	
	//merge with national and subnational estimates for coverage	
	use `ldi', clear
	merge m:1 year using `sanitation_chn', keep(1 3) nogen
	merge m:1 iso3 year using `sanitation_prov', keep(1 3) nogen
	merge 1:1 iso3 year using `urbanicity', keep(1 3) nogen

	
	gen logit_sanitation_mean_natl`d' = logit(sanitation_mean_natl`d')
	gen logit_sanitation_mean_prov = logit(sanitation_mean_prov)
	
	//merge with location names
	merge m:1 iso3 using `codes', keepusing(location_name location_id)
	drop if _merge==2
	drop _merge
	order location_name iso3 year, first
	
	//fix missing covariates
	replace prop_urban = 0.29771885 if year == 1990 & location_name=="Guangdong"
	replace prop_urban = 0.3908802 if year == 1995 & location_name=="Guangdong"
	
	//Run mixed effect regression with: fixed effect - national coverage, ln_LDI, urbanicity ; random slope: ln_LDI, urbanicity; intercept: subnational iso3 - 
	//[BEST MODEL THUS FAR]

	xtmixed logit_sanitation_mean_prov logit_sanitation_mean_natl`d' ln_LDI prop_urban || iso3: ln_LDI prop_urban
	predict logit_pred`d', fit
		
	gen pred`d' = invlogit(logit_pred`d')
	
	//save individual draws
	if `d'==1 {
	keep iso3 year pred`d'
	tempfile draws
	save `draws', replace
		} 
	else
		{
	keep iso3 year pred`d'
	merge 1:1 iso3 year using `draws', keep(1 3) nogen
	save `draws', replace
	}
	
	restore
}

//save draws for subnational estimates
use `draws', clear
merge m:1 iso3 year using `sanitation_prov', keep(1 3) nogen
merge m:1 iso3 using `codes', keepusing(location_name location_id) keep(1 3) nogen

egen sanitation_prov_pred_mean = rowmean(pred*)
egen sanitation_prov_pred_upper = rowpctile(pred*), p(97.5)
egen sanitation_prov_pred_lower = rowpctile(pred*), p(2.5)

**drop pred*
sort iso3 year
save "`data_folder'/sanitation_chn.dta", replace

**save for covariates database**
keep iso3 year location_id sanitation_prov_pred_mean
rename sanitation_prov_pred_mean mean_value
tostring(location_id), replace
replace iso3 = "CHN" + "_" + location_id
destring(location_id), replace

save "`data_folder'/sanitation_chn_cov.dta", replace

//GRAPH RESULTS with draws
	
	// Graph regression 
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graph_folder'/compare_sanitation_CHN_draws.pdf"

			levelsof location_name, local(locs)
			preserve
			foreach loc of local locs {
				keep if location_name == "`loc'"
					twoway line sanitation_prov_pred_mean year, lcolor(teal) lpattern(solid) || ///
					line sanitation_prov_pred_lower year, lcolor(teal) lpattern(dash) || ///
					line sanitation_prov_pred_upper year, lcolor(teal) lpattern(dash) || ///
					scatter sanitation_mean_prov year, mcolor(black) ///
					ylabel(0(0.2)1) xlabel(1980(5)2010) title("Improved Sanitation") subtitle("`loc'") xtitle("Year", size(small)) ytitle("Proportion with coverage", size(small))legend(size(small)) 	
				
				pdfappend
				
				restore, preserve
			}
			
		pdffinish
		
		restore


// END OF FILE 