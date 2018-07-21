// Janky extraction for BRA census 2010
// 7/27/16

//Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Additional Comments: 
clear all
set more off
capture log close
capture restore, not
set maxvar 20000

// set relevant locals
local input_dir "$j/temp/wgodwin"
local output_dir "$j/temp/wgodwin"

// Import and clean variables
use "`input_dir'/small", clear

gen isanitation_indic = .
replace isanitation_indic = 1 if sewage == 11 | sewage == 12 | sewage == 10 | sewage == 20
replace isanitation_indic = 0 if sewage == 00

gen isewer_indic = .
replace isewer_indic = 1 if sewage == 11 | sewage == 12 | sewage == 10 // septic or sewer system
replace isewer_indic = 0 if sewage == 00 | sewage == 20

gen iwater_indic = .
replace iwater_indic = 1 if watsup == 11 | watsup == 16 | watsup == 20
replace iwater_indic = 0 if watsup == 00

gen ipiped_indic = .
replace ipiped_indic = 1 if watsup == 11 | watsup == 16 
replace ipiped_indic = 0 if watsup == 00 | watsup == 20

// Prep survey design object and calculate mean
local exposures isanitation isewer iwater ipiped
foreach exp of local exposures {
	svyset [pweight=hhwt], strata(strata)
		svy: mean `exp'_indic 
			matrix mean_matrix = e(b)
			local mean_scalar = mean_matrix[1,1]
			gen `exp'_mean = `mean_scalar'

			matrix variance_matrix = e(V)
			local se_scalar = sqrt(variance_matrix[1,1])
			gen `exp'_sem = `se_scalar'

	}
	count
	gen sample_size = `r(N)'	
keep if _n < 5
save "`output_dir'/output", replace
