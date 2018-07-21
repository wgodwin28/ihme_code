**Purpose: Prep prevalence data for handwashing. 
**Date: 05/15/2014
**Author: Astha KC
**Notes: Data was extracted from the literature and was sent as is by Annette Pruss et al in 05/2014

**Housekeeping**
clear all
set more off

**Set relevant locals**
local country_codes 	"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
local data_folder 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"
local ldi_pc			"J:/WORK/01_covariates/02_inputs/LDI_pc/model/model_final.dta"

**Compile data

	**import data
	use "`data_folder'/DHS/prev_san_prop_DHS.dta", clear
	append using "`data_folder'/MICS/prev_san_prop_MICS.dta"
	
	drop countryname ihme_country region
	rename startyear year
	
	**Add relevant variables**
	preserve
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
	restore
	
	
	merge m:1 iso3 using `codes', keepusing(location_name gbd_analytical_region_name gbd_analytical_superregion_name indic_cod) keep(1 3) nogen
	merge m:1 iso3 year using `ldi', keepusing(ldi_pc) keep(1 3) nogen
	drop if indic_cod != 1
	gen ln_ldi_pc = ln(ldi_pc)
	
	local props "ihwws_unimproved_mean ihwws_sewer_mean ihwws_improved_mean"
	foreach prop of local props{
		gen logit_`prop' = logit(`prop')
		xtmixed logit_`prop' ln_ldi_pc || gbd_analytical_superregion_name: || gbd_analytical_region_name: || location_name:
		}
	
**Save data**
	save "`data_folder'/hygiene_prop.dta", replace
	

