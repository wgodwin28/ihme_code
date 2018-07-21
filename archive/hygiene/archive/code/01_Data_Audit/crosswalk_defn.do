/*
Filename: crosswalk_defn.do
Purpose: Conduct crosswalking between data for two indicators of structured observations of handwashing events and observed facilities
Date: June 18 2014
Notes:
*/

//Housekeeping
clear all
set more off

//Set relevant locals
local data_audit 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"
local country_codes 	"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
local ldi_pc			"J:/WORK/01_covariates/02_inputs/LDI_pc/model/model_final.dta"

**Compile dataset to conduct crosswalk
use "`data_audit'/hygiene_compiled.dta", clear

**ldi_pc
preserve
use "`ldi_pc'", clear
keep ihme_loc_id year mean_value
rename mean_value ldi_pc
tempfile ldi 
save `ldi', replace
restore

rename iso3 ihme_loc_id
merge m:1 ihme_loc_id year using `ldi', keepusing(ldi_pc) keep(1 3) nogen

**transform necessary variables
gen logit_hwws_prev = logit(hwws_prev)
gen logit_hwws_se = logit(hwws_se)
gen ln_ldi_pc = ln(ldi_pc)

tempfile data
save `data', replace

**regress
xtmixed logit_hwws_prev ln_ldi_pc reference_data || gbd_analytical_superregion_name: || gbd_analytical_region_name: || location_name: || reference: 
xtmixed logit_hwws_prev reference_data || gbd_analytical_superregion_name: reference_data|| gbd_analytical_region_name: reference_data || location_name: reference_data year 
predict re*, reffect
table gbd_analytical_superregion_name, c(mean re1 mean re2 mean re3)
// xtmixed logit_hwws_prev reference_data || gbd_analytical_superregion_name: || gbd_analytical_region_name: || location_name: || reference: 
gen reference_data_old = reference_data
replace reference_data = 1

*******
duplicates tag ihme_loc_id, gen(tag)
drop if tag==0
sort ihme_loc_id
twoway(scatter hwws_prev year if reference_data==1, mcolor(red)) (scatter hwws_prev year if reference_data==0, mcolor(blue)), by(ihme_loc_id) legend(label(1 "Lit (reference)") label(2 "DHS/MICS")) yscale(range(0 1)) ytitle("Handwashing Prevalence")
levelsof ihme_loc_id, l(locations)
foreach loc of local locations {
	preserve
	keep if ihme_loc_id=="`loc'"
	twoway(scatter hwws_prev year if reference_data==1, mcolor(red)) (scatter hwws_prev year if reference_data==0, mcolor(blue)), legend(label(1 "Lit (reference)") label(2 "DHS/MICS")) yscale(range(0 1)) ytitle("Handwashing Prevalence")
	restore
}
bysort ihme_loc_id: egen mean_ref= mean(reference_data)
drop if mean_ref == 1 | mean_ref==0
drop if ihme_loc_id=="BFA" | hwws_prev==. | ihme_loc_id=="KGZ"
drop if ihme_loc_id=="UGA" & year== 2000
drop if ihme_loc_id=="SEN" & year!=2005
drop if ihme_loc_id=="BGD" & year<2010
drop if nid == 146356

// Could use "predict logit_hwws_pred, fit", which incorporates the values of the random effects. This seems to be a better method because right now random effects
// are used in the regression, which affects the beta of the fixed effect (reference) but random effects aren't explicitly added in. Why is that? At the moment, the predicted data
// does seem to stay pretty close to each other by region and super region so random effects do seem to have some impact.
*****

predict logit_hwws_pred
predict logit_hwws_pred_se, stdp

replace logit_hwws_pred = logit_hwws_prev if reference_data_old == 1
replace logit_hwws_pred_se = logit_hwws_se if reference_data_old == 1
replace logit_hwws_pred_se = logit_hwws_pred_se + logit_hwws_se if reference_data_old == 0 

gen hwws_pred = invlogit(logit_hwws_pred)
gen hwws_pred_se = invlogit(logit_hwws_pred_se)

**clean up dataset
keep iso3 year hwws_prev hwws_se reference reference_data_old hwws_pred hwws_pred_se
order iso3 year hwws_pred hwws_pred_se reference reference_data_old hwws_prev hwws_se
rename reference_data_old reference_data

**save dataset
save "`data_audit'/hygiene_final.dta", replace


************************************************************************

/**do crosswalk - with error propagation**
xtmixed logit_hwws_prev ln_ldi_pc reference_data || gbd_analytical_superregion_name: || gbd_analytical_region_name: || location_name: || reference: 

**save beta coefficient
matrix m = e(b)
matrix m = m[1,2]

**save variance covariance matrix
matrix C = e(V)
matrix C = C[2,2]

local beta
capture set obs 1000
drawnorm beta, n(1000) means(m) cov(C) clear
gen n = _n
gen reference_data = 0
order reference_data n beta, first
reshape wide beta, i(reference_data) j(n)

tempfile beta
save `beta'

use `data', clear
	forvalues draw = 1/1000 {
		gen hwws_`draw' = rnormal(hwws_prev, hwws_se)
		gen logit_hwws_`draw' = logit(hwws_`draw')
	}

merge m:1 reference_data using `beta', keepusing(beta*) keep(1 3) nogen

	forvalues draw = 1/1000 {
		gen adj_`draw' = (logit_hwws_`draw' + (logit_hwws_`draw'* beta`draw')) if reference_data==0
	}
	
	egen adj_mean = rowmean(adj_*)
	egen adj_upper = rowpctile(adj_*), p(97.5)
	egen adj_lower = rowpctile(adj_*), p(2.5)
	gen adj_se = adj_upper - adj_lower/(2*1.96)
	
	replace hwws_prev = invlogit(adj_mean) if adj_mean!=.
	replace hwws_se = invlogit(adj_se) if adj_se!=. */
	
	

