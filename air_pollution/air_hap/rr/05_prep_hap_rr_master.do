//Purpose: Prep indoor air pollution relative risks based on country-year specific PM2.5 mapping values. 
//Filename: prep_indoor_air_pollution_rr.do
//Date: March 10 2015
// Edited by Yi Zhao on 5/31/2016 to reflect updated filepath
// do /snfs2/HOME/wgodwin/risk_factors2/air_pollution/air_hap/rr/05_prep_hap_rr_master.do

**Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 

//Housekeeping
clear all
set more off
set maxvar 30000

**Set relevant locals** TOGGLE THESE
local split_rr			0
local save_result		1
local version 			2
adopath + "$j/temp/central_comp/libraries/current/stata"


/* version: for GBD 2016
1: initial RRs for GBD 2016, 5/11/2017
2: update to include ambient exposure adjustment(subtraction), 5/20/2017
3: update after cutting out personal pm adjustment in m/w/child crosswalk, 6/14/2017
4: switching back to no ambient adjustment-should be final version, 6/22/2017
5: rerun to fix issue with TMREL in IER curve
*/

/* version: for GBD 2017
1: initial RRs for GBD 2017, testing out machinery 01/09/2018
2: run with updated IER curve, 02/25/2018
*/

local out_dir_draws		"/share/epi/risk/temp/air_hap/rr/`version'/save_results"
**directory with IER draws
local ier_dir			"/share/epi/risk/temp/air_hap/rr/`version'/draws"  
local code_folder		"/snfs2/HOME/wgodwin/risk_factors2/air_pollution/air_hap/rr"
local stata_shell		"$j/WORK/05_risk/risks/air_hap/02_rr/01_code/02_final_prep/stata_shell.sh"
local logs 				-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors


if `split_rr'==1 {
cap mkdir "`out_dir_draws'"
// get location_ids, get demographics
		get_location_metadata, location_set_id(22) clear 
		keep if level >= 3
		keep location_id ihme_loc_id
		quie levelsof location_id, local(locations)
		save "`ier_dir'/location_id.dta", replace  
		local loc_dta 		"`ier_dir'/location_id.dta"

	// Loop through each location and reformat/save in prep for save_results
	foreach loc of local locations {
		// forvalues year = 1990/2017 {
		foreach year in 1990 1995 2000 2005 2010 2017 {
			! qsub -N HAP_rr_`loc'_`year' -P proj_custom_models -pe multi_slot 2 `logs' "`stata_shell'" "`code_folder'/05_prep_hap_rr_child.do" "`ier_dir' `out_dir_draws' `loc' `year' `loc_dta'"
		}	
	}
}


// Save result. CHECK ON HOW MANY SLOTS THIS REQUIRES
// use this call to avoid memory issues---> qlogin -now no -P proj_custom_models -q all.q@@c6320hosts -l mem_free=256 -pe multi_slot 40
if `save_result'==1 {
	//local years = "1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017"
	local years = "1990 2005 2017"
	run "$j/temp/central_comp/libraries/current/stata/save_results_risk.ado"
	save_results_risk, modelable_entity_id(9020) year_id(`years') description(updated IER ahead of review week, including 2005...) input_dir(`out_dir_draws') input_file_pattern(rr_{location_id}_{year_id}_{sex_id}.csv) risk_type(rr) mark_best("T")
}

*******************************
**********end of code***********
*******************************
// Make map
/*
local in_dir "/share/epi/risk/air_pm/exp/21/final_draws"
	import delimited "`in_dir'/AFG", clear
	keep year exp_*
	gen ihme_loc_id = "AFG"
	tempfile master
	save `master', replace

	get_location_metadata, location_set_id(22) clear 
	keep if level >= 3
	drop if ihme_loc_id == "AFG"
	quie levelsof ihme_loc_id, local(locations)
	foreach loc of local locations {
		cap import delimited "`in_dir'/`loc'", clear
		if !_rc {
			keep year exp_*
			gen ihme_loc_id = "`loc'"
			append using `master'
			save `master', replace
		}
	}
*/
