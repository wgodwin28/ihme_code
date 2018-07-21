//// File Name: gen_prev_newcat.do
// File Purpose: combine output from proportion models to split each source type group by HWT use 
// Author: Astha KC 
// Date: 3/17/2014

// Additional Comments: 

//Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

//Housekeeping
clear all 
set more off
set maxvar 30000

//Set relevant locals
local source_results	"$j/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output"
local source_CHN		"$j/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/CHN"
local source_MEX		"$j/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/MEX"

local prop_results		"$j/WORK/01_covariates/02_inputs/water_sanitation/new_categories/02_Analyses/data/08072014/gpr_output"
local graphloc 			"$j/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/graphs"
local country_codes 	"$j/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
local dataloc			"$j/WORK/01_covariates/02_inputs/water_sanitation/new_categories/03_Final_Prep/output"

local final_output		"$j/WORK/01_covariates/02_inputs/water_sanitation/output_data/risk_factors"

local date "08152014"

//Prep the country codes file
	use `country_codes', clear
	drop if iso3==""
	tempfile codes
	save `codes', replace

//Prep GPR draws of exposure by access to piped or improved water sources

	//improved water
	use "`source_results'/gpr_results_w_covar_with_orig_data.dta", clear
	keep iso3 year gpr_draw*
	duplicates drop 
	forvalues n = 1/1000 {
		rename gpr_draw`n' iwater_mean`n'
		gen iunimp_mean`n' = 1 - iwater_mean`n'
		}
	
	tempfile natl_water
	save `natl_water', replace
	
	use "`source_CHN'/water_chn.dta", clear
	keep iso3 year *pred*
	duplicates drop iso3 year, force
	forvalues n = 1/1000 {
		rename pred`n' iwater_mean`n'
		gen iunimp_mean`n' = 1 - iwater_mean`n'
		}
	
	tempfile chn_water
	save `chn_water', replace
	
	use "`source_MEX'/water_mex_draws.dta", clear
	keep iso3 year *pred*
	forvalues n = 1/1000 {
		rename water_prov_pred`n' iwater_mean`n'
		gen iunimp_mean`n' = 1 - iwater_mean`n'
		}
	
	tempfile mex_water
	save `mex_water', replace

	//piped water
	use "`source_results'/gpr_results_piped_covar_with_orig_data.dta", clear
	keep iso3 year gpr_draw*
	duplicates drop
	merge 1:1 iso3 year using `natl_water', keep(1 3) nogen
	forvalues n = 1/1000 {
		rename gpr_draw`n' ipiped_mean`n'
		gen iimp_mean`n' = iwater_mean`n' - ipiped_mean`n'
		}
	tempfile natl_water_cats
	save `natl_water_cats', replace
	
	use "`source_CHN'/piped_chn.dta", clear
	keep iso3 year pred*
	merge 1:1 iso3 year using `chn_water', keep(1 3) nogen
	forvalues n = 1/1000 {
		rename pred`n' ipiped_mean`n'
		gen iimp_mean`n' = iwater_mean`n' - ipiped_mean`n'
		}
	tempfile chn_water_cats
	save `chn_water_cats', replace
	
	use "`source_MEX'/piped_mex_draws.dta", clear
	keep iso3 year *pred*
	merge 1:1 iso3 year using `mex_water', keep(1 3) nogen
	forvalues n = 1/1000 {
		rename piped_prov_pred`n' ipiped_mean`n'
		gen iimp_mean`n' = iwater_mean`n' - ipiped_mean`n'
		}
	
	tempfile mex_water_cats
	save `mex_water_cats', replace

//Prep draws from proportion models - use national estimates to split source draws for subnational locations because we don't have data on HWT subnationally

local models "imp_treat imp_treat2 piped_treat piped_treat2 unimp_treat unimp_treat2"
foreach model of local models {
	use "`prop_results'/gpr_results_`model'.dta", clear
	sort iso3 year
	keep iso3 year gpr_draw*
	
		forvalues n = 1/1000 {
			rename gpr_draw`n' prop_`model'`n'
			}
	
	tempfile `model'
	save ``model'', replace
} 

//merge all draws
**national**
use `natl_water_cats', clear
local sources imp unimp piped

foreach source of local sources {
merge m:1 iso3 year using ``source'_treat' , keepusing(prop_`source'_treat*) nogen keep(1 3)
merge m:1 iso3 year using ``source'_treat2', keepusing(prop_`source'_treat2*) nogen keep(1 3)

	forvalues d = 1/1000 {
		gen prop_`source'_untr`d' = 1 - (prop_`source'_treat2`d')
		rename prop_`source'_treat2`d' prop_`source'_any_treat`d'
		gen prop_`source'_treat2`d' = prop_`source'_any_treat`d' - prop_`source'_treat`d'
	}
}

tempfile compiled_draws
save `compiled_draws', replace

**mexico**
use `mex_water_cats', clear
rename iso3 new_iso3
gen iso3 = "MEX"
local sources imp unimp piped
foreach source of local sources {
merge m:1 iso3 year using ``source'_treat' , keepusing(prop_`source'_treat*) nogen keep(1 3)
merge m:1 iso3 year using ``source'_treat2', keepusing(prop_`source'_treat2*) nogen keep(1 3)

	forvalues d = 1/1000 {
		gen prop_`source'_untr`d' = 1 - (prop_`source'_treat2`d')
		rename prop_`source'_treat2`d' prop_`source'_any_treat`d'
		gen prop_`source'_treat2`d' = prop_`source'_any_treat`d' - prop_`source'_treat`d'
	}
}

replace iso3 = new_iso3 
drop new_iso3 

append using `compiled_draws'
save `compiled_draws', replace

**china**
use `chn_water_cats', clear
rename iso3 new_iso3
gen iso3 = "CHN"
local sources imp unimp piped
foreach source of local sources {
merge m:1 iso3 year using ``source'_treat' , keepusing(prop_`source'_treat*) nogen keep(1 3)
merge m:1 iso3 year using ``source'_treat2', keepusing(prop_`source'_treat2*) nogen keep(1 3)

	forvalues d = 1/1000 {
		gen prop_`source'_untr`d' = 1 - (prop_`source'_treat2`d')
		rename prop_`source'_treat2`d' prop_`source'_any_treat`d'
		gen prop_`source'_treat2`d' = prop_`source'_any_treat`d' - prop_`source'_treat`d'
	}
	
}

replace iso3 = new_iso3 
drop new_iso3 

append using `compiled_draws'
save `compiled_draws', replace

**GBR**
**Create a template for subnational GBR
	use "`codes'", clear
	keep if gbd_country_iso3 == "GBR"
	expand 34
	bysort iso3: gen year = 1979+_n
	sort iso3 year
	keep iso3 year
	
	local sources imp unimp piped
	foreach source of local sources {
		
		forvalues n = 1/1000 {
	
		if "`source'" == "piped" {
			gen prev_`source'_t_`n' = 1
			}
		
		else {
		
			gen prev_`source'_t_`n' = 0
			gen prev_`source'_t2_`n' = 0
			gen prev_`source'_untr_`n' = 0 
		
			}
		}
	}
	
	tempfile gbr_template
	save `gbr_template', replace 
	
**********************************************
*******Generate estimates for final categories**********
**********************************************
use `compiled_draws', clear

local sources imp unimp piped
foreach source of local sources {
	
	forvalues n = 1/1000 {
	
	gen prev_`source'_t_`n' = prop_`source'_treat`n' * i`source'_mean`n'
	gen prev_`source'_t2_`n' = prop_`source'_treat2`n'* i`source'_mean`n'
	gen prev_`source'_untr_`n' = prop_`source'_untr`n'* i`source'_mean`n'
	**gen prev_`source'_untr_`n' = i`source'_mean`n' - (prev_`source'_t_`n' + prev_`source'_t2_`n')
	**gen prev_`source'_untr_`n' = i`source'_mean`n'*(1-(prop_`source'_treat`n'+prop_`source'_treat2`n'))
	
	}
		}

keep iso3 year prev_*

**add UK subnationals
append using `gbr_template'

//merge location variables	and format them as needed
merge m:1 iso3 using `codes', keepusing(location_id gbd_country_iso3 gbd_analytical_region_name gbd_analytical_superregion_id gbd_analytical_superregion_name) keep(1 3) nogen

//format iso3s for subnational locations 
tostring(location_id), replace
gen new_iso3 = gbd_country_iso3 + "_" + location_id if gbd_country_iso3!=""
replace iso3 = new_iso3 if new_iso3!=""
destring(location_id), replace
drop new_iso3

//Bin all high income countries into TMRED except Southern Latin America - this includes subnational GBR
forvalues n = 1/1000	 {

	replace prev_piped_untr_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_piped_t2_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_imp_t_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_imp_t2_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_imp_untr_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_unimp_t_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_unimp_t2_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_unimp_untr_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_piped_t_`n' = 1 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America" 
	
	}
	
//for now - replace -ve draws
local sources imp unimp piped
foreach source of local sources {

	local trx untr t t2
	foreach t of local trx {
	
	forvalues n = 1/1000 {

		replace prev_`source'_`t'_`n' = 0.0001 if prev_`source'_`t'_`n' < 0
		
		}
			}
				}
	
//Squeeze in categories to make sure they add up to 1
forvalues n = 1/1000 {
	egen prev_total_`n' = rowtotal(*prev*_`n')
	replace prev_piped_untr_`n' = prev_piped_untr_`n' / prev_total_`n'
	replace prev_piped_t2_`n' = prev_piped_t2_`n'/ prev_total_`n'
	replace prev_imp_t_`n' = prev_imp_t_`n' / prev_total_`n'
	replace prev_imp_t2_`n' = prev_imp_t2_`n' / prev_total_`n'
	replace prev_imp_untr_`n' = prev_imp_untr_`n' / prev_total_`n'
	replace prev_unimp_t_`n' = prev_unimp_t_`n' / prev_total_`n'
	replace prev_unimp_t2_`n' = prev_unimp_t2_`n' / prev_total_`n'
	replace prev_unimp_untr_`n' = prev_unimp_untr_`n' / prev_total_`n'
	replace prev_piped_t_`n' = prev_piped_t_`n' / prev_total_`n'
	}
	
	drop *total*

**save data**
save "`final_output'/newcat_final_prev_water_`date'.dta", replace

//End of Code//
