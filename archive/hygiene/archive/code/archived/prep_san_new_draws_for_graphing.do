
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
local country_codes 	"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"

**prep country codes
use "`country_codes'", clear
drop if iso3==""
keep iso3 location_name
tempfile codes
save `codes', replace 

	
	**prep data
	use "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\output\final\san_final_draws_10032014.dta", clear
	drop iso3
	rename old_iso3 iso3 
	merge m:1 iso3 using `codes', keepusing(location_name) keep(1 3) nogen
	
	**generate mean**
	egen hw_improved_mean = rowmean(hw_improved_*)
	egen nohw_improved_mean = rowmean(nohw_improved_*)
	egen hw_unimproved_mean = rowmean(hw_unimproved_*)
	egen nohw_unimproved_mean = rowmean(nohw_unimproved_*)
	egen hw_sewer_mean = rowmean(hw_sewer_*)
	egen nohw_sewer_mean = rowmean(nohw_sewer_*)
	
	keep iso3 location_name year *mean
	rename (hw_sewer_mean nohw_sewer_mean hw_improved_mean nohw_improved_mean hw_unimproved_mean nohw_unimproved_mean) ///
		(exp_cat6 exp_cat5 exp_cat4 exp_cat3 exp_cat2 exp_cat1)
	
	order iso3 location_name year, first
	reshape long exp_cat, i(iso3 location_name year) j(cat) 
	rename exp_cat exp_prev
	gen exp_cat = cat
	drop cat
	
	**Change reverse order**
	tostring(exp_cat), replace
	replace exp_cat = "Sewer w/ handwashing"  if exp_cat=="6"
	replace exp_cat = "Sewer w/o handwashing" if exp_cat=="5"
	replace exp_cat = "Improved w/ handwashing" if exp_cat=="4"
	replace exp_cat = "Improved w/o handwashing" if exp_cat=="3"
	replace exp_cat = "Unimproved w/ handwashing" if exp_cat=="2"
	replace exp_cat = "Unimproved w/o handwashing" if exp_cat=="1"
	
	drop if exp_prev==.
	
	**save prepped data
	saveold "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/output/graphs/stacked_graph_cats_10032014.dta", replace
	
