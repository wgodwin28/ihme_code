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


// local in_dir `1'
// local out_dir `2'

local in_dir 			"$j/temp/wgodwin/sga/data/01_prepped"
local out_dir 			"$j/temp/wgodwin/sga/data/02_collapsed"

// MEX or USA collapse for connected scatters
/*
use "`in_dir'/MEX/MEX_national_2008_sga_prep.dta", clear
foreach year in 2009 2010 2011 2012 {
	append using "`in_dir'/MEX/MEX_national_`year'_sga_prep", force
}
*/
use "`in_dir'/USA/USA_states_2010_sga_prep.dta", clear
foreach year in 2002 2003 2004 2005 2006 2007 2008 2009 {
	append using "`in_dir'/USA/USA_states_`year'_sga_prep", force
}
tempfile USA
save `USA', replace

use "`in_dir'/URY/URY_national_2014_sga_prep", clear
foreach year in 1996 1997 1999 2000 2001 2001 2007 2008 2009 2010 2011 2012 2013 {
	append using "`in_dir'/URY/URY_national_`year'_sga_prep", force
}
tempfile URY
save `URY', replace

use "`in_dir'/MEX/MEX_national_2009_sga_prep.dta", clear
foreach year in 2008 2010 2011 2012 {
	append using "`in_dir'/MEX/MEX_national_`year'_sga_prep", force
}
tempfile MEX
save `MEX', replace
append using `USA', force
append using `URY', force

drop if gestage < 21 | gestage > 45

foreach wght in 1500 2500 { 
	gen tag_`wght'_1 = 1 if gestage >= 21 & gestage <= 27 & birthweight < `wght'
	replace tag_`wght'_1 = 0 if tag_`wght'_1 == . & gestage >= 21 & gestage <= 27
	mean tag_`wght'_1
	matrix mean_`wght'_1 = e(b)
	local mean_`wght'_1 = mean_`wght'_1[1,1]

	gen tag_`wght'_2 = 1 if gestage >= 28 & gestage <= 31 & birthweight < `wght'
	replace tag_`wght'_2 = 0 if tag_`wght'_2 == . & gestage >= 28 & gestage <= 31
	mean tag_`wght'_2 
	matrix mean_`wght'_2 = e(b)
	local mean_`wght'_2 = mean_`wght'_2[1,1]

// Currently generates the ratio between gestage category 3 and 4 under 1500 and 2500g for initial crosswalk
	gen tag_`wght'_3 = 1 if gestage >= 32 & gestage <= 36 & birthweight < `wght'
	replace tag_`wght'_3 = 0 if tag_`wght'_3 == . & gestage >= 32 & gestage <= 36
	mean tag_`wght'_3
	matrix mean_`wght'_3 = e(b)
	local mean_`wght'_3 = mean_`wght'_3[1,1]

	gen tag_`wght'_4 = 1 if gestage >= 37 & gestage <= 42 & birthweight < `wght'
	replace tag_`wght'_4 = 0 if tag_`wght'_4 == .
	mean tag_`wght'_4 if gestage >= 37 & gestage <= 42
	matrix mean_`wght'_4 = e(b)
	local mean_`wght'_4 = mean_`wght'_4[1,1]

	local ratio_`wght' = `mean_`wght'_4'/`mean_`wght'_3'
	di `ratio_`wght''
}
di `ratio_1500'

local stan_1 447
local stan_2 894
local stan_3 1692
local stan_4 2735
// the under birthweight prev is constant across location-years for gestage 1 and 2

// Calculate the ratio between prev of babies under standard threshold divided by prev of babies under 1500
foreach wght in 1500 2500 { 
	gen stan_`wght'_1 = 1 if gestage >= 21 & gestage <= 27 & birthweight < `stan_1'
	replace stan_`wght'_1 = 0 if stan_`wght'_1 == . & gestage >= 21 & gestage <= 27
	mean stan_`wght'_1
	matrix mean_stan_`wght'_1 = e(b)
	local mean_stan_`wght'_1 = mean_stan_`wght'_1[1,1]
	gen tag_`wght'_1 = 1 if gestage >= 21 & gestage <= 27 & birthweight < `wght'
	replace tag_`wght'_1 = 0 if tag_`wght'_1 == . & gestage >= 21 & gestage <= 27
	mean tag_`wght'_1
	matrix mean_`wght'_1 = e(b)
	local mean_`wght'_1 = mean_`wght'_1[1,1]
	local ratio_`wght'_1 = `mean_stan_`wght'_1'/`mean_`wght'_1'
	di `ratio_`wght'_1'

// gestage group 2
	gen stan_`wght'_2 = 1 if gestage >= 28 & gestage <= 31 & birthweight < `stan_2'
	replace stan_`wght'_2 = 0 if stan_`wght'_2 == . & gestage >= 28 & gestage <= 31
	mean stan_`wght'_2 
	matrix mean_stan_`wght'_2 = e(b)
	local mean_stan_`wght'_2 = mean_stan_`wght'_2[1,1]
	gen tag_`wght'_2 = 1 if gestage >= 28 & gestage <= 31 & birthweight < `wght'
	replace tag_`wght'_2 = 0 if tag_`wght'_2 == . & gestage >= 28 & gestage <= 31
	mean tag_`wght'_2 
	matrix mean_`wght'_2 = e(b)
	local mean_`wght'_2 = mean_`wght'_2[1,1]
	local ratio_`wght'_2 = `mean_stan_`wght'_2'/`mean_`wght'_2'
	di `ratio_`wght'_2'

	gen stan_`wght'_3 = 1 if gestage >= 32 & gestage <= 36 & birthweight < `stan_3'
	replace stan_`wght'_3 = 0 if stan_`wght'_3 == . & gestage >= 32 & gestage <= 36
	mean stan_`wght'_3
	matrix mean_stan_`wght'_3 = e(b)
	local mean_stan_`wght'_3 = mean_stan_`wght'_3[1,1]
	gen tag_`wght'_3 = 1 if gestage >= 32 & gestage <= 36 & birthweight < `wght'
	replace tag_`wght'_3 = 0 if tag_`wght'_3 == . & gestage >= 32 & gestage <= 36
	mean tag_`wght'_3
	matrix mean_`wght'_3 = e(b)
	local mean_`wght'_3 = mean_`wght'_3[1,1]
	local ratio_`wght'_3 = `mean_stan_`wght'_3'/`mean_`wght'_3'
	di `ratio_`wght'_3'

	gen stan_`wght'_4 = 1 if gestage >= 37 & gestage <= 42 & birthweight < `stan_4'
	replace stan_`wght'_4 = 0 if stan_`wght'_4 == . & gestage >= 37 & gestage <= 42
	mean stan_`wght'_4
	matrix mean_stan_`wght'_4 = e(b)
	local mean_stan_`wght'_4 = mean_stan_`wght'_4[1,1]
	gen tag_`wght'_4 = 1 if gestage >= 37 & gestage <= 42 & birthweight < `wght'
	replace tag_`wght'_4 = 0 if tag_`wght'_4 == . & gestage >= 37 & gestage <= 42
	mean tag_`wght'_4
	matrix mean_`wght'_4 = e(b)
	local mean_`wght'_4 = mean_`wght'_4[1,1]
	local ratio_`wght'_4 = `mean_stan_`wght'_4'/`mean_`wght'_4'
	di `ratio_`wght'_4'

/* use "`in_dir'/USA/USA_states_1990_sga_prep.dta", clear
foreach year in 1991 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 {
	append using "`in_dir'/USA/USA_states_`year'_sga_prep", force
}

replace mat_age_rec = 1 if mat_age_rec == 1 | mat_age_rec == 2 | mat_age_rec == 3
replace mat_age_rec = 2 if mat_age_rec == 4 | mat_age_rec == 5 | mat_age_rec == 6
replace mat_age_rec = 3 if mat_age_rec == 7 | mat_age_rec == 8 | mat_age_rec == 9 | mat_age_rec == 10
rename group_3_indic wk_32_36
rename group_2_indic wk_28_31
rename group_1_indic wk_21_27
rename group_4_indic wk_37_42
gen wk_32_36_tag=1 if gestage >= 32 & gestage < 37
gen wk_28_31_tag=1 if gestage >= 28 & gestage < 32
gen wk_21_27_tag=1 if gestage >= 21 & gestage < 28
gen wk_37_42_tag=1 if gestage >= 37 & gestage <= 42
save "`in_dir'/USA/states_master", replace
save "`in_dir'/MEX/MEX_prepped_master", replace


// use "`in_dir'/USA/states_master", clear
gen wk_37_42_tag=1 if gestage >= 37 & gestage < 42
foreach group in wk_21_27 wk_28_31 wk_32_36 wk_37_42	{
		preserve
		drop if `group'_tag != 1
		collapse (count) `group' (mean) mean_sga=`group', by(gestage year_start) fast
		save "`out_dir'/USA/`group'2", replace
		// scatter mean_sga year_start [fw=`group'], by(gestage)
		// scatter mean_sga year_start, by(gestage)
		// graph save "`in_dir'/URY/`group'", replace
		restore
	}
	drop if wk_37_42_tag != 1
		tempfile temp
		save `temp', replace
		collapse (count) sga_all (mean) mean_sga=sga_all, by(gestage year_start) fast
		save "/home/j/temp/wgodwin/sga/data/02_collapsed/USA/wk_37_42", replace
		use `temp', clear
		collapse (count) sga_all (mean) mean_sga=sga_all, by(year_start) fast
		save "/home/j/temp/wgodwin/sga/data/02_collapsed/USA/wk_37_422", replace
/*
// MEX
log using "$j/temp/wgodwin/sga/data/00_logfiles/MEX_new_tables"
use "`in_dir'/MEX/MEX_national_2008_sga_prep.dta", clear
foreach year in 2009 2010 2011 2012 {
	append using "`in_dir'/MEX/MEX_national_`year'_sga_prep", force
}
save "`in_dir'/MEX/MEX_prepped_master", replace

replace mat_age_rec = 1 if mat_age_rec == 1 | mat_age_rec == 2 | mat_age_rec == 3
replace mat_age_rec = 2 if mat_age_rec == 4 | mat_age_rec == 5 | mat_age_rec == 6
replace mat_age_rec = 3 if mat_age_rec == 7 | mat_age_rec == 8 | mat_age_rec == 9 | mat_age_rec == 10
rename group_3_indic wk_32_36
rename group_2_indic wk_28_31
rename group_1_indic wk_21_27
gen wk_32_36_tag=1 if gestage >= 32 & gestage < 37
gen wk_28_31_tag=1 if gestage >= 28 & gestage < 32
gen wk_21_27_tag=1 if gestage >= 21 & gestage < 28
foreach group in wk_21_27 wk_28_31 wk_32_36 	{
		preserve
		drop if `group'_tag != 1
		table mat_educ, c(mean `group' n `group') by(year_start)
		table mat_age_rec, c(mean `group' n `group') by(year_start)
		restore
	}
	log close

/* USA
log using "$j/temp/wgodwin/sga/data/00_logfiles/USA_new_tables"
foreach group in wk_21_27 wk_28_31 wk_32_36 	{
		use "`in_dir'/USA/states_master_tables3", clear
		gen wk_32_36_tag=1 if gestage >= 32 & gestage < 37
		gen wk_28_31_tag=1 if gestage >= 28 & gestage < 32
		gen wk_21_27_tag=1 if gestage >= 21 & gestage < 28
		rename group_3_indic wk_32_36
		rename group_2_indic wk_28_31
		rename group_1_indic wk_21_27
		drop if `group'_tag != 1
		// table mat_age_rec, c(mean `group' n `group' ) by(year_start)
		table mat_race_recode, c(mean `group' n `group') by(year_start)
		// table mat_race_num, c(mean `group' n `group') by(year_start)
		table mat_educ, c(mean `group' n `group') by(year_start)
		table mat_age_rec, c(mean `group' n `group') by(year_start)
		table smoker, c(mean `group' n `group') by(year_start)
		table alcohol, c(mean `group' n `group') by(year_start)
	}
log close
*/
/* use "`in_dir'/USA/USA_prepped_master", clear
collapse (count) sga_all (mean) mean_sga=sga_all (mean) group_1_indic (mean) group_2_indic (mean) group_3_indic, by(birthweight gestage mat_educ instit_birth c_section plurality mat_age_rec year_start) fast
save "`out_dir'/USA/collapse_USA1", replace

use "`in_dir'/USA/USA_prepped_master", clear
collapse (count) sga_all (mean) mean_sga=sga_all, by(birthweight gestage mat_educ c_section plurality mat_age_rec year_start) fast
save "`out_dir'/USA/collapse_USA2", replace

use "`in_dir'/USA/USA_prepped_master", clear
collapse (count) sga_all (mean) mean_sga=sga_all, by(birthweight gestage mat_educ c_section mat_age_rec year_start) fast
save "`out_dir'/USA/collapse_USA3", replace

use "`in_dir'/USA/states_master_tables2", clear
collapse (count) sga_all (mean) mean_sga=sga_all, by(birthweight gestage mat_educ smoker mat_age_rec year_start mat_race_recode) fast
save "`out_dir'/USA/collapse_USA1", replace

use "`in_dir'/USA/states_master_tables2", clear
collapse (count) sga_all (mean) mean_sga=sga_all, by(birthweight gestage mat_race_recode mat_age_rec year_start) fast
save "`out_dir'/USA/collapse_USA2", replace
*/