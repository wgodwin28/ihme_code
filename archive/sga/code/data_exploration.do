// Author: Will Godwin
// Date: 4/27/2016
// Purpose: Explore proportions of SGA across preterm age groups and explore distributions

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

// Set relevant locals
local data_dir		"$j/temp/wgodwin/sga/data"

// Split data into readable chunks
use "`data_dir'/all_data", clear
levelsof iso3, l(locations)
foreach location of local locations {
	keep if iso3 == "`location'"
		if "`location'" == "USA" {
			preserve
				drop if regexm(filepath, "TERRITORIES")
				save "`data_dir'/`location'/raw_data_states"
			restore
				keep if regexm(filepath, "TERRITORIES")
				save "`data_dir'/`location'/raw_data_territories"
		}
	save "`data_dir'/`location'/raw_data", replace
}

// Interpolate the values 
	import delimited "J:/temp/wgodwin/sga/data/sga_threshold_boys.csv", clear
	
	// log transform so values stay above 0. Then regress and predict linear values
		gen ln_weight = log(weight)
		regress ln_weight ga_weeks
		predict ln_pred_weight
		gen pred_weight1 = exp(ln_pred_weight)
		gen pred_weight = round(pred_weight1)
		replace pred_weight = 1390 if ga_weeks == 32 // replace implausible prediction with a plausible one
		replace weight = pred_weight if weight == .




********* Script to generate histograms of birthweight for USA, MEX, and URY data
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

local graphloc	"J:/temp/wgodwin/sga/data/03_weight_distr/USA"
local in_dir 	"J:/temp/wgodwin/sga/data/01_prepped/USA"

// initiate pdf maker
	do "J:/Usable/Tools/ADO/pdfmaker_Acrobat11.do"
	pdfstart using "`graphloc'/USA_weight_distr_nat.pdf"

// Generate locals and loop through year-specfic files to create birth weight histograms
	local filenames: dir "`in_dir'" files "USA*", respectcase
	local count = 1
	foreach file of local filenames {
		use "`in_dir'/`file'", clear
		di in red "`file'"
		sort year_start 
			tempfile temp_`count'
			save `temp_`count'', replace
		foreach var of varlist * {
			local `var' = `var'
		}
		gen tag=1 if gestage >= 21 & gestage < 28 // 21 weeks is the frontier according to Theo
		drop if tag!=1
		cap hist birthweight, title("`iso3'-<28 weeks-`year_start'")
			if _rc != 0 {
				di in red "`file' has no data for this age group"
			}
			else pdfappend
	use `temp_`count'', clear
		gen tag=1 if gestage >= 28 & gestage < 32
		drop if tag!=1
		cap hist birthweight, title("`iso3'-28-<32 weeks-`year_start'")
			if _rc != 0 {
				di in red "`file' has no data for this age group"
			}
			else pdfappend
	use `temp_`count'', clear
		gen tag=1 if gestage >= 32 & gestage < 38
		drop if tag!=1
		cap hist birthweight, title("`iso3'-32-<38 weeks-`year_start'")
			if _rc != 0 {
				di in red "`file' has no data for this age group"
			}
			else pdfappend
	use `temp_`count'', clear
		gen tag=1 if gestage >= 38
		drop if tag!=1
		cap hist birthweight, title("`iso3'-38+ weeks-`year_start'")
			if _rc != 0 {
				di in red "`file' has no data for this age group"
			}
			else pdfappend
	local count = `count' + 1
}

// Append tempfiles in order to create master data file
local count = `count' - 1
forvalues x = 2/`count' {
	use `temp_1', clear
	append using `temp_`x'', force
	di in red _N
	save `temp_1', replace
}
	tempfile master_data
	save `master_data', replace

// Generate preterm age specific histograms for all years of data in a country
		gen tag=1 if gestage >= 21 & gestage < 28 // 21 weeks is the frontier according to Theo
		drop if tag!=1
		hist birthweight, title("`iso3'-Under 28 weeks-all years")
		pdfappend
	use `master_data', clear
		gen tag=1 if gestage >= 28 & gestage < 32
		drop if tag!=1
		hist birthweight, title("`iso3'-28-<32 weeks-all years")
		pdfappend
	use `master_data', clear
		gen tag=1 if gestage >= 32 & gestage < 38
		drop if tag!=1
		hist birthweight, title("`iso3'-32-<38 weeks-all years")
		pdfappend
	use `master_data', clear
		gen tag=1 if gestage >= 38
		drop if tag!=1
		hist birthweight, title("`iso3'-38+ weeks-all years")
		pdfappend
pdffinish

// Mehrdad's analysis of SGA proportions
use "J:/temp/wgodwin/sga/data/02_collapsed/USA/USA_2003_collapse_group_1.dta" 
regress group_1_indic_1 mat_educ
regress group_1_indic_1 i.mat_educ
regress group_1_indic_1 i.mat_educ [fw= group_1_indic_sample] // when incorporate sample size weighting for regression, the relationship between mat_age and SGA becomes significant
regress group_1_indic_1 i.mat_age_rec [fw= group_1_indic_sample]
regress group_1_indic_1 i.mat_age_rec mat_educ [fw= group_1_indic_sample] // use this formula but substitute birth order (number of previous children) in order to 
// examine whether birth order soaks of most of the variation in SGA by maternal age.

regress group_1_indic_1 i.mat_age_rec mat_educ [aw= 1/ group_1_indic_se ]

regress group_1_indic_1 i.mat_age_rec mat_educ [aw= 1/ group_1_indic_se^2 ]
drop group_1_indic_se
gen n_0 = group_1_indic_sample* group_1_indic_0
gen n_1 = group_1_indic_sample* group_1_indic_1
reshape long group_1_indic_ n_,i(id) j(gr) string

use "J:/temp/wgodwin/sga/data/02_collapsed/USA/USA_2003_collapse_group_1.dta" ,clear
tab group_1_indic_sample

gen id = _n
gen n_0 = group_1_indic_sample * group_1_indic_0
gen n_1 = group_1_indic_sample * group_1_indic_1
drop group_1_indic_se
drop group_1_indic_sample
reshape long group_1_indic_ n_,i(id) j(gr) string
replace n_ = round(n_,1)
regress group_1_indic i.mat_age_rec mat_educ [fw= n_]
destring gr,replace force
regress gr i.mat_age_rec mat_educ [fw= n_]

encode mat_race_recode,gen(race)
logit gr i.mat_age_rec mat_educ i.race [fw= n_]


// Using individual level data to regress
// URY analysis
use "J:/temp/wgodwin/sga/data/01_prepped/URY/URY_national_2012_sga_prep.dta", clear
replace mat_age_rec = 1 if mat_age_rec == 1 | mat_age_rec == 2 | mat_age_rec == 3
replace mat_age_rec = 2 if mat_age_rec == 4 | mat_age_rec == 5 | mat_age_rec == 6
replace mat_age_rec = 3 if mat_age_rec == 7 | mat_age_rec == 8 | mat_age_rec == 9 | mat_age_rec == 10

encode mat_educ, gen(maternal_educ)
replace maternal_educ = . if maternal_educ == 2
replace maternal_educ = 1 if maternal_educ == 4
// replace maternal_educ = 4 if maternal_educ == 5
logit sga_all maternal_educ
logit group_1_indic i.maternal_educ // drop missing values for maternal education
logit group_2_indic i.maternal_educ
logit group_3_indic i.maternal_educ
logit sga_all maternal_educ i.mat_age_rec
logit sga_all i.mat_age_rec
logit group_1_indic i.mat_age_rec // 2008, 2009, 2010 has insignificant relationship in all groups
logit group_2_indic i.mat_age_rec // Only group 2 shows significant relationship between mat_age and sga (for 1996, 2001, 2002), very weird. All 3 groups are insignificant with age in 2010
logit group_3_indic i.mat_age_rec // 2007 has only significant relationship between mat_age and sga in group 3
logit group_1_indic i.mat_age_rec maternal_educ
logit group_2_indic i.mat_age_rec maternal_educ
logit group_3_indic i.mat_age_rec maternal_educ

// USA analysis
use "J:/temp/wgodwin/sga/data/01_prepped/USA/USA_states_2010_sga_prep.dta", clear
di in red "reading new file"
logit sga_all i.mat_age_rec
logit sga_all i.mat_age_rec mat_educ
logit sga_all i.mat_educ
encode mat_race_recode,gen(race)
logit sga_all i.mat_age_rec mat_educ i.race
logit group_1_indic i.mat_age_rec
logit group_2_indic i.mat_age_rec
logit group_3_indic i.mat_age_rec
logit group_1_indic i.mat_age_rec mat_educ
logit group_2_indic i.mat_age_rec mat_educ
logit group_3_indic i.mat_age_rec mat_educ
logit sga_all mat_educ i.race
logit sga_all i.race

// Mexico analysis
use "J:/temp/wgodwin/sga/data/01_prepped/MEX/MEX_national_2008_sga_prep.dta", clear
// di in red "reading new file"
// logit sga_all i.mat_age_rec
// logit sga_all num_prev_children i.mat_age_rec // to check if birth order variation explains maternal age variation
encode mat_educ, gen(maternal_educ)
// replace maternal_educ = . if maternal_educ == 1 // for 2008
// replace maternal_educ = 1 if maternal_educ == 4
// replace maternal_educ = 7 if maternal_educ == 2
// replace maternal_educ = 8 if maternal_educ == 3
replace maternal_educ = . if maternal_educ == 1 | maternal_educ == 2 // for 2012, 2011, 2010, 2009
replace maternal_educ = 1 if maternal_educ == 5
//replace maternal_educ = 1 if maternal_educ == 7
//replace maternal_educ = 2 if maternal_educ == 8
//replace maternal_educ = 0 if maternal_educ == 5
// logit sga_all maternal_educ i.mat_age_rec
//logit sga_all i.maternal_educ
logit group_1_indic i.mat_age_rec // for 2012, 2011, 2010, 2009, 2008 group 1 is very independent (interesting)
logit group_2_indic i.mat_age_rec // for 2008, only significant in a few age categories in group 2, 3.
logit group_3_indic i.mat_age_rec
logit group_1_indic i.maternal_educ
logit group_2_indic i.maternal_educ // For 2009, group 1,3 both fairly significant. For 2008, group 1,2 fairly significant. 
logit group_3_indic i.maternal_educ
logit group_1_indic i.mat_age_rec maternal_educ
logit group_2_indic i.mat_age_rec maternal_educ
logit group_3_indic i.mat_age_rec maternal_educ
// Appears that in most years of group 2 and 3, more educated women are at higher risk of SGA, very surprising. This seems to be related to maternal age, in that most older
// mothers are also at higher risk and are likely the ones that are more educated. In 2011, Women with post graduate degree are at significantly higher risk of SGA in many cases.
// This surprising relationship seems to hold pretty well over the years but no consistent relationship between groups appear 

// Can interpret the coefficients by exponentiating, which gives odds in predictor will increase in SGA in comparison to reference group.
// Logit regression outputs gives coefficients that are the log odds relationship between predictor and outcome. So must exponentiate the beta to achieve the odds
// of change in y with 1 unit increase in predictor. Odds are monotonic with probabilities(as odds increase, so does probability) but odds go from 0 to infinity.
// odds = p(1-p)
// The intercept when just "logit sga_all" is the command is simply the overall odds of being SGA in the dataset.

// According to Mehrdad, the output coefficient of logistic regression is a log odds ratio, which when exponentiated, tells the percent likelihood in a success
// (having SGA baby) difference in that specific group versus reference group.

// Generate the values that will be used as threshold for SGA below 33 weeks
clear
local in_dir "J:/temp/wgodwin/sga/data/01_prepped/USA"
local filenames: dir "`in_dir'" files "USA_states_*", respectcase

local count = 1
foreach file of local filenames {
	foreach sex in girls boys {
		gen file_`count' = "`file'"
		local count = `count' + 1
			forvalues x = 21/45 {
				gen week_`x' = .
			}
				tempfile `sex'
				save ``sex'', replace
				clear
		}
	}

import delimited "J:/temp/wgodwin/sga/data/threshold_template.csv", clear
tempfile boys
save `boys', replace
tempfile girls
save `girls', replace
foreach file of local filenames {
	di in red "reading in `file'"
	use "`in_dir'/`file'", clear
	drop if gestage < 21 | gestage > 45
	tempfile master
	save `master', replace
	levelsof gestage, l(gestages)
	foreach age of local gestages {
		forvalues sex = 1/2 {
		use `master', clear
			keep if gestage == `age' & sex == `sex'
			summarize birthweight, detail
			di in red `r(p10)'
			if `sex' == 1 {
				use `boys', clear
				replace week_`age' = `r(p10)' if file == "`file'"
				save `boys', replace
			}
			if `sex' == 2 {
				use `girls', clear
				replace week_`age' = `r(p10)' if file == "`file'"
				save `girls', replace
			}
		}
	}
}

// Generate threshold based on how USA data compares to Lancet reference and then apply that percentage to babies below 33 weeks to find appropriate reference

import delimited "J:/temp/wgodwin/sga/data/sga_threshold_boys.csv", clear
tempfile temp
save `temp', replace
use "J:/temp/wgodwin/sga/data/01_prepped/USA/USA_states_2010_sga_prep.dta", clear
drop if gestage < 21 | gestage > 45 | sex == 2
merge m:1 gestage using `temp'
drop if _m != 3
gen below_ref = .
replace below_ref = 1 if birthweight < birthweight_ref
replace below_ref = 0 if birthweight >= birthweight_ref
collapse (mean) below_ref, by(gestage)

import delimited "J:/temp/wgodwin/sga/data/sga_threshold_girls.csv", clear
tempfile temp
save `temp', replace
use "J:/temp/wgodwin/sga/data/01_prepped/USA/USA_states_2010_sga_prep.dta", clear
drop if gestage < 21 | gestage > 45 | sex == 1
merge m:1 gestage using `temp'
drop if _m != 3
gen below_ref = .
replace below_ref = 1 if birthweight < birthweight_ref
replace below_ref = 0 if birthweight >= birthweight_ref
collapse (mean) below_ref, by(gestage)

// Decided on using 5% of USA 2010 as appropriate percentile to apply to younger babies to find reference for SGA.
import delimited "J:/temp/wgodwin/sga/data/sga_threshold_girls.csv", clear
set obs 1
tempfile boys
save `boys', replace
tempfile girls
save `girls', replace
	forvalues age = 21/32 {
		forvalues sex = 1/2 {
		use `master', clear
			keep if gestage == `age' & sex == `sex'
			summarize birthweight, detail
			di in red `r(p5)'
			if `sex' == 1 {
				use `boys', clear
				replace wk_`age' = `r(p5)'
				save `boys', replace
			}
			if `sex' == 2 {
				use `girls', clear
				replace wk_`age' = `r(p5)'
				save `girls', replace
			}
		}
	}

import delimited "J:/temp/wgodwin/sga/data/boys.csv", clear
tempfile boys_ref
save `boys_ref', replace
merge m:1 gestage using `boys_ref'
scatter birthweight birthweight_ref gestage

// Start to make tables that Mehrdad wants that show SGA prev by preterm group over countries and years
// URY analysis
local in_dir "J:/temp/wgodwin/sga/data/01_prepped"
use "`in_dir'/URY/URY_national_1996_sga_prep.dta", clear
foreach year in 1997 1999 2000 2001 2002 2007 2008 2009 2010 2011 2012 2013 2014 {
	append using "`in_dir'/URY/URY_national_`year'_sga_prep"
}
	foreach group in wk_21_27 wk_28_31 wk_32_36 wk_37_42	{
		preserve
		drop if `group'_tag != 1
		collapse (count) `group' (mean) mean_sga=`group', by(gestage year_start) fast
		tempfile `group'2
		save ``group'2', replace
		// scatter mean_sga year_start [fw=`group'], by(gestage)
		// scatter mean_sga year_start, by(gestage)
		// graph save "`in_dir'/URY/`group'", replace
		restore
	}

// append using "J:/temp/wgodwin/sga/data/01_prepped/URY/URY_national_2001_sga_prep.dta"
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
replace mat_educ = "None" if mat_educ == "Ninguno" | regexm(mat_educ, "Sin Instrucción")
replace mat_educ = "Primary" if regexm(mat_educ, "Primaria")
replace mat_educ = "Secondary" if regexm(mat_educ, "Secundaria")
replace mat_educ = "College" if regexm(mat_educ, "Terciaria")
replace mat_educ = "Not indicated" if regexm(mat_educ, "No indicado")
foreach group in wk_21_27 wk_28_31 wk_32_36 	{
		preserve
		drop if `group'_tag != 1
		table mat_age_rec, c(mean `group' n `group' ) by(year_start)
		table mat_educ, c(mean `group' n `group') by(year_start)
		restore
}

// MEX analysis
local in_dir "J:/temp/wgodwin/sga/data/01_prepped"
use "`in_dir'/MEX/MEX_national_2008_sga_prep.dta", clear
foreach year in 2009 2010 2011 2012 {
	append using "`in_dir'/MEX/MEX_national_`year'_sga_prep", force
}
save "`in_dir'/MEX/MEX_prepped_master", replace
	foreach group in wk_21_27 wk_28_31 wk_32_36 	{
		use "`in_dir'/MEX/MEX_prepped_master", clear
		drop if `group'_tag != 1
		table mat_educ, c(mean `group' n `group') by(year_start)
		table mat_age_rec, c(mean `group' n `group') by(year_start)
	}

// USA analysis **run on cluster if need be
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

local in_dir "$j/temp/wgodwin/sga/data/01_prepped"
use "`in_dir'/USA/USA_states_1990_sga_prep.dta", clear
foreach year in 1995 2000 2005 2010 {
	append using "`in_dir'/USA/USA_states_`year'_sga_prep", force
}
encode mat_race_recode, gen(mat_race_num)
label variable year_start year
label variable mat_age_rec Maternal_age
label variable mat_race_num Maternal_race
label variable mat_educ Maternal_education
replace mat_age_rec = 1 if mat_age_rec == 1 | mat_age_rec == 2 | mat_age_rec == 3
replace mat_age_rec = 2 if mat_age_rec == 4 | mat_age_rec == 5 | mat_age_rec == 6
replace mat_age_rec = 3 if mat_age_rec == 7 | mat_age_rec == 8 | mat_age_rec == 9 | mat_age_rec == 10
rename group_3_indic wk_32_36
rename group_2_indic wk_28_31
rename group_1_indic wk_21_27
gen wk_32_36_tag=1 if gestage >= 32 & gestage < 37
gen wk_28_31_tag=1 if gestage >= 28 & gestage < 32
gen wk_21_27_tag=1 if gestage >= 21 & gestage < 28

log using "$j/temp/wgodwin/sga/data/00_logfiles/USA_smoking_alc"
foreach group in wk_21_27 wk_28_31 wk_32_36 	{
		use "`in_dir'/USA/states_master_tables2", clear
		label variable mat_educ "Education of Mother"
		label variable year_start Year
		label variable mat_race_recode Maternal_race
		label variable mat_age_rec "Age of mother"
		tostring smoker, replace
		replace smoker = "Yes" if smoker == "1"
		replace smoker = "No" if smoker == "2"
		tostring alcohol, replace
		replace alcohol = "Yes" if alcohol == "1"
		replace alcohol = "No" if alcohol == "2"

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
gen maternal = .
replace mat_educ = "None" if regexm(mat_educ, "Sin Instrucción")
replace mat_educ = "Primary" if regexm(mat_educ, "Primaria Completa")
replace mat_educ = "Secondary" if regexm(mat_educ, "UTU Completa")
replace mat_educ = "Tertiary" if regexm(mat_educ, "Terciaria Completa")
replace mat_educ = "Missing" if regexm(mat_educ, "No indicado")

collapse (mean) sga_all, by(sga_all birthweight gestage num_prev_children pweight mat_educ instit_birth c_section plurality mat_age_rec sexoh year_start) fast

******For the creation of the scatters of sga prevalence over time in USA. After collapsing by many possible confounders in order to reduce file size*******
use "`in_dir/USA/collapse_USA4", clear
gen wk_32_36_tag=1 if gestage >= 32 & gestage < 37
gen wk_28_31_tag=1 if gestage >= 28 & gestage < 32
gen wk_21_27_tag=1 if gestage >= 21 & gestage < 28

		drop if `group'_tag != 1
		collapse (count) count_sga=mean_sga (mean) mean_sga [fw=sga_all], by(gestage year_start mat_race_recode mat_age_rec) fast

// Mexico collapse
// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 

local in_dir "$j/temp/wgodwin/sga/data/01_prepped"

** run survey_juicer function (svy_subpop)
run "$j/temp/survey_juicer/tabulations/svy_subpop.ado"

use "`in_dir'/MEX/MEX_prepped_master", clear
** prep for collapse
svyset [pweight=pweight]

gen group_3_tag=1 if gestage >= 32 & gestage < 37
gen group_2_tag=1 if gestage >= 27 & gestage < 32
gen group_1_tag=1 if gestage >= 21 & gestage < 27 // 21 weeks is the frontier according to Theo

	foreach group in group_1 group_2 group_3 {
		preserve
		drop if `group'_tag != 1
		bysort mat_educ mat_age_rec num_prev_children prenat_attn year_start instit_birth c_section plurality gestage: svy_subpop sga_all, tab_type("prop") replace
		save "", replace
		restore
	}

// Protocol for generating sga prevalence over time by gestage is to collapse by gestage, save as csv, generate a column for each gestage, then twoway scatter it.

foreach iso3 in USA MEX URY {
	use "J:/temp/wgodwin/sga/data/02_collapsed/`iso3'/wk_37_42", clear
	rename mean_sga `iso3'_wk_
	drop sga_all
	reshape wide `iso3'_wk_, i(year_start) j(gestage)
	tempfile `iso3'
	save ``iso3'', replace
}
rename mean_sga `iso3'_wk_
drop wk_32_36
reshape wide mex_wk_, i(year_start) j(gestage)
twoway connected mex_wk_* year_start, title("Mexico SGA Prevalence by Gestational Age")
twoway connected ury_wk_* year_start, title("Uruguay SGA Prevalence by Gestational Age")
label variable mean_sga "SGA Proportion"
rename mean_sga mex_wk_
drop sga_all
label variable year_start Year
graph save "J:/temp/wgodwin/sga/data/02_collapsed/MEX/wk_32_36"
twoway connected ury_wk_* USA_wk_* MEX_wk_* year_start, title("URY(blue), USA(red), MEX(green) SGA Prev for 32-36 weeks") lcolor(midblue midblue midblue midblue midblue cranberry cranberry cranberry cranberry cranberry green green green green green) mcolor(midblue midblue midblue midblue midblue cranberry cranberry cranberry cranberry cranberry green green green green green) legend(off)
twoway connected USA_wk_* MEX_wk_* URY_wk_* year_start, title("USA(red), MEX(green), URY(blue) SGA Prev for 37-42 weeks") lcolor(cranberry cranberry cranberry cranberry cranberry cranberry green green green green green green midblue midblue midblue midblue midblue midblue) mcolor(cranberry cranberry cranberry cranberry cranberry cranberry green green green green green green midblue midblue midblue midblue midblue midblue) legend(off)
twoway connected ury_wk_* usa_wk_* mex_wk_* year_start, title("URY(blue), USA(red), MEX(green) SGA Prev for 28-31 weeks") lcolor(midblue midblue midblue midblue cranberry cranberry cranberry cranberry green green green green) mcolor(midblue midblue midblue midblue cranberry cranberry cranberry cranberry green green green green) legend(off)
twoway connected usa_wk_* mex_wk_* year_start, title("USA(red), MEX(green) SGA Prev for 21-27 weeks") lcolor(cranberry cranberry cranberry cranberry cranberry cranberry cranberry green green green green green green green green) mcolor(cranberry cranberry cranberry cranberry cranberry cranberry cranberry green green green green green green green green) legend(off)
twoway connected usa_sga mex_sga year_start, title("USA and MEX SGA Prev-under 27 weeks") lcolor(cranberry green) mcolor(cranberry green) legend(order(1 "USA" 2 "Mexico"))
twoway connected usa_sga mex_sga ury_sga year_start, title("USA, MEX, URY SGA Prev-28-31 weeks") lcolor(cranberry green midblue) mcolor(cranberry green midblue) legend(order(1 "USA" 2 "Mexico" 3 "Uruguay"))
twoway connected usa_sga mex_sga ury_sga year_start, title("SGA Prev in babies 32-36 weeks") lcolor(cranberry green midblue) mcolor(cranberry green midblue) legend(order(1 "USA" 2 "Mexico" 3 "Uruguay"))
twoway connected usa_sga mex_sga ury_sga year_start, title("SGA Prev in babies 37-42 weeks") lcolor(cranberry green midblue) mcolor(cranberry green midblue) legend(order(1 "USA" 2 "Mexico" 3 "Uruguay"))

label variable mex_sga "SGA Proportion"
label variable usa_sga "SGA Proportion"
rename mean_sga mex_sga
***** Work on generating same scatters but with USA and MEX and URY on the same graph, for each gestational week (maybe in groups of 3 weeks?). 
// Also make these graphs for URY. Can be done with lines that start at 380
// Cannot really use country-year specific data from URY to examine 21-32 week babies by gestational age because sample size is tiny since many of the sources
// have only a few babies(or none) at like 21 weeks.
// Will need to figure out how to use different dashed lines based on country

// Prep lit dataset that Mehrdad wants
import excel "J:/temp/wgodwin/sga/data/04_get_estimates/sga_lit.xlsx", clear firstrow
gen year_id = round(year_start, 5)
tempfile master
save `master', replace

// Prep and merge on epi's estimates of prevalence within each GA group 
	foreach group in wk_21_27 wk_28_31 wk_32_36 {
		use "J:/temp/wgodwin/sga/data/04_get_estimates/estimates_`group'.dta", clear
		keep location_id year_id sex_id mean
		preserve
			collapse (mean) mean, by(year_id location_id)
			gen sex_id = 3
			tempfile both
			save `both', replace
		restore
		append using `both'
		rename mean `group'_prev
		tempfile `group'
		save ``group'', replace
		if "`group'" == "wk_32_36" {
			merge 1:1 year_id location_id sex_id using `wk_21_27', nogen
			merge 1:1 year_id location_id sex_id using `wk_28_31', nogen
		}
	}
	
	merge 1:m location_id year_id sex_id using `master', keep(3) nogen
	drop year_id premature_group*
	order location_id country sex_id year_start year_end birthweightbin reported_prop wk_21_27_prev wk_28_31_prev wk_32_36_prev wk_37_42
	export delimited "J:\temp\wgodwin\sga\data\04_get_estimates\sga_lit", replace
// Calculated means of <1500 and <2500 by GA group in the 03_collapse_child script on the cluster

import excel "J:\WORK\05_risk\risks\wash_water\data\rr\review_studies_info.xlsx", clear firstrow
foreach var in effectsize lower95confidenceinterval upper95confidenceinterval numberofobservations {
destring `var', replace force
}
gen log_se = log((upper95 - lower95)/3.92)
gen log_effect = log(effectsize)
gen se = (upper95 - lower95)/3.92

keep if regexm(intervention, "POU")
drop if effectsize == .
tempfile all
save `all', replace

drop if regexm(intervention, "filter")
tempfile chlo_all
save `chlo_all', replace

use `all', clear
keep if regexm(intervention, "filter")
tempfile filter_all
save `filter_all', replace

log using "J:\WORK\05_risk\risks\wash_water\data\rr\new_studies_comparison", replace
di in red "Below are results including new meta-analysis studies-FILTER"
metaan effectsize se, fe
drop if numberofobservations < 1
di in red "Below are results excluding new meta-analysis studies-FILTER"
metaan effectsize se, fe

use `chlo_all', replace
di in red "Below are results including new meta-analysis studies-Chlorine/Solar"
metaan effectsize se, fe
drop if numberofobservations < 1
di in red "Below are results excluding new meta-analysis studies-Chlorine/Solar"
metaan effectsize se, fe
log close

import excel "J:\WORK\05_risk\risks\wash_water\data\rr\new_review_meta.xlsx", firstrow clear
gen se = (upper95 - lower95)/3.92
tempfile all
save `all', replace

keep if regexm(intervention, "filter")
tempfile filter
save `filter', replace
metaan effectsize se, fe

use `all', clear
keep if intervention == "solar" | intervention == "chlorine"
tempfile chlorine
save `chlorine', replace
metaan effectsize se, fe


gen gbd_component = "Risk Factors"
gen sub_component = ""
gen me_id = 8944
gen cause_id = .
gen rei_id = .
gen sequela_id = .
gen covariate_id = .
gen measure = 18
gen ignore = ""
gen release = "gbd_2015"
gen underlying_nid = .
gen source_type = .
gen not_population_data = .
gen sex = 3
rename startyear year_start
rename endyear year_end
gen age_start = .
gen age_end = .
gen age_type = .
gen sample_size = .
rename iwater_sem standard_error
gen representative_name = "National"
gen urbanicity_type = .
gen case_diagnostics = .
gen meta_analysis_or_component_study = .
rename iwater_mean value_mean
keep gbd_component sub_component me_id cause_id rei_id sequela_id covariate_id location_id iso3 measure ignore release nid underlying_nid source_type not_population_data sex year_start year_end age_start age_end age_type sample_size standard_error representative_name urbanicity_type case_diagnostics meta_analysis_or_component_study value_mean
order gbd_component sub_component me_id cause_id rei_id sequela_id covariate_id location_id iso3 measure ignore release nid underlying_nid source_type not_population_data sex year_start year_end age_start age_end age_type sample_size standard_error representative_name urbanicity_type case_diagnostics meta_analysis_or_component_study value_mean
