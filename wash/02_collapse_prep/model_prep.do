// Purpose: Prepare tabulated data from ubcov for ST-GPR modeling for HAP and WaSH indicators
// Date: 1/6/17


// Setup
if c(os) == "Unix" {
	local j "/home/j"
	set odbcmgr unixodbc
}
else if c(os) == "Windows" {
	local j "J:"
}

clear all
set maxvar 10000
set more off

// Set locals
	local watersan_db 	"J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Compiled/prev_all_final_with_citations.dta"
	local hwt_dir	 	"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/data/compile"
	local hwws_report	"J:/WORK/05_risk/risks/wash_hygiene/data/exp/reports"
	local wash_report	"J:\WORK\05_risk\risks\wash_water\data\exp\01_data_audit\tabs"
	local hap_dir 		"J:/temp/wgodwin/wash_exposure/03_upload/hap"
	local hap_path 		"ubcov_tabulation_wgodwin_2017-01-26.csv"
	local ubcov_dir		"J:/temp/wgodwin/wash_exposure/03_upload"
	local ubcov_path 	"tabulation_06022017.csv"
	local code_path 	"H:/rf_code/wash/02_collapse"
	local out_dir 		"J:/temp/wgodwin/gpr_input/run1"
	local keep_vars 	"var nid survey_name ihme_loc_id year_start year_end mean standard_error sample_size design_effect"
	adopath + "`j'/temp/central_comp/libraries/current/stata"

// Bring in tabulated data and produce separate datasets by indicator
	import delimited "`ubcov_dir'/`ubcov_path'", clear
	levelsof var, local(indicators)
	foreach indic of local indicators {
		preserve
			keep `keep_vars'
			drop if ihme_loc_id == "" 
			drop if mean > 1 & mean < 10000
			keep if var == "`indic'"
			duplicates drop ihme_loc_id year_start nid, force
			// rename (mean standard_error) ("`indic'"_mean_2016 "`indic'"_se_2016)
			tempfile `indic'
			save ``indic'', replace
		restore
	}

// Call hap_prep code, which adjust for family size and produces model ready data
// do "`code_path'/hap_prep.do"
// export delimited "`out_dir'/air_hap2.csv", replace

****************************************
****************WATER*******************
****************************************
// Prep water to model
use "`watersan_db'", clear
keep if plot == "Report"
keep nid iso3 year_start endyear filepath_full iwater_mean iwater_sem ipiped_mean ipiped_sem location_name location_id
rename iso3 ihme_loc_id
tempfile water_2015
save `water_2015', replace

use `improved_water', clear
drop if mean < 0
duplicates drop ihme_loc_id year_start nid, force // deleting two duplicates IDN surveys, CHECK ON WHY
merge 1:1 ihme_loc_id year_start nid using `water_2015', nogen
gen imp_water_2015 = iwater_mean - ipiped_mean
twoway (scatter mean imp_water_2015) (function y=x), ytitle(new) xtitle(old) title (Scatter plot: 2016 mean and 2015 mean by data extraction)
gen change = (mean-imp_water_2015)/imp_water_2015 // much of the change is driven by new categrization of strings
preserve
	keep if change != .
	order location_name ihme_loc_id year_start year_end mean standard_error imp_water_2015 iwater_sem change
	br if change > .5 | change < -.5
restore

// Prep get_location_metadata dataset for merge
preserve
	// get_location_metadata, location_set_id(22) clear 
	use "J:/temp/wgodwin/diagnostics/loc_metadata.dta", clear
	keep location_id region_id super_region_id ihme_loc_id location_name
	duplicates drop ihme_loc_id, force
	tempfile loc 
	save `loc', replace
restore

// Merge on get_location_metadata to make sure all locations have location_id
	// replace ihme_loc_id = iso3 if mi(ihme_loc_id)
	drop location_id
	merge m:1 ihme_loc_id using `loc', keep(1 3) nogen
	drop if location_id == .

//Format and clean for modelling
	gen data = mean
	replace data = imp_water_2015 if data == .
	gen variance = standard_error^2
	replace variance = iwater_sem^2 if variance == .
	gen age_group_id = 22
	gen sex_id = 3
	rename year_start year_id
	drop if data == 1 | data == 0 // won't work in logit space and unrealistic values
	gen me_name = "wash_water_imp"
	keep nid location_name location_id year_id sample_size variance me_name data age_group_id sex_id ihme_loc_id

	// Outliers
	replace data = . if ihme_loc_id == "COL" & nid == 19341
	replace data = . if ihme_loc_id == "COL" & nid == 3100
	replace data = . if ihme_loc_id == "EGY" & nid == 19472
	replace data = . if ihme_loc_id == "RWA" & nid == 26930
	export delimited "`out_dir'/wash_water_imp2.csv", replace

// Format piped water dataset in preparation for ST-GPR
	use "`piped'", clear
	rename (mean standard_error) (piped_mean_2016 piped_se_2016)
	duplicates drop ihme_loc_id year_start nid, force // deleting two duplicates IDN surveys, CHECK ON WHY

// Merge on 2015 data that's not in ubcov and the ubcov improved water values
merge 1:1 ihme_loc_id year_start nid using `water_2015', nogen
// merge 1:1 location_name year_start nid using `improved_water', keepusing(improved_water_mean_2016 improved_water_se_2016)

drop if piped_mean_2016 == 1 | piped_mean_2016 <= 0
drop if ipiped_mean == 1 | ipiped_mean == 0
replace piped_mean_2016 = ipiped_mean if piped_mean_2016 == . 
replace piped_se_2016 = ipiped_sem if piped_se_2016 == .
twoway (scatter piped_mean_2016 ipiped_mean) (function y=x), ytitle(new) xtitle(old) title (Scatter plot: 2016 mean and 2015 mean by data extraction)

	// Append on report data
	preserve
		import delimited "`wash_report'/bra_wash.csv"
		rename piped data
		replace data = data/total_water if count == 1
		tempfile report
		save `report'
	restore
	append using `report'

// Merge on get_location_metadata to make sure all locations have location_id
	// replace ihme_loc_id = iso3 if mi(ihme_loc_id)
	drop location_id
	merge m:1 ihme_loc_id using `loc', keep(1 3) nogen
	drop if location_id == .

//Format and clean for modelling
	gen data = piped_mean_2016
	gen variance = piped_se_2016^2
	gen age_group_id = 22
	gen sex_id = 3
	rename year_start year_id
	drop if data == 1 | data == 0 // won't work in logit space and unrealistic values
	gen me_name = "wash_water_piped"
	keep nid location_name location_id year_id sample_size variance me_name data age_group_id sex_id ihme_loc_id
	summ variance, detail
	local thres `r(p95)'
	// gen cv_nonsv= 1 if variance < `thres'
	replace variance = `thres' if variance == .

// Outliers
	replace data = . if ihme_loc_id == "COM" & nid == 3114
	replace data = . if ihme_loc_id == "MEX" & nid == 8442
	replace data = . if ihme_loc_id == "MEX" & nid == 56480
	replace data = . if ihme_loc_id == "MEX" & nid == 264590
	replace data = . if ihme_loc_id == "ZMB" & nid == 13842
	replace data = . if ihme_loc_id == "PAN" & nid == 94127
	replace data = . if ihme_loc_id == "PAN" & nid == 161587
	replace data = . if ihme_loc_id == "TUR" & nid == 56509
	replace data = . if ihme_loc_id == "TUR" & nid == 13012
	replace data = . if ihme_loc_id == "SEN" & nid == 218592
	replace data = . if ihme_loc_id == "PAK" & nid == 104236
	replace data = . if ihme_loc_id == "BRA" & nid == 19027


	export delimited "`out_dir'/wash_water_piped2.csv", replace

******************************************
********HOUSEHOLD WATER TREATMENT*********
******************************************
// Prep for modeling
local cats "wash_water_itreat_piped wash_water_itreat_imp wash_water_itreat_unimp wash_water_tr_piped wash_water_tr_imp wash_water_tr_unimp"
foreach cat of local cats {
	use ``cat'', clear
	merge m:1 ihme_loc_id using `loc', keep(1 3) nogen
	gen data = mean
	gen variance = (standard_error)^2
	gen age_group_id = 22
	gen sex_id = 3
	rename year_start year_id
	drop if data == 1 | data == 0 | data == . // won't work in logit space and unrealistic values
	gen me_name = "`cat'"
	keep nid location_name location_id year_id sample_size variance me_name data age_group_id sex_id ihme_loc_id
	export delimited "`out_dir'/`cat'.csv", replace
}

******************************************
****************HANDWASHING***************
******************************************
//Append on report data
import delimited "`hwws_report'/tabulations.csv", clear
tempfile reports
save `reports'

use "`handwashing'", clear
append using `reports'

// Outliering
drop if nid == 20567 & ihme_loc_id == "NGA" & year_id == 2003 // implausibly high value
drop if nid == 26855 & ihme_loc_id == "SEN" & year_id == 2005 // implausibly high value

//Format and clean for modelling
	gen data = mean
	gen variance = standard_error^2
	gen age_group_id = 22
	gen sex_id = 3
	rename year_start year_id
	drop if data == 1 | data == 0 // won't work in logit space and unrealistic values
	gen me_name = "wash_hwws"
	keep nid location_name location_id year_id sample_size variance me_name data age_group_id sex_id ihme_loc_id
	export delimited "`out_dir'/wash_hwws.csv", replace




******************************************
****************SANITATION****************
******************************************
// Prep 2015 sanitation results to model
use "`watersan_db'", clear
keep nid iso3 year_start endyear filepath_full isanitation_mean isanitation_sem isewer_mean isewer_sem location_name location_id
rename iso3 ihme_loc_id
gen imp_san_2015 = isanitation_mean - isewer_mean
tempfile san_2015
save `san_2015', replace

// Bring in ubcov generated values
use `improved_san', clear
duplicates drop ihme_loc_id year_start nid, force // deleting two duplicates IDN surveys, CHECK ON WHY
save `improved_san', replace
merge 1:1 ihme_loc_id year_start nid using `san_2015'
twoway (scatter mean imp_san_2015) (function y=x), ytitle(new) xtitle(old) title (Scatter plot: 2016 mean and 2015 mean by data extraction)
gen change = (mean-imp_san_2015)/imp_san_2015 // much of the change is driven by new categrization of strings
preserve
	keep if change != .
	order location_name ihme_loc_id year_start year_end mean standard_error imp_san_2015 isanitation_sem change
	br if change > .5 | change < -.5
restore
*******TEMP Outliering**************
	drop if (change > .5 | change < -.5) & change != . & mean >.1

// Prep get_location_metadata dataset for merge
preserve
	get_location_metadata, location_set_id(22) clear 
	keep location_id region_id super_region_id ihme_loc_id location_name
	duplicates drop ihme_loc_id, force
	tempfile loc 
	save `loc', replace
restore

// Merge on get_location_metadata to make sure all locations have location_id
	replace ihme_loc_id = iso3 if mi(ihme_loc_id)
	drop location_id
	merge m:1 ihme_loc_id using `loc', keep(1 3) nogen
	drop if location_id == .

//Format and clean for modelling
	gen data = mean
	replace data = isanitation_mean if data == .
	gen variance = standard_error^2
	replace variance = isanitation_sem^2 if variance == .
	gen age_group_id = 22
	gen sex_id = 3
	rename year_start year_id
	drop if data == 1 | data == 0 // won't work in logit space and unrealistic values
	gen me_name = "wash_sanitation_imp"
	keep nid location_name location_id year_id sample_size variance me_name data age_group_id sex_id ihme_loc_id

// Outliers
	replace data = . if nid == 20154 & ihme_loc_id == "KGZ" // implausibly low
	replace data = . if nid == 12595 & ihme_loc_id == "TJK" // implausibly low
	replace data = . if nid == 13436 & ihme_loc_id == "UZB" // implausibly low
	replace data = . if nid == 21033 & ihme_loc_id == "UZB" // implausibly low
	replace data = . if nid == 4916 & ihme_loc_id == "GUY" // implausibly low
	replace data = . if nid == 4926 & ihme_loc_id == "GUY" // implausibly low
	replace data = . if nid == 20478 & ihme_loc_id == "NIC" // implausibly low **COME BACK TO THESE TWO
	replace data = . if nid == 20487 & ihme_loc_id == "NIC" // implausibly low **COME BACK TO THESE TWO
	replace data = . if nid == 19511 & ihme_loc_id == "EGY" // implausibly low due to "tradtional with flush" treated as unimproved
	replace data = . if nid == 19529 & ihme_loc_id == "EGY" // implausibly low due to "tradtional with flush" treated as unimproved
	replace data = . if nid == 3583 & ihme_loc_id == "EGY" // PAPCHILD survey with 40% sanitaion obs classified as "other"
	replace data = . if nid == 565 & ihme_loc_id == "AFG" // implausibly high
	replace data = . if nid == 20092 & ihme_loc_id == "KAZ" // implausibly high



	export delimited "`out_dir'/wash_sanitation_imp_ubcov.csv", replace

// Format sewer dataset in preparation for ST-GPR
	use "`sewer'", clear
	duplicates drop ihme_loc_id year_start nid, force // deleting two duplicates IDN surveys, CHECK ON WHY
	rename (mean standard_error) (sewer_mean_2016 sewer_se_2016)

// Merge on 2015 data that's not in ubcov and improved water values
merge 1:1 ihme_loc_id year_start nid using `san_2015', nogen
//merge 1:1 location_name year_start nid using `improved_san', keepusing(mean standard_error)

// Clean up dataset and create one sewer variable using new ubcov sources and old 2015 sources
drop if sewer_mean_2016 == 1 | sewer_mean_2016 == 0
drop if isewer_mean == 1 | isewer_mean == 0
replace sewer_mean_2016 = isewer_mean if sewer_mean_2016 == . 
replace sewer_se_2016 = isewer_sem if sewer_se_2016 == .
twoway (scatter sewer_mean_2016 isewer_mean) (function y=x), ytitle(new) xtitle(old) title (Scatter plot: 2016 mean and 2015 mean by data extraction)

gen change = (sewer_mean_2016-isewer_mean)/isewer_mean // much of the change is driven by new categrization of strings
preserve
	keep if change != .
	order location_name ihme_loc_id year_start year_end sewer_mean_2016 sewer_se_2016 isewer_mean isewer_sem change
	br if (change > .5 | change < -.5) & change != .
restore

***********TEMP OUTLIERING***********
	drop if (change > .5 | change < -.5) & change != . & sewer_mean_2016 > .1 & ihme_loc_id != "EGY"

// Merge on get_location_metadata to make sure all locations have location_id
	replace ihme_loc_id = iso3 if mi(ihme_loc_id)
	drop location_id
	merge m:1 ihme_loc_id using `loc', keep(1 3) nogen
	drop if location_id == .

//Format and clean for modelling
	gen data = sewer_mean_2016
	gen variance = sewer_se_2016^2
	gen age_group_id = 22
	gen sex_id = 3
	rename year_start year_id
	drop if data == 1 | data == 0 | data == . // won't work in logit space and unrealistic values
	gen me_name = "wash_sanitation_piped"
	keep nid location_name location_id year_id sample_size variance me_name data age_group_id sex_id ihme_loc_id
	summ variance, detail
	local thres `r(p95)'
	// gen cv_nonsv= 1 if variance < `thres'
	replace variance = `thres' if variance == .
//OUTLIERING
	replace data = . if nid == 21856 & ihme_loc_id == "SVN" // throwing off trend
	replace data = . if	nid == 43226 & ihme_loc_id == "THA" // too small
	replace data = . if nid == 43231 & ihme_loc_id == "THA" // too small
	replace data = . if nid == 43221 & ihme_loc_id == "THA" // too small
	replace data = . if nid == 39396 & ihme_loc_id == "IRN" // census that doesn't ask appropriate question
	replace data = . if nid == 154897 & ihme_loc_id == "EGY" // too large
	replace data = . if nid == 19499 & ihme_loc_id == "EGY" // too small
	replace data = . if nid == 3583 & ihme_loc_id == "EGY" // PAPCHILD survey with 40% sanitaion obs classified as "other"
	replace data = . if nid == 19341 & ihme_loc_id == "COL" // throwing off trend
	replace data = . if nid == 20326 & ihme_loc_id == "MEX" // throwing off trend
	replace data = . if nid == 275090 & ihme_loc_id == "PER" // go back to extraction
	replace data = . if nid == 270404 & ihme_loc_id == "PER" // go back to extraction
	replace data = . if nid == 270469 & ihme_loc_id == "PER" // go back to extraction
	replace data = . if nid == 270470 & ihme_loc_id == "PER" // go back to extraction
	replace data = . if nid == 270471 & ihme_loc_id == "PER" // go back to extraction
	replace data = . if nid == 146860 & ihme_loc_id == "PER" // go back to extraction
	gen BOL = 1 if nid == 1357 | nid == 18990
	replace data = . if ihme_loc_id == "BOL" & BOL != 1
	export delimited "`out_dir'/wash_sanitation_piped2.csv", replace



******************************************
***************BREASTFEEDING**************
******************************************
// use "J:/WORK/01_covariates/02_inputs/breastfeeding/01_Data_Audit/Compile/data/BF_rates_all_surveys.dta", clear
import delimited "`out_dir'/abf_0to5.csv", clear
replace data = . if ihme_loc_id == "USA" & nid == 145027 // implausibly low

// Added abf rates from "https://www.cdc.gov/BREASTFEEDING/DATA/NIS_data/#modalIdString_CDCTable_1" directly into dataset-2/6/2017
export delimited "`out_dir'/abfrate0to5.csv"




local vars "wash_water_imp wash_sanitation_imp wash_hwws wash_water_itreat_imp air_hap"
foreach var of local vars {
	import delimited "J:/temp/wgodwin/gpr_input/run1/`var'", clear
	//keep if var == "`var'"
	gen num = 1
	collapse (sum) num, by(ihme_loc_id)
	rename num mapvar
	// gen var = "`var'"
	export delimited "J:/temp/wgodwin/review_week/collapse_`var'", replace
}
