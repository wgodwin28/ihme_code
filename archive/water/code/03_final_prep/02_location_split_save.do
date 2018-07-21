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
local location_dir 		`1'
local input_dir 		`2'
local loc 				`3'
local exp 				`4'
local ages "2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 30 31 32 235"
local age_app "3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 30 31 32 235"

*** Debugging ***
// local exposures 		"imp_t imp_t2"
// local location_dir 		"H:/unimp/run1"
// local input_dir "$j/temp/wgodwin/save_results/wash_water/rough_output"
// local loc 7
// local date 04102016

use "`input_dir'/`exp'", clear
keep if location_id == `loc'
		keep location_id year_id age_group_id prev_`exp'_*
		expand 2, gen(tag)
		gen sex_id = 1 if tag==0
		replace sex_id = 2 if tag==1
		drop tag

			foreach x of local ages {
				replace age_group_id = `x'
				tempfile temp_`x'
				save `temp_`x'', replace
			}

			use `temp_2', clear
			foreach x of local age_app {
				append using `temp_`x''
			}
			gen measure_id=18
	forvalues n = 0/999 {
		rename prev_`exp'_`n' draw_`n'
	}
	order location_id sex_id age_group_id measure_id draw_*
	cap mkdir "`location_dir'/`exp'"
		export delimited "`location_dir'/`exp'/`loc'", replace
