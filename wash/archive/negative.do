// Hello
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
local in_dir `1'
local file `2'
local save_dir `3'
local ages "2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 30 31 32 235"
local age_app "3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 30 31 32 235"

*** Debugging ***
// local exp	 		"improved"
// local location_dir 		"H:/unimp/run1"
// local input_dir "$j/temp/wgodwin/save_results/wash_water/rough_output"
// local loc 7
// local date 04102016

import delimited "`in_dir'/`file'", clear
		keep location_id year_id age_group_id draw_*
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
		export delimited "`save_dir'/`file'", replace

/* import delimited "`path'/`file'", clear
forvalues x = 0/999 {
	replace draw_`x' = 0.0001 if draw_`x' <= 0
	replace draw_`x' = 0.999 if draw_`x' >= 1
}

export delimited "/share/epi/risk/temp/wash_hwws/review_week/locations2/`file'", replace
*/

end
