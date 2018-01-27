// Author: Will Godwin
// Purpose: Split observations by sex to prep for save_results for handwashing
// Date: 2/29/16

// Additional Comments: 

// Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Housekeeping
clear all 
set more off
set maxvar 20000

// Set relevant locals
local input_folder		"/share/covariates/ubcov/04_model/wash_hwws/_models/490/107/draws"
local functions			"$j/WORK/10_gbd/00_library/functions"
local get_demo			"`functions'/get_demographics.ado"
local get_location		"`functions'/get_location_metadata.ado"
local output_dir		"/share/epi/risk/temp/wash_hwws2"
local data_dir 			"`input_folder'"
local files: dir "`data_dir'" files "*.csv"

local date 02282016

// Prep the country codes file
	run "`get_location'"
	get_location_metadata, location_set_id(9) clear
	keep if level >= 3
	keep location_id parent_id location_name super_region_id super_region_name region_name ihme_loc_id
	levelsof location_id, local(locations)

foreach loc of local locations {
		forvalues y = 1980/2015 	{
			import delimited "`data_dir'/18_`loc'_`y'_3", clear
			forvalues n = 0/999 {
				replace draw_`n' = 1 - draw_`n'
			}
			expand 20
			// split into sex categories
			foreach obs in 1 2 {
				local counter = 1
				// expand out to all age group id's
				forvalues x = 2/21 {
					replace age_group_id = `x' if _n==`counter'

					local counter = `counter' + 1
					}
				export delim using "`output_dir'/18_`loc'_`y'_`obs'.csv", replace	
				}
			}

		}
