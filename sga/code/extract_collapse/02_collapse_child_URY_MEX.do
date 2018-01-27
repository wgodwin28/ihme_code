// Author: Stephanie Teeple
// Edited: Will Godwin
// Created: 10 Jan 2016
// Edited: 1 May 2016
// Description: This is a parallelized script submitted by 02_collapse_launch.do. to collapse data for URY and MEX


// priming the working environment
clear 
set more off
set maxvar 30000

// discover root
if c(os) == "Unix" {
		global j "/home/j"
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}


// set arguments
local in_dir `1'
local out_dir `2'
local iso3 `3'
local file `4'


// bring in data
use "`in_dir'/`iso3'/`file'", clear
	foreach var of varlist * {
		local `var' = `var'
	}

// run survey_juicer function (svy_subpop)
run "$j/temp/survey_juicer/tabulations/svy_subpop.ado"

// prep for collapse
svyset [pweight=pweight]

// some weird error I keep getting (_000002 or _0000001 or _000000 already defined r(110))
capture noisily drop __00*

// collapse 
// Note - the data is structured differently based on location_type and year. 

gen group_3_tag=1 if gestage >= 32 & gestage < 37
gen group_2_tag=1 if gestage >= 28 & gestage < 32
gen group_1_tag=1 if gestage >= 20 & gestage < 28 // 21 weeks is the frontier according to Theo

// Loop through each preterm age group and calculate SGA proportions by various possible confounders
if iso3 == "MEX" {
	foreach group in group_1 group_2 group_3 {
		preserve
		drop if `group'_tag != 1
		bysort mat_educ mat_age_rec: svy_subpop `group'_indic, tab_type("prop") replace
		save "`out_dir'/`iso3'/`iso3'_`year_start'_collapse_`group'.dta", replace
		restore
	}
}

if iso3 == "URY" {
	foreach group in group_1 group_2 group_3 {
		preserve
		drop if `group'_tag != 1
		bysort mat_educ mat_age_rec: svy_subpop `group'_indic, tab_type("prop") replace
		save "`out_dir'/`iso3'/`iso3'_`year_start'_collapse_`group'.dta", replace
		restore
	}
}
