// File Name: squeeze handwashing draws.do

// File Purpose: Use GPR draws to estimate final exposure categories for sanitation
// Author: Astha KC 
// Date:9/29/2014


clear all
set mem 500m
set more off
set maxvar 30000
capture restore, not

** create locals for relevant files and folders
local code_folder 			"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/code"
local spacetime_folder 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/smoothing/spacetime_results_san"
local gpr_input_folder 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr input"
local gpr_results_folder 	"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr output"
local graph_folder 			"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/output/graphs"

local country_codes			"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"

local san_draws 			"J:/WORK/01_covariates/02_inputs/water_sanitation/output_data/risk_factors/newcat_final_prev_san_08152014.dta"

**prep country codes
use "`country_codes'"
drop if iso3==""
tostring(location_id), replace
gen new_iso3 = gbd_country_iso3 + "_" + location_id if gbd_country_iso3!=""
replace new_iso3=iso3 if new_iso3==""
keep iso3 new_iso3 
tempfile codes
save `codes', replace 

**prep gpr draws
foreach m in "hw_imp" "hw_unimp" "hw_sewer" "hwws"{

	use "`gpr_results_folder'/gpr_results_`m'.dta", clear
	keep iso3 year gpr_draw*
	
	forvalues n = 1/1000 {
		rename gpr_draw`n' `m'`n'
	}
	
	tempfile `m'
	save ``m'', replace 
	
	if "`m'"=="hw_imp" {
		use ``m'', clear
		tempfile compiled
		save `compiled', replace
		}
	else {
		use `compiled', clear
		merge 1:1 iso3 year using ``m'', keep(1 3) nogen
		save `compiled', replace
		
		}
	} 
	
**fix subnational ids
merge m:1 iso3 using `codes', keep(1 3) nogen
rename (iso3 new_iso3) (old_iso3 iso3)

	**merge with draws of houshold sanitation facility coverage
	merge 1:1 iso3 year using "`san_draws'", keep(3) nogen
	
	forvalues n = 1/1000 {
		gen new_hw`n' = hw_imp`n'*iimproved_`n' + hw_unimp`n'*iunimp_`n' + hw_sewer`n'*isewer_`n'
		gen hw_ratio`n' = new_hw`n'/hwws`n'
		
		**rescale all handwashing proportions
		foreach m in "hw_imp" "hw_unimp" "hw_sewer" {
			replace `m'`n' = `m'`n'/hw_ratio`n'
		}
		
		**check to see if squeezing of draws worked
		gen final_hw`n' = hw_imp`n'*iimproved_`n' + hw_unimp`n'*iunimp_`n' + hw_sewer`n'*isewer_`n'
		gen final_ratio`n' = final_hw`n'/hwws`n' /*for successful squeezing of draws the ratio should equal 1*/
		
		}
		
	**keep necessary vars
	keep iso3 old_iso3 year hw_imp* iimproved* hw_unimp* iunimp* hw_sewer* isewer*
	
	**generate final draws for each category
	forvalues n = 1/1000 {

		gen hw_improved_`n' = hw_imp`n' * iimproved_`n'
		gen nohw_improved_`n' = (1-hw_imp`n')*iimproved_`n'
		
		gen hw_unimproved_`n' = hw_unimp`n' * iunimp_`n'
		gen nohw_unimproved_`n' = (1-hw_unimp`n') * iunimp_`n'
		
		gen hw_sewer_`n' = hw_sewer`n' * isewer_`n'
		gen nohw_sewer_`n' = (1-hw_sewer`n') * isewer_`n'
	}
	
	**ensure that all 6 categories add up to 1 for every draw
	keep iso3 old_iso3 year hw_improved* hw_unimproved* hw_sewer_* nohw*
	forvalues n = 1/1000 {
		gen sum`n' = hw_improved_`n' + nohw_improved_`n' + hw_unimproved_`n' + nohw_unimproved_`n' + hw_sewer_`n' + nohw_sewer_`n'
		}
	drop sum*
	
  **save file
  save "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\output\final\san_final_draws_10032014.dta", replace 
	
*****************
****end of code***
*****************