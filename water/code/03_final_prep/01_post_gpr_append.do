// Author: Will Godwin
// Purpose: Append together gpr outputs so that all water categories can be created
// Date: 2/28/16

// Additional Comments: Currently must be run on cluster b/c appending files in clustertemp

clear all 
set more off


// Set relevant locals

//input arguments
local input_dir `1'
local output_dir `2'
local exposure `3'

	di "`input_dir' `output_dir' `exposure'"
	local date "04102016"
	adopath + "/home/j/WORK/10_gbd/00_library/functions"

** Debugging
// local location = 101
// local i = "1989 1990"
// local data_dir "C:/Users/wgodwin/Desktop"

// Prep the country codes file
	get_location_metadata, location_set_id(9) clear
	keep if level >= 3
	keep location_id parent_id location_name super_region_id super_region_name region_name ihme_loc_id
	drop if location_id == 6
	levelsof location_id, local(location_ids)


// Loop through each location within draws directory and append together 
	local counter = 1
		foreach location of local location_ids {
			forvalues i = 1980/2015 {
			import delimited "`input_dir'/18_`location'_`i'_3", clear
			gen location_id = `location'
			gen year_id = `i'
			tempfile location_`counter'
			save `location_`counter'', replace
		local counter = `counter' + 1
	}
}
			use `location_1', clear
			local max = `counter' - 1
			forvalues x = 2/`max' {
				append using `location_`x''
		}		
	save "`output_dir'/`exposure'_`date'", replace
