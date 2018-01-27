// File Name: extract_files_pma.do

// File Purpose: Extract appropriate survey datasets from pma surveys
// Author: Leslie Mallinger
// Date: 3/2/10
// Edited on: 12/22/2010 (updated file paths to reflect changes to J:/DATA)
// Edited: Will Godwin
// Date: 6/3/2016

// Additional Comments: 


clear all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_pma "J:/LIMITED_USE/PROJECT_FOLDERS/GBD/JHSPH_PERFORMANCE_MONITORING_ACCOUNTABILITY_SURVEY_PMA2020"
local dat_folder_new_pma "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/pma"
local functions					"J:/WORK/10_gbd/00_library/functions"
local get_demo					"`functions'/get_demographics.ado"
local get_location				"`functions'/get_location_metadata.ado"

cap mkdir "`dat_folder_new_pma'"


** extract survey file paths into mata, then put them into Stata
	// initialize mata vector
	local maxobs 2000
	mata: filepath_full = J(`maxobs', 1, "")
	mata: filedir = J(`maxobs', 1, "")
	mata: filename = J(`maxobs', 1, "")
	local obsnum = 1

	// loop through directories and extract files and file paths
	local iso_list: dir "`dat_folder_pma'" dirs "*", respectcase
	foreach i of local iso_list {
		local year_list: dir "`dat_folder_pma'/`i'" dirs "*", respectcase
		foreach y of local year_list {
			// extract HH surveys
			local filenames: dir "`dat_folder_pma'/`i'/`y'" files "*HH*DTA", respectcase
			foreach f of local filenames {
				mata: filepath_full[`obsnum', 1] = "`dat_folder_pma'/`i'/`y'/`f'"
				mata: filedir[`obsnum', 1] = "`dat_folder_pma'/`i'/`y'"
				mata: filename[`obsnum', 1] = "`f'"
				local obsnum = `obsnum' + 1
			}
			
			// extract WN surveys
			// local filenames: dir "`dat_folder_pma'/`i'/`y'" files "*WN*DTA", respectcase
			// foreach f of local filenames {
				// mata: filepath_full[`obsnum', 1] = "`dat_folder_pma'/`i'/`y'/`f'"
				// mata: filedir[`obsnum', 1] = "`dat_folder_pma'/`i'/`y'"
				// mata: filename[`obsnum', 1] = "`f'"
				// local obsnum = `obsnum' + 1
			}
		}

	
	getmata filepath_full filedir filename
	
	
** parse each part of the filename into informative variables
	split filename, p("_") gen(part)
	rename part1 ihme_loc_id
	drop if ihme_loc_id == "NER" | ihme_loc_id == "NGA" // Not nationally representative
	rename part3 year_id
	drop part*

** match ISO codes with country names, determine whether IHME country
	// prepare countrycodes database
	preserve
	run "`get_location'"
	get_location_metadata, location_set_id(9) clear
	keep location_name location_id ihme_loc_id
	tempfile loc_id
	save `loc_id', replace
	restore

	// merge together
	merge m:1 ihme_loc_id using `loc_id', keep(3) nogen
	
** organize
order location_name location_id ihme_loc_id year_id, first
sort location_name year_id
compress

drop if ihme_loc_id =="GHA" & year_id == "2013"
cd "`dat_folder_new_pma'"
save "datfiles_pma", replace
