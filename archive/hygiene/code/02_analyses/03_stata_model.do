// Date: 8/9/206
// Purpose: To model both aspects of hand washing outside of ST-GPR framework

**********************Availability of water and soap model prep*********************
//Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

//Housekeeping
clear all 
set more off
set maxvar 30000
adopath + "$j/WORK/10_gbd/00_library/functions"

	use "$j/temp/wgodwin/gpr_input/run_2015/hwws_availability_input", clear

// Impute one value of .95 for one country in each high income region
		replace hwws_mean = .95 if location_id == 74 & year_id == 2010
		replace hwws_se = .01 if location_id == 74 & year_id == 2010
		replace hwws_mean = .95 if location_id == 97 & year_id == 2010
		replace hwws_se = .01 if location_id == 97 & year_id == 2010
		replace hwws_mean = .95 if location_id == 71 & year_id == 2010
		replace hwws_se = .01 if location_id == 71 & year_id == 2010
		replace hwws_mean = .95 if location_id == 66 & year_id == 2010
		replace hwws_se = .01 if location_id == 66 & year_id == 2010
		replace hwws_mean = .95 if location_id == 101 & year_id == 2010
		replace hwws_se = .01 if location_id == 101 & year_id == 2010
// Prep for logistic model by estimating sample size and positive observations
	gen ss = hwws_mean*(1- hwws_mean)/ hwws_se^2
	gen obs = round(hwws_mean*ss, 1)
	replace ss = round(ss,1)
	replace obs = round(obs,1)

// Model and predict using multi-level logistic regression with random effect on region
	meqrlogit obs ln_ldi, binomial(ss) || region_id: 
	predict pred, xb

// Predict random effects on region level and generate 1000 draws
	predict re,reffect
	predict rese,rese
		forvalues x = 0/999 {
			gen re_`x' = rnormal(re, rese)
		}
	tempfile master
	save `master', replace
	
// Store matrices of variance/covariance matrix
	mat b = e(b)
	mat b2 = b[1, 1..2]
	mat v = e(V)
	mat v2 = v[1..2, 1..2]

// Generate a thousand draws of beta and intercept of the model
	clear 
	drawnorm v1 v2, n(1000) means(b2) cov(v2) cstorage(full)
	xpose, clear

// Rename to standard numbers and store as locals
	local i 0
	forvalues x = 1/1000 {
		rename v`x' v`i'
		local i = `i' + 1
	}
	forvalues x = 0/999 {
		local beta_`x' = v`x'[1]
		local int_`x' = v`x'[2]
	}

// Calculate draws of the model
	use `master', clear
	forvalues x = 0/999 {
		gen avail_`x' = (ln_ldi * `beta_`x'') + `int_`x'' + re_`x'
	}
	forvalues x = 0/999 {
		replace avail_`x' = (ln_ldi * `beta_`x'') + `int_`x'' if re_`x' == .
	}

// Transform to normal space
	forvalues n = 0/999 {
		replace avail_`n' = invlogit(avail_`n')
	}

// Set all High-income countries to 95% post-hoc
  	forvalues draw = 0/999 {
	replace avail_`draw' = .95 if super_region_name == "High-income" & region_name!= "Southern Latin America"
	}

// Prep for scatter and save
	fastpctile avail_*, pct(2.5 97.5) names(lower upper)
	fastrowmean avail_*, mean_var_name(mean)
	save "/share/epi/risk/temp/wash_hwws5/avail_v1", replace
// export delimited "$j/temp/wgodwin/diagnostics/hwws/hwws_avail_new.csv", replace


**********************Act of handwashing model prep*********************
// Conduct similar modeling scheme for act of hand washing
	use "$j/temp/wgodwin/gpr_input/hwws_lit.dta", clear
	rename hwws_prev hwws_mean
	replace hwws_se = .112148 in 2874
	// Delta method to tranform se
		gen variance = hwws_se^2
		gen variance_logit = variance * (1/(hwws_mean*(1-hwws_mean)))^2
		gen logit_hwws = logit(hwws_mean)

// Model
	regress logit_hwws education_yrs_pc [aw = 1/(variance_logit)]
	predict pred, xb
	tempfile act
	save `act', replace

// Store relevant aspects of variance/covariance matrix
	mat b = e(b)
	mat b2 = b[1, 1..2]
	mat v = e(V)
	mat v2 = v[1..2, 1..2]

// Generate a thousand draws of beta and intercept of the model
	clear 
	set obs 1000
	drawnorm v1 v2, n(1000) means(b2) cov(v2) cstorage(full)
	xpose, clear

// Rename to standard numbers and store as locals
	local i 0
	forvalues x = 1/1000 {
		rename v`x' v`i'
		local i = `i' + 1
	}
	forvalues x = 0/999 {
		local beta_`x' = v`x'[1]
		local int_`x' = v`x'[2]
	}

// Calculate draws of the model
	use `act', clear
	forvalues x = 0/999 {
		gen act_`x' = (education_yrs_pc * `beta_`x'') + `int_`x''
	}

// Transform to normal space
	forvalues n = 0/999 {
		replace act_`n' = invlogit(act_`n')
	}
	duplicates drop location_id year_id, force

// Prep for scatter and replace impractical values
	fastpctile act_*, pct(2.5 97.5) names(act_lower act_upper)
	fastrowmean act_*, mean_var_name(act_mean)
	replace mean = 1 if mean > 1
	
// Prep for merge with availability draws
	preserve
	use "/share/epi/risk/temp/wash_hwws5/avail_v1", clear
	duplicates drop location_id year_id, force
	tempfile avail
	save `avail', replace
	restore

// Merge with draws of availability and multiply together
	merge 1:1 location_id year_id using `avail'
	forvalues n = 0/999 {
		gen hwws_final_`n' = act_`n' * avail_`n'
		}

// Clean up and calculate 1- handwashing to get prevalence of "no handwashing"
	keep age_group_id location_id year_id sex_id hwws_final_*
		forvalues n = 0/999 {
			rename hwws_final_`n' hwws_final2_`n'
			gen hwws_final_`n' = 1 - hwws_final2_`n'
			replace hwws_final_`n' = 0 if hwws_final_`n' < 0
			replace hwws_final_`n' = 1 if hwws_final_`n' > 1

		}

// Prep for scatter/map and save for save_results
	fastpctile hwws_final_*, pct(2.5 97.5) names(gpr_lower gpr_upper)
	fastrowmean hwws_final_*, mean_var_name(gpr_mean)
	drop hwws_final2_*
	save "/share/epi/risk/temp/wash_hwws5/hwws_final_v5", replace


************ Mehrdad example of transformation to logistic regression by generating counts based on proportion and sample size
use "J:/temp/wgodwin/gpr_input/hwws_lit.dta", clear
rename hwws_prev hwws_mean
replace hwws_se = .112148 in 2874
	gen ss = hwws_mean*(1- hwws_mean)/ hwws_se^2 // just a rearranged equation of (pq/n)
	gen obs = round(hwws_mean*ss,1) // gets observations of positive occurences of handwashing
replace ss = round(ss,1)
rename obs obs1
gen obs0 = ss - obs
gen id = _n
preserve
reshape long obs,i(id) j(case)
replace obs = round(obs,1)
logit case education_yrs_pc [fw = obs]
mat b = e(b)
mat b2 = b[1,1..2]
mat v = e(V)
mat v2 = v[1..2, 1..2]
// mat v2 = v[7..13,7..13]
clear 
set obs 1000
drawnorm beta integer, means(b2) cov(v2)
replace draw = invlogit(draw)

db drawnorm
db meqrlogit

restore
predict se, stdp
predict pred, xb
replace pred = invlogit(pred)

    forvalues draw = 0/999 {
        gen draw_`draw' = exp(rnormal(ln(pred), se))
    }


fastpctile hwws_final_*, pct(2.5 97.5) names(gpr_lower gpr_upper)
fastrowmean hwws_final_*, mean_var_name(gpr_mean)
drop hwws_final_*
gen me_name = "wash_hwws"
gen data = .
gen prior = gpr_mean
gen st = gpr_mean
export delimited "J:/temp/wgodwin/diagnostics/hwws/hwws_final_new4.csv", replace
