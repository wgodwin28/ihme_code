// File Purpose: Calculate means of 2013 draws and merge onto 2015 datasets for vetting models
// Author: Will Godwin
// Date: 1/21/2016


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
set maxvar 30000

// Set relevant locals
local fastrowmean			"J:/WORK/10_gbd/00_library/functions/fastrowmean.ado"
local input_folder			"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output"
local fastpctile			"J:/WORK/10_gbd/00_library/functions/fastpctile.ado"
local input_folder_treat	"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/02_Analyses/data/08072014/gpr_output"
local input_folder_hwws		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr output"

// Loop through each water and sanitation 2013 gpr output
local files s sewer piped w
foreach file of local files {
	use "`input_folder'/gpr_results_`file'_covar", clear
		// Calculate mean of 1000 draws
		run "`fastrowmean'"
		fastrowmean gpr_*, mean_var_name(gpr_mean2013)
		// Calculate lower and upper bounds of draws
		run "`fastpctile'"
		fastpctile gpr_*, pct(2.5 97.5) names(gpr_lower2013 gpr_upper2013)
	// Clean up dataset
	rename iso3 ihme_loc_id
	rename year year_id
	keep ihme_loc_id year_id gpr_*2013
	save "`input_folder'/`file'_mean", replace
	}

// Loop through each household water treatment 2013 gpr output
local files imp_treat imp_treat2 piped_treat piped_treat2 unimp_treat unimp_treat2
foreach file of local files {
	use "`input_folder_treat'/gpr_results_`file'", clear
		// Calculate mean of 1000 draws
		run "`fastrowmean'"
		fastrowmean gpr_*, mean_var_name(gpr_mean2013)
		// Calculate lower and upper bounds of draws
		run "`fastpctile'"
		fastpctile gpr_*, pct(2.5 97.5) names(gpr_lower2013 gpr_upper2013)
	// Clean up dataset
	rename iso3 ihme_loc_id
	rename year year_id
	keep ihme_loc_id year_id gpr_*2013
	save "`input_folder_treat'/`file'_mean", replace
	}

	use "`input_folder_hwws'/gpr_results_hwws", clear
		fastrowmean gpr_*, mean_var_name(gpr_mean2013)
		fastpctile gpr_*, pct(2.5 97.5) names(gpr_lower2013 gpr_upper2013)
	rename iso3 ihme_loc_id
	rename year year_id
	keep ihme_loc_id year_id gpr_*2013
	save "`input_folder_hwws'/hwws_mean", replace

	clear
                #delim ;
                odbc load, exec("SELECT ihme_loc_id, location_name, location_id, location_type, super_region_name, region_name, super_region_id, region_id
                FROM shared.location_hierarchy_history 
                WHERE (location_type = 'admin0' OR location_type = 'admin1' OR location_type = 'admin2' OR location_type = 'nonsovereign')
                AND location_set_version_id = (
                SELECT location_set_version_id FROM shared.location_set_version WHERE 
                location_set_id = 9
                and end_date IS NULL)") dsn(epi) clear;
                #delim cr
/