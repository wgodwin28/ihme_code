// Compare old water treatment RR with new ones from new Review
// Date: 6/21/2016

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

// Set relevant locals
local data_dir	"$j/WORK/05_risk/risks/wash_water/data/rr/data"
local log_dir 	"$j/WORK/05_risk/risks/wash_water/data/rr/documentation"

// Import and clean dataset
	import excel "`data_dir'/review_studies_info.xlsx", clear firstrow
		foreach var in effectsize lower95confidenceinterval upper95confidenceinterval numberofobservations {
			destring `var', replace force
		}
	gen log_se = log((upper95 - lower95)/3.92)
	gen log_effect = log(effectsize)
	gen se = (upper95 - lower95)/3.92

// tempfile both treatment options (filter or chlorine/solar)
	keep if regexm(intervention, "POU")
	drop if effectsize == .
	tempfile all
	save `all', replace

	drop if regexm(intervention, "filter")
	tempfile chlo_all
	save `chlo_all', replace

	use `all', clear
	keep if regexm(intervention, "filter")
	tempfile filter_all
	save `filter_all', replace

// Conduct meta-analysis on each
	log using "`log_dir'/new_studies_comparison", replace
	di in red "Below are results including new meta-analysis studies-FILTER"
	metaan effectsize se, fe
	drop if numberofobservations < 1
	di in red "Below are results excluding new meta-analysis studies-FILTER"
	metaan effectsize se, fe

	use `chlo_all', replace
	di in red "Below are results including new meta-analysis studies-Chlorine/Solar"
	metaan effectsize se, fe
	drop if numberofobservations < 1
	di in red "Below are results excluding new meta-analysis studies-Chlorine/Solar"
	metaan effectsize se, fe
	log close

// Check what the RR would be for filter and chlorine/boil if we do our own meta-analysis instead of using Wolf et al 2013
	import excel "`data_dir'/new_review_meta.xlsx", firstrow clear
	gen se = (upper95 - lower95)/3.92
	tempfile all
	save `all', replace

	keep if regexm(intervention, "filter")
	tempfile filter
	save `filter', replace
	metaan effectsize se, fe

	use `all', clear
	keep if intervention == "solar" | intervention == "chlorine"
	tempfile chlorine
	save `chlorine', replace
	metaan effectsize se, fe

