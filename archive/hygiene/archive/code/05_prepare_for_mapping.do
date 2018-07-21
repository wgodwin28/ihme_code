// File Name: prepare_for_mapping.do

// File Purpose: Prepare water and sanitation data for mapping
// Author: Leslie Mallinger
// Date: 7/19/2011
// Edited on: 

// Additional Comments: 
clear all
macro drop _all
set mem 500m
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local dat_folder "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr output"
local map_folder "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/output/maps"


** open data with smoothing results
	// water
	use "`dat_folder'/gpr_results_hwws", clear
	egen gpr_mean = rowmean(gpr_draw*)
	rename gpr_mean hwws_prev
	keep iso3 year hwws_prev
	drop if hwws_prev == . 
	drop if year < 1980
	
	
** calculate level for each country in 1980 and 2010
local years 1980 1990 2005 2010 2013
foreach y of local years {
	gen hwws_tmp = hwws_prev*100 if year == `y'

	bysort iso3: egen hwws_`y' = mean(hwws_tmp)
	drop *tmp
}

** reduce to one observation per country
collapse(mean) *1980 *1990 *2005 *2010 *2013, by(iso3)

** save for input to R
saveold "`map_folder'/gpr_results_for_mapping.dta", replace


**************************************************************

** calculate change between 1980 and 2010 for each country
gen water_change = water_2010 - water_1980
gen sanitation_change = sanitation_2010 - sanitation_1980

gen water_mdg_change = water_2010 - water_1990
gen sanitation_mdg_change = sanitation_2010 - sanitation_1990


** calculate MDG stuff
	// proportion of the population without access
	gen no_water_1990 = 1 - water_1990
	gen no_sanitation_1990 = 1 - sanitation_1990
	gen no_water_2010 = 1 - water_2010
	gen no_sanitation_2010 = 1 - sanitation_2010
	
	// annualized rate of decline
		gen decline_rate_san_obs = -100*ln(no_sanitation_2010/no_sanitation_1990)/(2010-1990)
		gen decline_rate_water_obs = -100*ln(no_water_2010/no_water_1990)/(2010-1990)
		gen decline_rate_goal = -100*ln(1/2)/(2015-1990)
		
		count if decline_rate_water_obs != 0 & decline_rate_water_obs > decline_rate_goal
		count if decline_rate_san_obs != 0 & decline_rate_san_obs > decline_rate_goal
		count if decline_rate_water_obs != 0 & decline_rate_water_obs > decline_rate_goal & ///
			decline_rate_san_obs != 0 & decline_rate_san_obs > decline_rate_goal

			
** transform for mapping
local vars water_1980 sanitation_1980  water_2010 sanitation_2010 water_change sanitation_change
foreach var of local vars {
	replace `var' = `var' * 100
}
rename decline_rate_water_obs water_rate
rename decline_rate_san_obs sanitation_rate

** save for input to R
saveold "`map_folder'/gpr_results_for_mapping.dta", replace
	
	

