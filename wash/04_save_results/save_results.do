// Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Set incoming args
local exp	`1'
local risk 	`2'
local dir 	`3'
local dat_dir `dir'/`exp'
di in red "`dir'/`exp'"

	//Sanitation exposures
		if "`exp'" == "improved" {
			local me_id 8879
		}
		if "`exp'" == "unimp" {
			local me_id 9369
		}
	//Water exposures
		if "`exp'" == "imp_t" {
			local me_id 8873
		}
		if "`exp'" == "imp_t2" {
			local me_id 8872
		}
		if "`exp'" == "imp_untr" {
			local me_id 8871
		}
		if "`exp'" == "unimp_t" {
			local me_id 8870
		}
		if "`exp'" == "unimp_t2" {
			local me_id 8869
		}
		if "`exp'" == "unimp_untr" {
			local me_id 9415
		}
		if "`exp'" == "bas_piped_t" {
			local me_id 15794
		}
		if "`exp'" == "bas_piped_t2" {
			local me_id 8875
		}
		if "`exp'" == "bas_piped_untr" {
			local me_id 8874
		}
		if "`exp'" == "piped_untr_hq" {
			local me_id 8877
		}
		if "`exp'" == "piped_t2_hq" {
			local me_id 8878
		}
	//Handwashing exposure
		if "`exp'" == "wash_hwws" {
			local me_id 8944
		}
	//Household air pollution exposure
		if "`exp'" == "air_hap" {
			local me_id 2511
		}
// Debugging
	// local me_id = 8873
	// local description = "first imp_t update for 2016"
	// local dat_dir = "/share/epi/risk/temp/wash_sanitation/review_week/locations/`exp'"

	local metrics = "proportion"
	local mark_best = "T"
	local file_pat = "{location_id}.csv"
	local years = "1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017"
	//local years = "1990 1995 2000 2005 2007 2010 2017"

// Run save_results
	quietly run "$j/temp/central_comp/libraries/current/stata/save_results_epi.ado"
	di "save_results, modelable_entity_id(`me_id')  description(upload of GBD 2016 data, testing GBD 2017 machinery-`exp') input_dir(`dat_dir') input_file_pattern(`file_pat') mark_best(`mark_best')"
	save_results_epi, modelable_entity_id(`me_id') year_id(`years') description(some years for water-East Europe fix) input_dir(`dat_dir') input_file_pattern(`file_pat') measure_id(18) mark_best(`mark_best') 

