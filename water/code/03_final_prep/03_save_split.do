//Extrapolate csmr from 5 year points to the full 1980 to 2015 time period
set more off

//input arguments
local location_dir `1'
local save_dir `2'
local exp `3'
local loc `4'
local date 03242016
// di "`location_dir' `save_dir' `exp' `loc'"

/*
// Debugging 
local base_file "J:/WORK/05_risk/risks/wash_water/data/exp/me_id/uploaded/rough_output/imp_t_03142016"
local save_dir "C:/Users/wgodwin/Desktop"
local exp imp_t
local loc 6 
*/

//Load the data file

// By year, save a file-clean up data for save_results
use "`location_dir'/`exp'/`loc'", clear
	rename `exp'_* draw_*
	keep age_group_id year_id draw_*
		forvalues y = 1980/2016 {
			preserve
			keep if year_id == `y'
			expand 20
				// split into sex categories
				foreach obs in 1 2 {
					local counter = 1
					// expand out to all age group id's
					forvalues x = 2/21 {
						replace age_group_id = `x' if _n==`counter'
						local counter = `counter' + 1
						}
					cap mkdir "`save_dir'/run1/`exp'"
					cap drop year_id
					export delimited "`save_dir'/run1/`exp'/18_`loc'_`y'_`obs'.csv", replace
				}
				restore
			}
end