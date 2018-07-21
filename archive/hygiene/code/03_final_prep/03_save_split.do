// Author: Will Godwin
// Purpose: Split observations by sex to prep for save_results for handwashing
// Date: 2/29/16

// Additional Comments: 

// Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Housekeeping
clear all 
set more off
set maxvar 20000

// Set relevant locals
local location_dir 	`1'
local save_dir		`2'
local loc 			`3'
di "`location_dir'" "`save_dir'" `loc'

// use "`input_dir'/hwws_final_`date'", clear
// 		keep if location_id == `loc'
//		keep location_id year_id age_group_id hwws_final_*

// Formatted files for the old save_results
// Loop through year, calculate "no handwashing", and split into sexes and ages
	use "`location_dir'/`loc'", clear
	forvalues y = 1980/2015 {
		preserve
		keep if year_id == `y'
		rename hwws_final_* draw_*
		keep age_group_id draw_*
		expand 20
			// split into sex categories
			foreach obs in 1 2 {
				local counter = 1
				// expand out to all age group id's
				forvalues x = 2/21 {
					replace age_group_id = `x' if _n==`counter'
					local counter = `counter' + 1
					}
				export delimited "`save_dir'/18_`loc'_`y'_`obs'.csv", replace	
				}
			restore
			}
