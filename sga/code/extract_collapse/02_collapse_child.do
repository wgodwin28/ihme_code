// Author: Stephanie Teeple
// Edited: Will Godwin
// Created: 10 Jan 2016
// Edited: 1 May 2016
// Description: This is a parallelized script submitted by 02_collapse.do. 



// priming the working environment
clear 
set more off
set maxvar 30000
version 13.0


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
local file `3'


// bring in data
use "`in_dir'/USA/`file'", clear
	foreach var of varlist * {
		local `var' = `var'
	}

** run survey_juicer function (svy_subpop)
run "$j/temp/survey_juicer/tabulations/svy_subpop.ado"

** prep for collapse
svyset [pweight=pweight]

** some weird error I keep getting (_000002 or _0000001 or _000000 already defined r(110))
capture noisily drop __00*

** collapse 
** Note - the data is structured differently based on location_type and year. 
** Years 1990 - 2004 localhave the subnational variable (state id data) filled out, but 2005-onwards does not. 
** The states files from 1995-onwards have weights attached to babies that die to account for bias in 
** states that had lower % of records that were able to be linked to a birth certificate. Territories files
** do not have these weights.

gen group_3_tag=1 if gestage >= 32 & gestage < 38
gen group_2_tag=1 if gestage >= 28 & gestage < 32
gen group_1_tag=1 if gestage >= 21 & gestage < 28 // 21 weeks is the frontier according to Theo

if `year_start' < 2005 {
	foreach group in group_1 group_2 group_3 {
		preserve
		drop if `group'_tag != 1
		bysort mat_educ mat_age_rec mat_race_rec: svy_subpop `group'_indic, tab_type("prop") replace
		save "`out_dir'/USA/USA_`year_start'_collapse_`group'.dta", replace
		restore
	}
}

if `year_start' >= 2005 & "`module'" == "territories" { // Syntax: interestingly, you need quotes around the local here, otherwise stata will think "territories" is a value in a VARIABLE. 
		foreach group in group_1 group_2 group_3 	{
		preserve
		drop if `group'_tag != 1
		bysort mat_educ mat_age_rec mat_race_rec subnational: svy_subpop `group'_indic, tab_type("prop") replace
		save "`out_dir'/USA/USA_`year_start'_collapse_`group'.dta", replace
		restore
	}
}

if `year_start' >= 2005 & "`module'" == "states" {
		foreach group in group_1 group_2 group_3 {
		preserve
		drop if `group'_tag != 1
		bysort mat_educ mat_age_rec mat_race_rec: svy_subpop `group'_indic, tab_type("prop") replace
		save "`out_dir'/USA/USA_`year_start'_collapse_`group'.dta", replace
		restore
}
