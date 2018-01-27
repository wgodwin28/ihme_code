clear all
set more off
set maxvar 20000

// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 


local in_dir 			"$j/temp/wgodwin/sga/data/01_prepped"
local out_dir 			"$j/temp/wgodwin/sga/data/02_collapsed"

// MEX analysis. Different variations of collapsing in order to reduce file size but maintain variation between possible confounders.
use "`in_dir'/MEX/MEX_prepped_master", clear
collapse (count) sga_all (mean) mean_sga=sga_all, by(birthweight gestage mat_educ instit_birth c_section plurality mat_age_rec year_start) fast
save "`out_dir'/MEX/collapse_MEX1", replace

use "`in_dir'/MEX/MEX_prepped_master", clear
collapse (count) sga_all (mean) mean_sga=sga_all, by(birthweight gestage mat_educ c_section plurality mat_age_rec year_start) fast
save "`out_dir'/MEX/collapse_MEX2", replace

use "`in_dir'/MEX/MEX_prepped_master", clear
collapse (count) sga_all (mean) mean_sga=sga_all, by(birthweight gestage mat_educ c_section mat_age_rec year_start) fast
save "`out_dir'/MEX/collapse_MEX3", replace


// USA analysis
use "`in_dir'/USA/states_master_tables2", clear
collapse (count) sga_all (mean) mean_sga=sga_all, by(birthweight gestage mat_educ smoker instit_birth c_section plurality mat_age_rec year_start mat_race_recode) fast
save "`out_dir'/USA/collapse_USA1", replace

use "`in_dir'/USA/states_master_tables2", clear
collapse (count) sga_all (mean) mean_sga=sga_all, by(birthweight gestage mat_race_recode mat_age_rec year_start) fast
save "`out_dir'/USA/collapse_USA2", replace
