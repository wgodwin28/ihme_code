//// File Name: gen_prev_newcat.do
// File Purpose: combine output from gpr models to create exposure inputs to PAF
// Author: Astha KC 
// Date: 3/17/2014
// Edited: Will Godwin
// Date: 2/28/16

// Additional Comments: 
// do /snfs2/HOME/wgodwin/risk_factors2/wash/03_process_split/gen_prev_allcat_san.do

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

** toggle
local run "run1"
local run "run2" //Run ahead of review week with 11 new data sources
local run "run4"
local run "run5"
local c_date= c(current_date)
local date = subinstr("`c_date'", " " , "_", .)

//Set relevant locals
local input_folder		"/share/epi/risk/temp/wash_sanitation/`run'"
local output_folder		"`input_folder'"
local graphloc			"$j/WORK/05_risk/risks/wash_sanitation/data/exp/04_output"
adopath + "/home/j/temp/central_comp/libraries/current/stata"

// Prep dataset
**Improved proportion sanitation**
import delimited "`input_folder'/wash_sanitation_imp_prop", clear
keep location_id year_id age_group_id draw_*
forvalues n = 0/999 {
	rename draw_`n' prop_improved_`n'
}
tempfile sanitation
save `sanitation', replace


**Sewer**
import delimited "`input_folder'/wash_sanitation_piped", clear
keep location_id year_id age_group_id draw_*
forvalues n = 0/999 {
	rename draw_`n' prev_sewer_`n'
}

tempfile sewer
save `sewer', replace

// Merge on with improved sanitation
merge 1:1 location_id year_id using `sanitation', keep(1 3) nogen

//Calculate improved prevalence by multiplying times 1- sewer prevalence
forvalues n = 0/999 {
	gen prev_improved_`n' = prop_improved_`n' * (1 - prev_sewer_`n')
}
// estimate remaining unimproved category
forvalues n = 0/999 {
	gen prev_unimp_`n' = 1 - (prev_improved_`n' + prev_sewer_`n')
}

****replace negative prevalence numbers
local cats "improved sewer unimp" 
foreach cat of local cats {
	forvalues n = 0/999 {
	replace prev_`cat'_`n' = 0.0001 if prev_`cat'_`n' < 0
	replace prev_`cat'_`n' = 0.999 if prev_`cat'_`n' > 1	
		}
}

**rescale draws from all three categories to make sure they add up to 1
forvalues n = 0/999 {
	gen total_`n' = (prev_improved_`n' + prev_sewer_`n' + prev_unimp_`n')
	replace prev_improved_`n' = (prev_improved_`n'/(total_`n'))
	replace prev_sewer_`n' = (prev_sewer_`n'/(total_`n'))
	replace prev_unimp_`n' = (prev_unimp_`n'/(total_`n'))
}
drop total*

tempfile san_cats
save `san_cats', replace

//Save data on share and J for graphing
foreach exp in unimp improved sewer {
	preserve
	keep age_group_id location_id year_id prev_`exp'_*
	save "`output_folder'/`exp'", replace
	restore
}
**save data**
save "`graphloc'/allcat_prev_san_`date'", replace

******************************************************************************************************************************
/*
**Calculate PAF**
gen paf_num = ((isewer_mean*1) + (iimproved_mean*2.71) + (iunimproved_mean*3.23)) - (1*1)
gen paf_denom =  ((isewer_mean*1) + (iimproved_mean*2.71) + (iunimproved_mean*3.23)) 
gen paf = paf_num/paf_denom
tempfile paf
save `paf', replace

**Collapse to gen global/regional estimates**
***Population data***
use "C:/Users/asthak/Documents/Covariates/Water and Sanitation/smoothing/spacetime input/pop_data.dta", clear
tempfile all_pop
sort iso3 
save `all_pop', replace

use `paf', clear
merge m:1 iso3 year using `all_pop'

collapse (mean) paf, by(region_name year)
collapse (mean) paf, by(year)

br if year==1990 | year == 1995 | year == 2000 | year==2005 | year == 2010 | year == 2013

//Graph to see if this works
local iso3s ECU PER SLV KEN MAR BGD
	foreach iso3 of local iso3s {
	twoway (line step2_prev year) || (line prev_piped_t year) || (line prev_piped_t2 year) || (line prev_piped_untr year) if iso3=="BGD", title("BGD") ///
	xlabel(1980(5)2013)
	graph export "`graphloc'/`iso3'_03182014.pdf", replace
}
