// Prep diagnostics to compare one-step with old ST-GPR

********************HANDWASHING************************

// priming the working environment
clear 
set more off
set maxvar 30000

// discover root
if c(os) == "Unix" {
		global j "/home/j"
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

//Set relevant locals
local in_dir 	"J:/temp/wgodwin/gpr_output"
local out_san	"J:/temp/wgodwin/diagnostics/sanitation"
local out_hwt	"J:/temp/wgodwin/diagnostics/hwt"
local out_hwws  "J:/temp/wgodwin/diagnostics/hwws"

//import one-step data
// import delimited "`in_dir'/san_piped_output_0617_unraked", clear // change
import delimited "`in_dir'/hwws_lit_output_0713", clear // change
duplicates drop gpr_mean year_id location_id, force
tempfile one_step
save `one_step', replace

//import old data
// import delimited "`in_dir'/output_old/san_piped_output_full_0408", clear // change
import delimited "`in_dir'/output_old/hwws_output_full_0405", clear // change
keep gpr_* location_id year_id ihme_loc_id
// drop *2013
duplicates drop gpr_mean year_id location_id, force
rename (gpr_mean gpr_lower gpr_upper) (gpr_mean2013 gpr_lower2013 gpr_upper2013)
tempfile old
save `old', replace

//Prep to merge
use `one_step', clear
merge 1:1 year_id location_id using `old', nogen keep(1 3)
// scatter gpr_mean gpr_mean_old
gen me_name = "wash_hwws_lit" // change
export delimited "`out_hwws'/hwws_lit_compare_run_121", replace // change

tempfile master
save `master', replace

drop if location_id > 436
tempfile national
save `national', replace
scatter gpr_mean gpr_mean_old

use `master', clear
drop if location_id < 436
tempfile subnational
save `subnational', replace
scatter gpr_mean gpr_mean_old
scatter gpr_mean_unraked gpr_mean_old


***************************UNSAFE WATER*************************

// priming the working environment
clear all
set more off
set maxvar 30000

// discover root
if c(os) == "Unix" {
		global j "/home/j"
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

//Set relevant locals
local in_dir 	"J:/temp/wgodwin/gpr_output"
local out_san	"J:/temp/wgodwin/diagnostics/sanitation"
local out_hwt	"J:/temp/wgodwin/diagnostics/hwt"

//import one-step data
import delimited "`in_dir'/hwt/itreat_piped_check_0621", clear
duplicates drop gpr_mean year_id location_id, force
tempfile one_step
save `one_step', replace

//import old data
import delimited "`in_dir'/hwt/itreat_piped_590_271", clear
keep gpr_* location_id year_id ihme_loc_id
drop *2013
duplicates drop gpr_mean year_id location_id, force
rename (gpr_mean gpr_lower gpr_upper) (gpr_mean2013 gpr_lower2013 gpr_upper2013)
tempfile old
save `old', replace

//Prep to merge
use `one_step', clear
merge 1:1 year_id location_id using `old', nogen keep(1 3)
// scatter gpr_mean gpr_mean_old
gen me_name = "wash_water_itreat_piped"
export delimited "`out_hwt'/itreat_piped_compare_run_85", replace

tempfile master
save `master', replace

drop if location_id > 436
tempfile national
save `national', replace
scatter gpr_mean gpr_mean_old

use `master', clear
drop if location_id < 436
tempfile subnational
save `subnational', replace
scatter gpr_mean gpr_mean_old
scatter gpr_mean_unraked gpr_mean_old