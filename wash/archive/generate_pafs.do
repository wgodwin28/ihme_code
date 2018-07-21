// Generate PAFs
// Date: 9/9/16


// Additional Comments: Must run get_draws on cluster

//Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Set relevant macros
	adopath + "$j/temp/central_comp/libraries/current/stata"
	local tmrel 1

// Pull in draws of RR - Start with just hygiene and year 1990 (SGP, USA, BRA, IND, TOGO)
	get_draws, gbd_id_field("rei_id") gbd_id(84) location_ids(69 102 135 163 218) year_ids(1990) source(risk) kwargs(draw_type:rr) clear
	keep if cause_id == 302 & age_group_id == 2 & sex_id == 1 & parameter == "cat1"
	tempfile rr
	save `rr', replace
	save "/home/j/temp/wgodwin/rr_test", replace

// Pull in draws of exposure
	get_draws, gbd_id_field("rei_id") gbd_id(238) location_ids(69 102 135 163 218) year_ids(1992) source(risk) kwargs(draw_type:exposure) clear
	keep if parameter == "cat1" & sex_id == 1 & age_group_id == 2
		forvalues x = 0/999 {
			rename draw_`x' exp_`x'
		}
	tempfile exposure
	save `exposure', replace

//Merge on rr with exposure draws
	use `exposure', clear
	merge m:1 location_id2 using `rr', nogen keep(1 3)
		// Actual paf calculation
		forvalues x = 0/999 {
			gen paf_`x' = (exp_`x' * (rr_`x' - `tmrel'))/((exp_`x' * (rr_`x' - `tmrel')) + 1) 
		}
	fastrowmean paf_*, mean_var_name(paf_mean)
	fastpctile paf_*, pct(2.5 97.5) names(paf_lower paf_upper)

// Check that SEV is equivalent to prevalence since handwashing is dichotomous-that's true because for each outcome, the relative risks in the denominator and numerator are the same so they just cancel out
gen sev_`x' = (exp_`x' * rr_`x') - 1/(rr_`x' - 1)

// Compare with old pafs- shouldn't need to specify measure_id b/c should be same PAF for deaths, DALYs, YLLs, and YLDs
    get_outputs, topic(rei) metric_id(2) measure_id(1) rei_id(238) cause_id(302) gbd_round(2015) year_id(1990) location_id(69 102 135 163 218) clear

save "/home/j/temp/wgodwin/exposure_test", replace


get_draws, gbd_id_field("rei_id") gbd_id(83) location_ids(5 9 21 32 42 56 65 70 73 96 100 104 120 124 134 138 159 167 174 192 199) year_ids(2015) source(risk) kwargs(draw_type:exposure) clear
fastrowmean draw_*, mean_var_name(water_mean)
fastpctile draw_*, pct(2.5 97.5) names(water_lower water_upper)
tempfile master
save `master', replace

foreach reg of local regions{
	use `master', clear
	keep if region_id == `reg'
	
}



// Population weight sewer estimates to get global estimates for gates
import delimited "J:\temp\wgodwin\gpr_output\output_2015\sewer_gates.csv", clear
keep if year_id >= 1990 & year_id != 2016
levelsof year_id, loc(years)
levelsof location_id, loc(locations)
tempfile sewer
save `sewer', replace

// Pull global pops by year
get_population, year_id(`years') sex_id(3) age_group_id(22) clear
foreach year of local years {
	preserve
	keep if year_id == `year'
	local pop_`year' = population
	restore
}

// Pull national pops by year and calculate each country's pop weight
get_population, location_id(`locations') year_id(`years') sex_id(3) age_group_id(22) clear
gen pop_weight = .
foreach year of local years {
	replace pop_weight = population / `pop_`year'' if year_id == `year'
}

tempfile weights
save `weights', replace

// Import sewer dataset and merge on pop weights
use `sewer', clear
merge 1:1 location_id year_id using `weights', nogen

// Calculate pop weighted exposure values and sum across
foreach metric in mean lower upper {
	gen exp_fraction_`metric' = `metric' * pop_weight
	bysort year_id: egen global_`metric' = sum(exp_fraction_`metric')
}

duplicates drop year_id, force
drop mean lower upper region_name super_region_name exp_fraction_lower exp_fraction_upper exp_fraction_mean sum pop_weight process_version_map_id population
rename (global_upper global_lower global_mean) (upper lower mean)
replace ihme_loc_id = "G"
replace location_id = 1
replace location_name = "Global"
tempfile global
save `global', replace

use `sewer', clear
append using `global'
replace sex_id = 3

adopath + "$j/temp/central_comp/libraries/current/stata"
get_draws, gbd_id_field(rei_id) gbd_id(238) location_ids(`locations') year_ids(`years') source(risk) kwargs(draw_type:exposure) gbd_round_id(3) clear
fastpctile draw_*, pct(2.5 97.5) names(lower upper)
fastrowmean draw_*, mean_var_name(mean)

get_draws, gbd_id_field("rei_id") gbd_id(87) source(risk) kwargs(draw_type:exposure) gbd_round_id(3) clear
fastpctile draw_*, pct(2.5 97.5) names(lower upper)
fastrowmean draw_*, mean_var_name(mean)
drop draw_*
save "/home/j/temp/wgodwin/hap_mike", replace
