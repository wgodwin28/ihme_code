// File Name: run_gpr.do

// File Purpose: Run GPR for hygiene (handwashing)
// Author: Astha KC 
// Date: 6/5/2014


clear all
set mem 500m
set more off
capture log close
capture restore, not

** create locals for relevant files and folders
local code_folder 			"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/code"
local spacetime_folder 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/smoothing/spacetime results"
local gpr_input_folder 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr input"
local gpr_results_folder 	"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr output"
local iters 1000

**Set directory to successfully call on GPR.py 
cd 	"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/code"

** run gpr for hygiene
local measure hwws
local m hwws

		** open spacetime results
		use "`spacetime_folder'/`m'_B_results.dta", clear

		** calculate GPR parameters
			//replace mad_estimate with global mad_estimate
			sort iso3 year 
			egen mad_global = mad(step2_resid)
			replace mad_estimate = mad_global
			
			// amplitude
			generate spacetime_amplitude_1 = 1.4826 * mad_estimate

			// data variance
				** fill in SEM for observations without it as the 75th percentile of the observed SEMs
**				centile i`measure'_sem, centile(75)
**				replace i`measure'_sem = `r(c_1)' if actual_prev != . & (i`measure'_sem == . | i`measure'_sem == 0)
				
			** calculate data variance
**				forvalues x=1/300 {
**					gen logit_var_`x' = logit(rnormal(actual_prev, i`measure'_sem))
**			}
**				egen logit_var_sd = rowsd(logit_var_*)

			**replace data variance because currently data variance is not being estimated correctly in spacetime used; use delta method to estimate variance in logit space
			** Variance(G(x)) = Var(x)*(G'(x))^2 (approximately)
			**in our case G(x) = logit(x). so, G'(x) = 1/(x(1-x)). 
			**Var(logit(x) = Var(x)/[x(1-x))]^2
			
			replace data_var = . 
			replace data_var = (`measure'_se^2)/((actual_prev*(1-actual_prev))^2)
			gen spacetime_data_variance_1 = data_var + mad_estimate^2
			
			//fill in missing data variances
			bysort gbd_analytical_superregion_id: egen data_var_missing =  median(spacetime_data_variance_1) /*fill up missing data_variance*/
			egen data_var_global = median(data_var_missing)
			replace spacetime_data_variance_1 = data_var_missing if spacetime_data_variance_1 ==. & actual_prev!=.
			replace spacetime_data_variance_1 = data_var_global if data_var_missing==. & actual_prev!=.
			drop data_var_*

			**gen spacetime_data_variance_1 = data_var + logit_var_sd^2
				
			** increase data variance for subnational data
			replace spacetime_data_variance_1 = spacetime_data_variance_1*10 if national == 0 
			**drop logit_var_*

		** cleanup and save full dataset
			// rename
			rename `measure'_pred_logit lt_prev
			rename step2_prev_transformed spacetime_1

			// organize
			sort iso3 year

			// save
			tempfile full_data
			save `full_data', replace

		** cleanup and save dataset for GPR input
			// reduce variables
			keep iso3 year lt_* *_data_variance_1 spacetime_* *_amplitude_1
			
			// get rid of duplicate estimates by making them missing
			bysort iso3 year: gen keep = _n
			replace spacetime_1 = . if keep != 1
			replace spacetime_amplitude = . if keep != 1
			drop keep

			// save
			outsheet using "`gpr_input_folder'/gpr_input_data_`m'.csv", comma replace
	
		** run GPR
		global dvs = lt_prev
		ashell python GPR.py "`gpr_input_folder'/gpr_input_data_`m'.csv" "`gpr_results_folder'/gpr_temp_output_`m'.csv" "lt_prev" 7 1 `iters'
		return list
		
		** open GPR results
		insheet using "`gpr_results_folder'/gpr_temp_output_`m'.csv", comma clear
		rename age_group year
	
		** fix missing values
		qui destring gpr_1_spacetime_mean, replace force
		forvalues i = 1/`iters' {
			qui destring gpr_1_spacetime_d`i', replace force
		}

		** transform to normal space and rename
		forvalues n = 1/1000 {
			replace gpr_1_spacetime_d`n' = invlogit(gpr_1_spacetime_d`n')
			rename gpr_1_spacetime_d`n' gpr_draw`n'
		}
		
		** save draw-level GPR results without original data
		compress
		save "`gpr_results_folder'/gpr_results_`m'.dta", replace
		
		** combine with original data
		merge 1:m iso3 year using `full_data'

		** save summary GPR results with original data
		egen gpr_mean = rowmean(gpr_draw*)
		egen gpr_lower = rowpctile(gpr_draw*), p(2.5)
		egen gpr_upper = rowpctile(gpr_draw*), p(97.5)
		drop gpr_draw*
		compress
		save "`gpr_results_folder'/gpr_results_`m'_with_orig_data.dta", replace
