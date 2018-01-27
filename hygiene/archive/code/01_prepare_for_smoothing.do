**Purpose: Prep prevalence data for modelling
**Date: 05/15/2014
**Author: Astha KC

**housekeeping
clear all
set more off

**set relevant locals
local prev_folder  			"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"
local smoothing_folder		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/smoothing/spacetime input"

local ldi_pc				"J:/WORK/01_covariates/02_inputs/LDI_pc/model/model_final.dta"
local sanitation_folder		"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output/gpr_results_s_covar.dta"
local piped_folder			"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output/gpr_results_piped_covar.dta"
local urbanicity			"J:/WORK/01_covariates/02_inputs/urbanicity/model/urbanicity.dta"
local matern_educ			"J:/WORK/01_covariates/02_inputs/education/model/MaternalEducation_IHME_1950-2020_Y2013M12Y16.dta"
local country_codes			"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"


**covariates & location variables

**country codes
use "`country_codes'", clear
drop if iso3==""
tempfile codes
save `codes', replace 

**ldi_pc
use "`ldi_pc'", clear
keep iso3 year mean_value
rename mean_value ldi_pc
tempfile ldi 
save `ldi', replace 

/**urbanicity
use "`urbanicity'", clear
keep iso3 year prop_urban
tempfile urbanicity
save `urbanicity', replace 

**maternal education
use "`matern_educ'", clear
keep iso3 year maternal_educ
tempfile matern_educ
save `matern_educ', replace 

**piped_water
use "`piped_folder'", clear
keep iso3 year *mean
rename *mean piped_mean 
tempfile piped
save `piped', replace 

**improved_sanitation
use "`sanitation_folder'", clear
keep iso3 year *mean
rename *mean sanitation_mean

merge 1:1 iso3 year using `piped', keep(1 3) nogen
merge 1:1 iso3 year using `ldi', keep(1 3) nogen
merge 1:1 iso3 year using `urbanicity', keep(1 3) nogen
merge 1:1 iso3 year using `matern_educ', keep(1 3) nogen*/

use `ldi', clear

**merge prevalence data
merge 1:m iso3 year using "`prev_folder'/hygiene_final.dta", keep(1 3) nogen keepusing(reference reference_data *pred *prev *se)
merge m:1 iso3 using `codes', keepusing(location_name gbd_analytical_region_name gbd_analytical_superregion_id) keep(1 3) nogen

order reference, last

**transform necessary variables
gen hwws_pred_logit = logit(hwws_pred)
gen ln_ldi_pc = ln(ldi_pc)

gen national = 0 

**save data
save "`smoothing_folder'/hygiene_smoothing_dataset.dta", replace 

/**explore covariates
xtmixed hwws_prev ldi_pc || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev year || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev maternal_educ || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev prop_urban || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev piped_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev sanitation_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:

xtmixed hwws_prev ldi_pc year || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev ldi_pc maternal_educ || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev ldi_pc prop_urban || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev ldi_pc piped_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:
xtmixed hwws_prev ldi_pc sanitation_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:

xtmixed hwws_prev ldi_pc year maternal_educ prop_urban piped_mean sanitation_mean || gbd_analytical_superregion_id: || gbd_analytical_region_name: || location_name:*/
