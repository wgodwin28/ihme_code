// File Name: prepare_data.do

// File Purpose: Prepare water and sanitation data for smoothing
// Author: Leslie Mallinger
// Date: 7/1/10
// Edited: Will Godwin
// Edited on: 12/14/15

// Additional Comments: 
clear all
set more off
capture log close
capture restore, not

** create locals for relevant files and folders
local dat_folder_compiled 		"J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Compiled"
local input_folder 				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/smoothing/spacetime input"
local merge_2013				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output"
local functions					"J:\temp\central_comp\libraries\current\stata"
local get_demo					"`functions'/get_demographics.ado"
local get_location				"`functions'/get_location_metadata.ado"
local get_covar					"`functions'/get_covariate_estimates.ado"
local get_nid					"J:\WORK\01_covariates\common\ubcov_central\functions\archive\get_nid.ado"
local output_folder				"H:/wash/source_sanitation"
local dhs_subnat				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/DHS/DHS_mapped_noloc_split.dta"
local ipums_subnat				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/IPUMS/IPUMS_mapped.dta"
local chns_subnat				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/CHNS/prev_CHNS_mapped.dta"
local ken_subnat				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/DHS/DHS_KEN.dta"
local ind_subnat 				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/IND/ind_subnat_clean.csv"
local firstyear					1970

** open dataset with compiled prevalence estimates; remove unnecessary entries and variables
	// open file
	use "`dat_folder_compiled'/prev_all_final_with_citations.dta", clear	
	rename startyear year
	drop if year < `firstyear'
	gen national = (subnational != 1)
	replace national = 0 if nopsu == "1" | noweight == "1"
	drop subnational nopsu noweight
	
	// tag water outliers
	preserve
		insheet using "`input_folder'/outliers_water.csv", comma clear names
		tempfile outliers_water
		save `outliers_water', replace
	restore
	
	merge m:1 location_name year plot national using `outliers_water', keep(1 3)
	
	preserve
		keep if _merge == 3
		drop _merge
		replace plot = "Outlier"
		rename iwater_mean actual_prev
	restore
	gen outlier_water = (_merge == 3)
	drop _merge


	preserve
		insheet using "`input_folder'/outliers_water2.csv", clear
		tempfile outliers_water
		save `outliers_water', replace
	restore
	// model: water_imp_data_id_187_model_166
	
	merge m:1 nid iso3 using `outliers_water', keepusing(iso3 nid) keep (1 3)
	replace outlier_water = 1 if _m == 3
	drop _merge

	// tag piped outliers
	preserve
		insheet using "`input_folder'/outliers_piped.csv", comma clear names
		tempfile outliers_piped
		save `outliers_piped', replace
	restore
	
	merge m:1 location_name year plot national using `outliers_piped', keep(1 3)
	
	preserve
		keep if _merge == 3
		drop _merge
		replace plot = "Outlier"
		rename ipiped_mean actual_prev
	restore
	gen outlier_piped = (_merge == 3)
	drop _merge

	preserve
		insheet using "`input_folder'/outliers_piped2.csv", clear
		tempfile outliers_piped2
		save `outliers_piped2', replace
	restore
// model: water_piped_425_98
	
	merge m:1 nid iso3 using `outliers_piped2', keepusing(iso3 nid) keep (1 3)
	replace outlier_water = 1 if _m == 3
	drop _merge
	
	// tag sanitation outliers
	preserve
		insheet using "`input_folder'/outliers_sanitation.csv", comma clear names
		tempfile outliers_sanitation
		save `outliers_sanitation', replace
	restore
	
	merge m:1 location_name year plot national using `outliers_sanitation', keep(1 3)
	
	preserve
		keep if _merge == 3
		drop _merge
		replace plot = "Outlier"
		rename isanitation_mean actual_prev
	restore
	gen outlier_sanitation = (_merge == 3)
	drop _merge
	
	preserve
		insheet using "`input_folder'/outliers_sanitation2.csv", clear
		tempfile outliers_sanitation2
		save `outliers_sanitation2', replace
	restore
	
	merge m:1 nid iso3 using `outliers_sanitation2', keepusing(iso3 nid) keep (1 3)
	replace outlier_sanitation = 1 if _m == 3
	drop _merge

	// tag sewer outliers
	preserve
		insheet using "`input_folder'/outliers_sewer.csv", comma clear names
		tempfile outliers_sewer
		save `outliers_sewer', replace
	restore
	
	merge m:1 location_name year plot national using `outliers_sewer', keep(1 3)
	
	preserve
		keep if _merge == 3
		drop _merge
		replace plot = "Outlier"
		rename isewer_mean actual_prev
	restore
	gen outlier_sewer = (_merge == 3)
	drop _merge
	
	preserve
		insheet using "`input_folder'/outliers_sewer2.csv", clear
		tempfile outliers_sewer2
		save `outliers_sewer2', replace
	restore
	
	merge m:1 nid iso3 using `outliers_sewer2', keepusing(iso3 nid) keep (1 3)
	replace outlier_sewer = 1 if _m == 3
	drop _merge

duplicates drop nid iso3, force
		
	keep iso3 year endyear filename svy iwater_mean iwater_sem ipiped_mean ipiped_sem ///
		isanitation_mean isanitation_mean isanitation_sem isewer_mean isewer_sem ///
		plot nid outlier* national


	// save
	tempfile estimates
	save `estimates', replace
	
	// Prep to append on subnationals from CHNS, DHS, and IPUMS
	use `chns_subnat', clear
	gen year = regexs(0) if regexm(filepath_full, "[0-9][0-9][0-9][0-9]")
	drop map subnational icombined_mean icombined_sem 
	destring year, replace
	tempfile chns
	save `chns', replace
	
	use `dhs_subnat', clear
	// drop if map == ""
	drop if regexm(iso3, "KEN")
	drop if regexm(filepath_full, "IND")
	drop if iso3 == "IND" | iso3 == "KEN"
	replace ipiped_mean= . if regexm(filepath_full, "BRA_DHS2_1991") // Outliering faulty DHS survey
	tempfile dhs
	save `dhs', replace
	
	import delimited "`ind_subnat'", clear
	rename ihme_loc_id iso3
	tempfile ind
	save `ind', replace
	
	use `ken_subnat', clear
	destring year, replace
	tempfile dhs_ken
	save `dhs_ken', replace
	
	use `ipums_subnat', clear
	rename ihme_loc_id iso3
	drop if iso3 == "BRA" | iso3 == "ZAF"
	replace ipiped_mean = .  if regexm(filepath_full, "MEX_CENSUS_2010_WATER_SAN_Y2014M03D26") // Outliering faulty IPUMS census
	replace iwater_mean = .  if regexm(filepath_full, "MEX_CENSUS_2010_WATER_SAN_Y2014M03D26") // Outliering faulty IPUMS census
	tempfile ipums
	save `ipums', replace
	
	use `estimates', clear
	append using `chns'
	append using `dhs'
	append using `ind'
	append using `dhs_ken'
	append using `ipums'
	
	gen example = regexs(0) if regexm(filepath_full,"[//]([A-z.0-9]*)$")
    gen path = subinstr(filepath_full, example, "", .)
	replace path = subinstr(path,"/","/",.)
	drop example

	tempfile all_estimates
	save `all_estimates', replace
	
// Merge on missing nids
	qui run "`get_nid'"
	get_nid, filepath_full(filepath_full)
	replace nid = record_nid if nid == .

// Hard code in sources that are not in J:/DATA
	replace nid = 2449 if filepath_full == "J:/WORK/01_COVARIATES/02_INPUTS/WATER_SANITATION/DATA/01_DATA_AUDIT/CHNS/MERGED ORIGINAL FILES/CHINA_1993.DTA"
	replace nid = 2494 if filepath_full == "J:/WORK/01_COVARIATES/02_INPUTS/WATER_SANITATION/DATA/01_DATA_AUDIT/CHNS/MERGED ORIGINAL FILES/CHINA_1997.DTA"
	replace nid = 2531 if filepath_full == "J:/WORK/01_COVARIATES/02_INPUTS/WATER_SANITATION/DATA/01_DATA_AUDIT/CHNS/MERGED ORIGINAL FILES/CHINA_2000.DTA"
	replace nid = 2347 if filepath_full == "J:/WORK/01_COVARIATES/02_INPUTS/WATER_SANITATION/DATA/01_DATA_AUDIT/CHNS/MERGED ORIGINAL FILES/CHINA_2004.DTA"
	replace nid = 2577 if filepath_full == "J:/WORK/01_COVARIATES/02_INPUTS/WATER_SANITATION/DATA/01_DATA_AUDIT/CHNS/MERGED ORIGINAL FILES/CHINA_2006.DTA"
	replace nid = 56480 if filepath_full == "J:/DATA/IPUMS_CENSUS/MEX/2010/MEX_CENSUS_2010_WATER_SAN_Y2014M03D26.DTA"
	replace nid = 111432 if filename == "SEN_DHS6_2012_2013_HH_Y2015M09D14.DTA"
	replace nid = 157065 if filename == "UGA_MIS_2014_2015_HH_Y2015M11D06.DTA"
	replace nid = 165390 if filename == "IND_DLHS4_2012_2014_HH_Y2015M12D07.DTA"
	replace nid = 23219 if filename == "USABLE_INT_DLHSII_IND_2002_INDIA_HH.DTA"
	replace nid = 23258 if filename == "CRUDE_INT_DLHS3_IND_2007_HIND.DTA"


	drop record_nid path
	save `all_estimates', replace

// Prep for spacetime by creating square dataset
	// Generate file with all country years
		run "`get_demo'"
		get_demographics, gbd_team("cov") make_template clear
		
	// Customize for specific risk factor modeling
	duplicates drop location_id year_id, force
	replace age_group_id = 22
	replace sex_id = 3
	tempfile demograph
	save `demograph', replace
	
	// Prep to merge on ihme_loc_id from get_location_metadata central function
	run "`get_location'"
	get_location_metadata, location_set_id(22) clear
	keep location_id ihme_loc_id 
	tempfile loc_id
	save `loc_id', replace
	
	// Merge on ihme_loc_id to demographics square
	use `demograph', clear
	merge m:1 location_id using `loc_id', nogen keep (1 3)
	save `demograph', replace
	
	// Prep dataset for merge
	use `all_estimates', clear
	rename iso3 ihme_loc_id
	rename year year_id
	tempfile data
	save `data', replace
	
	// Merge onto square
	use `demograph', clear
	merge 1:m ihme_loc_id year_id using `data', nogen keep (1 3)
	drop svy endyear plot
	tempfile final_data
	save `final_data', replace

	
tempfile check
save `check', replace
// use `check', clear

// MERGE ON COVARIATES
local covariates sds
// ldi_pc education_yrs_pc prop_urban
foreach covar of local covariates {
	preserve
	get_covariate_estimates, covariate_name_short("`covar'") clear
	capture duplicates drop location_id year_id, force
	tempfile `covar'
	save ``covar'', replace
	restore
	merge m:1 location_id year_id using "``covar''", nogen keepusing(mean_value) keep(1 3)
	rename mean_value `covar'
	}

replace national = 1 if regexm(filename, "PMA")

// Replace outliers- Moved this step in front of propotion creation, temporary fix...
	replace iwater_mean = . if outlier_water == 1 | national == 0 
	replace ipiped_mean = . if outlier_piped == 1 | national == 0 | iwater_mean == .
	replace isanitation_mean = . if outlier_sanitation == 1 | national == 0
	replace isewer_mean = . if outlier_sewer== 1 | national == 0 | isanitation_mean == .
	**replace icombined_mean_logit = . if outlier_combined == 1 | national == 0
	
// Transform variables and covariates that warrant it- this step doesn't appear to be necessary since 2013 outputs indicate that ipiped was modeled as prevalence, not as a proportion of improved***NO, NEED TO RE-IMPLEMENT CREATING PROPORTION PIPED AND SEWER
gen ipiped = ipiped_mean/iwater_mean  // run this as a proportion of improved
	drop ipiped_mean
	rename ipiped ipiped_mean

	gen isewer = isewer_mean/isanitation_mean // run this as a proportion of improved
	drop isewer_mean
	rename isewer isewer_mean

	tempfile poo
	save `poo', replace

// Cleanup dataset and prepare to save
	save "`input_folder'/smoothing_dataset_all_water_san_subnat9", replace
	drop outlier_water outlier_piped outlier_sanitation outlier_sewer national location_set_version_id region_id super_region_id
	use "`input_folder'/smoothing_dataset_all_water_san_subnat4", clear
	local it 7
	
// save data and prepare an individual dataset for each exposure that will be modeled
	local exposures iwater ipiped isanitation isewer
	foreach exposure of local exposures {
		preserve
		if "`exposure'" == "iwater" {
			gen me_name = "wash_water_imp"
			local me_name "wash_water_imp"
			merge m:1 ihme_loc_id year_id using "`merge_2013'/w_mean", keep(1 3) nogen
			}
			else if "`exposure'" == "ipiped" {
			gen me_name = "wash_water_piped"
			local me_name "wash_water_piped"
			replace ipiped_mean = .4999999 if nid == 60372
			merge m:1 ihme_loc_id year_id using "`merge_2013'/piped_mean", keep(1 3) nogen
			}
			else if "`exposure'" == "isanitation" {
			gen me_name = "wash_sanitation_imp"
			local me_name "wash_sanitation_imp"
			merge m:1 ihme_loc_id year_id using "`merge_2013'/s_mean", keep(1 3) nogen
			}
			else if "`exposure'" == "isewer" {
			gen me_name = "wash_sanitation_piped"
			local me_name "wash_sanitation_piped"
			merge m:1 ihme_loc_id year_id using "`merge_2013'/sewer_mean", keep(1 3) nogen
			}
		rename `exposure'_mean data
		// Generate appropriate variance
		gen variance = ((`exposure'_sem)^2)
		// summarize variance, detail
		// replace variance = `r(p90)' if variance == . & data !=.
		// Decided centrally to set a variance floor of 0.0001
			// replace variance = 0.002 if variance < 0.002 & data != .
		// drop sample_size
		// rename sample_size_`exposure' sample_size
		// rename stan_dev_`exposure' standard_deviation
		// gen sample_size = .
		// replace sample_size = 35 if variance == . & data !=.
		gen standard_deviation = .
		replace variance = . if data == .
		replace variance = .002 if variance == 0
		replace data = .01 if data == 0
		replace data = . if data >= 1 & data <= 2
		// Excluding state level IND data b/c we only model at the rural/urban level.
			replace data = . if location_id >= 4841 & location_id <= 4875
			replace variance = . if location_id >= 4841 & location_id <= 4875
		keep me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation ihme_loc_id region_name super_region_name gpr_mean2013 gpr_lower2013 gpr_upper2013
		// keep me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation ldi_pc pop_dens_under_150_psqkm_pct education_yrs_pc ihme_loc_id gpr_mean2013 gpr_lower2013 gpr_upper2013
		// order me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation ldi_pc pop_dens_under_150_psqkm_pct education_yrs_pc ihme_loc_id gpr_mean2013 gpr_lower2013 gpr_upper2013
		order me_name location_id year_id sex_id age_group_id data variance nid sample_size standard_deviation ihme_loc_id region_name super_region_name gpr_mean2013 gpr_lower2013 gpr_upper2013
		replace nid = . if data == .
		save "J:/temp/wgodwin/gpr_input/run4/`me_name'`it'", replace
		restore
}


********** END

quiet run "J:/WORK/10_gbd/00_library/functions/create_connection_string.ado"
create_connection_string, server("modeling-epi-db") database("epi") user("readonly") password("justlooking")
local conn_string = r(conn_string)
odbc load, exec("SELECT cause_id, acause FROM shared.cause;") `conn_string' clear

quiet run "J:/WORK/10_gbd/00_library/functions/create_connection_string.ado"
create_connection_string, server("modeling-epi-db") database("epi") user("readonly") password("justlooking")
local conn_string = r(conn_string)
odbc load, exec("SELECT modelable_entity_id, cause_id FROM epi.modelable_entity_cause;") `conn_string' clear

quiet run "J:/WORK/10_gbd/00_library/functions/create_connection_string.ado"
create_connection_string, server("modeling-epi-db") database("epi") user("readonly") password("justlooking")
local conn_string = r(conn_string)
odbc load, exec("SELECT modelable_entity_id, rei_id FROM epi.modelable_entity_rei;") `conn_string' clear

quiet run "J:/WORK/10_gbd/00_library/functions/create_connection_string.ado"
create_connection_string, server("modeling-epi-db") database("epi") user("readonly") password("justlooking")
local conn_string = r(conn_string)
odbc load, exec("SELECT covariate_name, covariate_name_short FROM shared.covariate;") `conn_string' clear

// For sanitation outliers
replace data=. if ihme_loc_id=="UGA" & year_id==2014
replace data=. if ihme_loc_id=="KEN_35646"
replace data=. if year_id==2008 & data<.4 & ihme_loc_id=="KEN"
replace data=. if year_id==2011 & ihme_loc_id=="GNQ"
replace data=. if ihme_loc_id=="MEX_4651" & year_id ==1980
replace data=. if regexm(ihme_loc_id, "MEX") & year_id ==1987

// For querying the database for me_id's and risk factor information
run J:/WORK/05_risk/central/code/risk_utils/risk_info.ado
risk_info, risk(wash_water) clear
// risk_info, risk(wash_sanitation) clear

// For formatting before sending to Edem to upload to covariates db
import delimited "J:/temp/wgodwin/gpr_output/san_imp_output_full_0404.csv", clear
keep location_id year_id age_group_id sex_id gpr_upper gpr_mean gpr_lower
gen covariate_name_short = "sanitation_prop"
rename gpr_mean mean_value
rename gpr_lower lower_value
rename gpr_upper upper_value
duplicates drop location_id year_id age_group_id sex_id, force
order location_id year_id age_group_id sex_id covariate_name_short mean_value lower_value upper_value
gen data_version_id = 459
export delimited "J:\temp\wgodwin\diagnostics\covariates\san_covar2", replace
	
local exposures iwater ipiped isanitation isewer
foreach exp of local exposures {
	replace `exp'_mean = `exp'_mean/100 if `exp'_mean > 1 & `exp'_mean < 100
	}

/*
To do data upload:
save dataset to J temp
Set model setting csv to the correct paths
Open qlogin and navigate to 04model in H drive
Open stata-mp
Type: do "data_upload.do" (no options needed)

To run the model:
Model db csv is used to pull in modeling information for each run (so change this with each run)
Once data is uploaded and you are navigated to the correct place on H drive, do this command: do model.do me_name data_id run_id subnat
Use bitvise to view the outputs and error logs

qdel -u wgodwin: command that closes all jobs
qlogin -now no -P proj_custom_models

new clustertmp path: /share/covariates

Make sure that linear model is plausible (that covariates are informing the direction in the correct trend of the actual risk)
*/
// Possible covariates: pop_dens_over_1000_psqkm_pct, pop_dens_500_1000_psqkm_pct
keep location_id year_id sex_id age_group_id nid sample_size ldi_pc prop_urban education_yrs_pc ihme_loc_id super_region_name region_name iwater_mean ipiped_mean isanitation_mean isewer_mean
local covariates pop_dens_under_150_psqkm_pct
local covariates maternal_educ_yrs_pc sds
foreach covar of local covariates {
	preserve
	run "`get_covar'"
	get_covariate_estimates, covariate_name_short("`covar'") clear
	capture duplicates drop location_name year_id, force
	tempfile `covar'
	save "`covar'", replace
	restore
	merge m:1 location_name year_id using "`covar'", nogen keepusing(mean_value) keep(1 3)
	rename mean_value `covar'
	// gen logit_`covar' = logit(`covar')
	
	}

gen ldi = ln(ldi_pc)
gen urban = logit(prop_urban)
gen pop_dens = logit(pop_dens_under_150_psqkm_pct)
replace pop_dens = -15 if pop_dens_under_150_psqkm_pct == 0
replace pop_dens = 15 if pop_dens_under_150_psqkm_pct == 1
replace urban = 9 if ihme_loc_id == "SGP"
xtmixed iwater_mean ldi urban education_yrs_pc || super_region_name: || region_name: || ihme_loc_id:
regress iwater_mean ldi urban education_yrs_pc
xtmixed iwater_mean pop_dens || super_region_name: || region_name: || ihme_loc_id:
xtmixed iwater_mean pop_dens ldi education_yrs_pc || super_region_name: || region_name: || ihme_loc_id:
xtmixed isanitation_mean urban ldi education_yrs_pc || super_region_name: || region_name: || ihme_loc_id:
xtmixed isanitation_mean pop_dens ldi education_yrs_pc || super_region_name: || region_name: || ihme_loc_id:

xtmixed isewer_mean pop_dens ldi education_yrs_pc || super_region_name: || region_name: || ihme_loc_id:
xtmixed isewer_mean urban ldi education_yrs_pc || super_region_name: || region_name: || ihme_loc_id:

xtmixed ipiped_mean pop_dens ldi education_yrs_pc || super_region_name: || region_name: || ihme_loc_id:
xtmixed ipiped_mean ldi education_yrs_pc urban || super_region_name: || region_name: || ihme_loc_id:


levelsof ihme_loc_id, l(locations)
foreach loc of local locations {
mean iwater_mean if iso3=="`loc'"
local `loc' `e(cmd)'
}
keep if regexm(filepath_full, "BRA_CENSUS_1991")

replace ipiped_mean=. if regexm(filepath_full, "MEX_CENSUS_2010_WATER_SAN_Y2014M03D26")

// dlhs
replace ipiped_mean = . if iso3 == "IND_43872" & year == 2012
replace ipiped_mean = . if iso3 == "IND_43916" & year == 2007 // Delhi rural
replace ipiped_mean = . if iso3 == "IND_43881" & year == 2012 // Goa urban
replace ipiped_mean = . if iso3 == "IND_43918" & year == 2002 // Gujarat rural

// dhs
replace ipiped_mean = . if iso3 == "IND_43909" & year == 2005 // Arunchal Prad rural
replace ipiped_mean = . if iso3 == "IND_43873" & year == 2005 // Arunchal Prad urban
replace ipiped_mean = . if iso3 == "IND_43875" & year == 1992 | year == 1998 // Bihar urban

// Draw normal distributions to calculate variance for piped proportions
clear all
local fastpctile			"J:/WORK/10_gbd/00_library/functions/fastpctile.ado"
local fastrowmean			"J:/WORK/10_gbd/00_library/functions/fastrowmean.ado"
local n 10
matrix m = 33, 78
matrix sd = 2.9, 3.6
drawnorm x y, n(`n') means(m) sds(sd)
summarize
foreach var in varlist {
	gen prop_piped = x/y
}
xpose, clear
keep if _n==3
run "`fastrowmean'"
	fastrowmean v*, mean_var_name(piped_prop_mean)
forvalues x = 1/`n' {
	gen piped_var_`x' = piped_prop_mean - v`x'
}
keep piped_var_*
egen total_var= rowtotal(piped_var_*)
gen final_var = (total_var^2)/`n'
run "`fastpctile'"
fastpctile v*, pct(2.5 97.5) names(piped_lower piped_upper)

// Create template for SEV upload
adopath + "J:/temp/central_comp/libraries/current/stata"
get_demographics_template, gbd_team("cov") gbd_round_id(4) clear
levelsof age_group_ids, local(ages)

get_location_metadata, location_set_id(22) clear
levelsof location_id, local(locations)

clear all
local code_folder	"/snfs2/HOME/wgodwin/rf_code/wash/04_save_results"
local logs 			-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
local stata_shell 	"/home/j/temp/wgodwin/save_results/stata_shell.sh"

foreach location of local locations {
	di in red `location'
	! qsub -N template_`location' -P proj_custom_models -pe multi_slot 2 `logs' "`stata_shell'" "`code_folder'/make_template.do" "`location'"
}


forvalues x = 1980/2016 {
	preserve
	keep if year_id == `x' & ihme_loc_id == "CHN"
	local mean_`x' = mean_sev
	local lower_`x' = lower_sev
	local upper_`x' = upper_sev
	restore
}
forvalues x = 1980/2016 {
	replace mean_sev = `mean_`x'' if mean_sev == . & year_id == `x'
	replace lower_sev = `lower_`x'' if lower_sev == . & year_id == `x'
	replace upper_sev = `upper_`x'' if upper_sev == . & year_id == `x'
}

levelsof location_id, local(loc_ids)
foreach loc of local loc_ids {
	forvalues x = 1980/2016 {
		preserve
		keep if year_id == `x' & location_id == `loc'
		local mean_`x'_`loc' = mean_sev
		local lower_`x'_`loc' = lower_sev
		local upper_`x'_`loc' = upper_sev
		restore
	}
}

foreach loc of local loc_ids {
	forvalues x = 1990/2016 {
		replace mean_sev = `mean_`x'_`loc'' if mean_sev == . & year_id == `x' & location_id == `loc'
		replace lower_sev = `lower_`x'_`loc'' if lower_sev == . & year_id == `x' & location_id == `loc'
		replace upper_sev = `upper_`x'_`loc'' if upper_sev == . & year_id == `x' & location_id == `loc'
	}
}
