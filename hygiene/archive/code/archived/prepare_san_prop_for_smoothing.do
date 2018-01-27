**Filename: prepare_san_prop_for_smoothing.do
**Author: Astha KC
**Purpose: Compile dataset with survey extractions containing hygiene+san proportions
**Date: Sept 29 2014

**housekeeping
clear all
set more off
set maxvar 32000

**Set directories
if c(os) == "Windows" {
	global j "J:"
	set mem 3000m
}
if c(os) == "Unix" {
	global j "/home/j"
	set mem 8g
} 

**set relevant locals
local prev_folder	"$j/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"
local spacetime 	"$j/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/smoothing/spacetime input"
local ldi_pc		"$j/WORK/01_covariates/02_inputs/LDI_pc/model/model_final.dta"
local country_codes 		"$j/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"

**prep country codes file
use "`country_codes'", clear
drop if iso3==""
keep iso3 location_name indic_cod gbd_analytical_region_name gbd_analytical_superregion_id
tempfile codes
save `codes', replace 

**bring in data 
use "`prev_folder'/san_prop_compiled.dta", replace
rename startyear year
merge m:1 iso3 year using "`ldi_pc'", keepusing(mean_value) nogen
merge m:1 iso3 using `codes', nogen

keep if indic_cod == 1
keep if (year >= 1980 & year <= 2013 )
drop indic_cod

rename mean_value ldi_pc
gen ln_ldi_pc = log(ldi_pc)

gen logit_hw_unimp = logit(ihwws_unimproved_mean)
gen logit_hw_sewer = logit(ihwws_sewer_mean)
gen logit_hw_imp = logit(ihwws_improved_mean)
gen national = 1 

**save file**
save "`spacetime'/san_prop_smoothing.dta", replace 

**************
**end of code**
**************