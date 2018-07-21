// Author: Will Godwin
// Purpose: Split observations by location_id and save in share folder
clear all
set more off
cap restore, not

// Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Pass in arguments
local location_dir `1'
local input_dir `2'
local loc `3'
local date `4'

*** Debugging ***
// local location_dir 		"H:/unimp/run1"
// local input_dir "$j/temp/wgodwin/save_results/wash_hygiene/rough_output"
// local loc 7
// local date 04152016

use "`input_dir'/hwws_final_v5", clear
		keep if location_id == `loc'
		keep location_id year_id age_group_id hwws_final_*
		expand 2, gen(tag)
		gen sex_id = 1 if tag==0
		replace sex_id = 2 if tag==1
		drop tag
			forvalues x = 2/21 {
				replace age_group_id = `x'
				tempfile temp_`x'
				save `temp_`x'', replace
			}
			use `temp_2', clear
				forvalues x = 3/21 {
					append using `temp_`x''
				}
			gen measure_id = 18
		forvalues n = 0/999 {
		rename hwws_final_`n' draw_`n'
			}
	export delimited "`location_dir'/`loc'", replace
