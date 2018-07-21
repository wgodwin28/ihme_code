**Purpose: Prep handwashing source sheet for sourcing viz tool 
**Date: August 6 2015
**Author: Astha KC
**Filename: 00_gen_source_sheet.do

** Set directories
	if c(os) == "Windows" {
		global j "J:"
		global i "I:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		global i "/home/i"
		set mem 2g
		set odbcmgr unixodbc
	}
    
	** Housekeeping
	clear all 
	set more off 
	
	** Set relevant locals
	local exp_dir 		"$j/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"

	** Prep source sheet
	use "`exp_dir'/hygiene_compiled.dta", clear
	keep iso3 year nid  
	rename (year) (year_start)
	gen year_end = year_start
	gen sex_id = 3
	gen age_start = 0
	gen age_end = 80
	gen risk = "wash_hygiene"

	** Clean up and save
	order risk iso3 year_start year_end age_start age_end sex_id nid, first
	outsheet using "$i/Data Team/GHDx/Source query tool/RISK/Original/source_sheet_wash_hygiene.xls", replace 
	
*****************************
******END OF CODE************
	