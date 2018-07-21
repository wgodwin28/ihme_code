**Filename: compile_san_prop.do
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

**bring in data 

**DHS
use "`prev_folder'/DHS/prev_san_prop_DHS.dta", clear
keep iso3 *year* svy ihwws*
/*drop surveys that are empty - as of now this includes three surveys from ETH and EGY*/
egen sum = rowtotal(ihwws*)
drop if sum == 0
drop sum 

tempfile dhs
save `dhs', replace
 
**MICS
use "`prev_folder'/MICS/prev_san_prop_MICS.dta", clear 
keep iso3 *year* svy ihwws*

append using `dhs'

rename svy source

**save file
save "`prev_folder'/san_prop_compiled.dta", replace

**************
**end of code**
**************