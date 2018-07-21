// File Name: prepare_data.do

// File Purpose: Prepare water and sanitation data for smoothing
// Author: Leslie Mallinger
// Date: 7/1/10
// Edited on: 

// Additional Comments: 
clear all
set more off
capture log close
capture restore, not

** create locals for relevant files and folders
local dat_folder_compiled 		"J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Compiled"
local codes_folder 				"J:/DATA/IHME_COUNTRY_CODES"
local urbrur_folder 			"J:/Data/UN_WORLD_POPULATION_PROSPECTS/2008"
global input_folder 			"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/smoothing/spacetime input"
global output_folder 			"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/smoothing/spacetime results"

**last year should include year of update i.e. 2013
local firstyear 1970 
local lastyear 2013

** create template dataset with the years that we're using
clear
set obs 44
gen year = .
forvalues i = 1/44 {
	replace year = 1969 + `i' in `i'
}
gen merge = 1
tempfile years
save `years', replace

** create database with covariates from codem database
**odbc load, exec("SELECT iso3,year,region,super_region,age,sex,LDI_pc,ln_LDI_pc,education_yrs_pc,pop FROM all_covariates WHERE age BETWEEN 15 AND 45") dsn(codmod) clear
**collapse (mean) LDI_pc ln_LDI_pc education_yrs_pc [weight=pop], by(iso3 year region super_region) fast
**tempfile covariates
**save `covariates'


***Create covariates database from J drive using data on LDI and Education.**
**Variables needed in the final dataset: location_id, location_name, iso3, year, region, super_region, LDI_pc, lnLDI_pc, education***

***Import education data***
use "J:/WORK/01_covariates/02_inputs/education/output_data/2013rerun_Education_IHME_1950-2015.dta"
drop educ_25plus maternal_educ
keep if mean_yrseduc!=.
rename national_iso3 iso3
replace iso3="HKG" if regexm(location_name, "Hong Kong")
replace iso3="MAC" if regexm(location_name, "Macao")
replace iso3="XIR" if regexm(location_name, "India, Rural")
replace iso3="XIU" if regexm(location_name, "India, Urban")
tempfile education
save `education'

***Population data***
use "C:\Users\asthak\Documents\Covariates\Water and Sanitation\smoothing\spacetime input\pop_data.dta", clear
tempfile all_pop
sort iso3 
save `all_pop', replace

use `education', clear
merge m:1 iso3 year sex age_group using `all_pop' 
keep if _merge==3
drop _merge
replace subnational_id=. if regexm(location_name, "Hong Kong") | regexm(location_name, "Macao") | regexm(location_name, "India, Rural") | regexm(location_name, "India, Urban")
drop if subnational!=. 

sort location_name year age_group
collapse (mean) mean_yrseduc [weight=pop], by(iso3 year location_name location_id) fast
save `education', replace

***Import LDI_pc data***
use "J:\WORK\01_covariates\02_inputs\LDI_pc\output_data\model_final.dta"
rename model_value LDI_pc
keep iso3 year LDI_pc
gen ln_LDI_id=ln(LDI_pc)

merge 1:1 iso3 year using `education', keepusing(mean_yrseduc)
keep if _merge==3
drop _merge
drop if year>2013

tempfile covariates
save `covariates'

** open dataset with compiled prevalence estimates; remove unnecessary entries and variables
	// open file
	use "`dat_folder_compiled'/prev_all_final.dta", clear
	rename startyear year
	drop if year < `firstyear'
	gen national = (subnational != 1)
	replace national = 0 if nopsu == "1" | noweight == "1"
	drop subnational nopsu noweight
	
	// drop water outliers
	preserve
		insheet using "$input_folder/outliers_water.csv", comma clear names
		tempfile outliers_water
		save `outliers_water', replace
	restore
	
	merge m:1 location_name year plot national using `outliers_water', keep(1 3)
	
	preserve
		keep if _merge == 3
		drop _merge
		replace plot = "Outlier"
		rename iwater_mean actual_prev
		save "$output_folder/water_outliers", replace
	restore
	gen outlier_water = (_merge == 3)
	drop _merge

	//drop piped outliers
	preserve
		insheet using "$input_folder/outliers_piped.csv", comma clear names
		tempfile outliers_piped
		save `outliers_piped', replace
	restore
	
	merge m:1 location_name year plot national using `outliers_piped', keep(1 3)
	
	preserve
		keep if _merge == 3
		drop _merge
		replace plot = "Outlier"
		rename ipiped_mean actual_prev
		save "$output_folder/piped_outliers", replace
	restore
	gen outlier_piped = (_merge == 3)
	drop _merge
	
	//drop sanitation outliers
	preserve
		insheet using "$input_folder/outliers_sanitation.csv", comma clear names
		tempfile outliers_sanitation
		save `outliers_sanitation', replace
	restore
	
	merge m:1 location_name year plot national using `outliers_sanitation', keep(1 3)
	
	preserve
		keep if _merge == 3
		drop _merge
		replace plot = "Outlier"
		rename isanitation_mean actual_prev
		save "$output_folder/sanitation_outliers", replace
	restore
	gen outlier_sanitation = (_merge == 3)
	drop _merge
	
	//drop sewer outliers
	preserve
		insheet using "$input_folder/outliers_sewer.csv", comma clear names
		tempfile outliers_sewer
		save `outliers_sewer', replace
	restore
	
	merge m:1 location_name year plot national using `outliers_sewer', keep(1 3)
	
	preserve
		keep if _merge == 3
		drop _merge
		replace plot = "Outlier"
		rename isewer_mean actual_prev
		save "$output_folder/sewer_outliers", replace
	restore
	gen outlier_sewer = (_merge == 3)
	drop _merge
	
	
	/* drop combined outliers
	preserve
		insheet using "$input_folder/outliers_combined.csv", comma clear names
		tempfile outliers_combined
		save `outliers_combined', replace
	restore
	
	merge m:1 location_name year plot national using `outliers_combined', keep(1 3)
	
	preserve
		keep if _merge == 3
		drop _merge
		replace plot = "Outlier"
		rename icombined_mean actual_prev
		save "$output_folder/combined_outliers", replace
	restore
	gen outlier_combined = (_merge == 3)
	drop _merge */
	
	// save source database for inputs
	preserve
		** mark final sources
		gen water = (iwater_mean != . & outlier_water != 1)
		gen sanitation = (isanitation_mean != . & outlier_sanitation != 1)
		
		** cleanup and save
		compress
		**keep location_name location_id iso3 year endyear dattype svytype svy filepath_full source source_long water sanitation
		keep location_name location_id iso3 year endyear dattype svytype svy filepath_full water sanitation
		rename year startyear
		order water sanitation filepath_full iso3 startyear endyear, first
		save "$input_folder/input_data_sources.dta", replace
		outsheet using "$input_folder/input_data_sources.csv", comma replace
	restore

	// remove unnecessary variables
	/*keep location_id location_name iso3 year endyear filename svy iwater_mean iwater_sem iwater_uncertain ///
		isanitation_mean isanitation_sem isanitation_uncertain icombined_mean icombined_sem ///
		plot outlier* national*/
		
	keep iso3 year endyear filename svy iwater_mean iwater_sem ipiped_mean ipiped_sem ///
		isanitation_mean isanitation_mean isanitation_sem isewer_mean isewer_sem ///
		plot outlier* national
		

	// save
	tempfile estimates
	save `estimates', replace

** prepare urban/rural data
	// WPP: most countries
		** open file
		use "J:/WORK/01_covariates/02_inputs/population/model/WPP_2012rev_population_urbanicity.dta", clear
		drop if year < `firstyear' | year > `lastyear'
		gen percenturban = urban_pop/total_pop	
		drop urban_pop

		** add iso3 to urban/rural data for merging
		preserve
			use "`codes_folder'/IHME_COUNTRY_CODES_Y2013M07D26", clear
			drop if iso3==""
			tempfile codes
			save `codes', replace
		restore
		
		**replace countryname>location_id, countryname_ihme>gbd_country_name, ihme_indic_country>indic_cod, gbd_region>gbd_region_name, gbd_developing>gbd_non_developing
		merge m:1 location_id using `codes', keepusing(location_name gbd_country_name indic_cod iso3 gbd_region_name gbd_non_developing)
		drop if _merge == 1	// all regions rather than countries
		drop if _merge == 2
		drop if indic_cod == 0
		drop _merge indic_cod
		
		
		** calculate proportion of population in rural areas in developing countries
		
		** figure out which ihme indicator countries don't have urban/rural data
		preserve
			use "`codes_folder'/IHME_COUNTRY_CODES_Y2013M07D26", clear
			keep if indic_cod == 1
			tempfile codes_indic
			save `codes_indic', replace
		restore 
		
		merge m:1 iso3 using `codes_indic', keepusing(location_name location_id gbd_country_name indic_cod iso3 gbd_region_name)
		tab location_name gbd_country_name if _merge == 2, missing
		replace _merge = 3 if iso3=="XIU" | iso3=="XIR" 		/*ensuring that India Urban/Rural do not get dropped*/
		drop if _merge==2 & gbd_country_name!="" 				/*dropping all subnationals for the time being UK, SA, Mexico, China*/
		replace _merge = 2 if iso3=="XIU" | iso3=="XIR" 		/*adding it back on to the list of missings*/
		
		** pull these countries into their own dataset and expand to have all years
		preserve
			keep if _merge == 2
			drop _merge year
			gen merge = 1
			joinby merge using `years'
			drop merge
			tempfile missings
			save `missings', replace
		restore
		
		** re-attach
		drop if _merge == 2
		drop _merge
		append using `missings'
		
		** calculate average urbanicity by region, apply to countries where we don't have country-specific data
		bysort gbd_region_name year: egen region_percenturban = mean(percenturban) if iso3!="XIU" | iso3!="XIR"
		replace percenturban = region_percenturban if percenturban == .
		drop region_percenturban
		
		**filling out urbanicity var for India  
		replace percenturban = 0.9999999 if iso3=="XIU" //XIU is all urban
		replace percenturban = 0.0000001 if iso3=="XIR" //XIR is all rural
		
		**changing urbanicity var values to be reasonable enough within logit space
		replace percenturban = 0.9999999  if percenturban >= 1 
			
		** save
		tempfile urbrur_wpp
		save `urbrur_wpp', replace	
	
	// ZAF provinces
		** open file 
		insheet using "$input_folder/ZAF_percent_urban.csv", comma clear
		
		** rearrange
		keep in 6
		destring zaf, replace
		reshape long z, i(v1) j(province) string
		drop v1
		replace province = "z" + province
		replace province = strupper(province)
		rename province iso3
		rename z percenturban
		replace percenturban = percenturban/100
		gen merge = 1
		
		joinby merge using `years'
		drop merge
		drop if iso3 == "ZAF"
		
		gen location_name = iso3
		gen gbd_region_name = "Sub-Saharan Africa, Southern"
		
		** save
		tempfile urbrur_zaf
		save `urbrur_zaf', replace	
		
	// combine them
	use `urbrur_wpp', clear
	append using `urbrur_zaf'
	replace location_name = "Eastern Cape" if location_name=="ZEC"
	replace location_name = "Free State" if location_name=="ZFS"
	replace location_name = "Gauteng" if location_name=="ZGA"
	replace location_name = "KwaZulu-Natal" if location_name=="ZKN"
	replace location_name = "Limpopo" if location_name=="ZLI"
	replace location_name = "Mpumalanga" if location_name=="ZMP"
	replace location_name = "North-West" if location_name=="ZNW"
	replace location_name = "Northern Cape" if location_name=="ZNC"
	replace location_name = "Western Cape" if location_name=="ZWC"
	replace gbd_country_name = "South Africa" if iso3=="ZEC" | iso3=="ZFS" | iso3=="ZGA" | iso3=="ZKN"| iso3=="ZLI" | iso3=="ZMP" | iso3=="ZNW" | iso3=="ZNC" |iso3=="ZWC"
	tempfile urbrur
	save `urbrur', replace 
	
** ** prepare lag distributed income data
	** // open file
	** use "`ldi_folder'/LDI_data_with_SA_provinces.dta", clear
	
	** // standardize variables
	** keep iso3 year LDI_id
	** drop if year < `firstyear' | year > `lastyear'
	
	** // reduce to relevant countries 
	** preserve
		** use "`codes_folder'/countrycodes_official", clear
		** drop if countryname == "Burma" & countryname_ihme == "Burma"
		** keep if countryname == countryname_ihme
		** drop if iso3 == ""
		** tempfile codesiso3
		** save `codesiso3', replace
	** restore
	** merge m:1 iso3 using `codesiso3', keepusing(countryname countryname_ihme ihme_indic_country gbd_region)
	** keep if _merge == 3 | (_merge == 1 & iso3 != "USSR_FRMR")
	** keep if ihme_indic_country == 1 | countryname == ""
	** replace countryname = iso3 if countryname == ""
	
	** drop _merge ihme_indic_country countryname
	** rename countryname_ihme countryname
	
	** // save
	** tempfile ldi
	** save `ldi', replace
	
	
** prepare education and LDI data
	// open file
	// use "$input_folder/covariates_from_codem.dta", clear
	
	use `covariates', clear
	
	// reduce to relevant countries
	merge m:1 iso3 using `codes', keepusing(location_name location_id indic_cod iso3 gbd_region_name gbd_superregion_name) keep(1 3)
	keep if indic_cod == 1 | _merge == 1
	drop _merge indic_cod 
	
	replace location_name = "Guam" if iso3=="GUM"
	replace location_name = "Virgin Islands, U.S." if iso3=="VIR"
	drop if location_id>=491 & location_id<=521 //removing China subnational sites//
	drop if location_id>=4618 & location_id<=4636 | location_id==433 | location_id==434 //removing UK subnational sites//
	
	drop if year < `firstyear' | year > `lastyear'
	keep iso3 year location_id location_name mean_yrseduc *LDI*
	
	// save 
	tempfile education_ldi
	save `education_ldi', replace
	
** merge covariates with prevalence estimates
	// percent urban
	use `estimates', clear
	merge m:1 iso3 year using `urbrur_wpp', nogenerate
	sort location_name location_id year svy
	
	// education and LDI
	merge m:1 iso3 location_name year using `education_ldi'
	tab iso3 if _merge == 1
		drop if _merge == 1	& year == 2014 // THIS IS REDUCING IT TO 1980-2013
	tab iso3 if _merge == 2
	drop _merge
	
	// GBD regions
	merge m:1 iso3 using `codes', keepusing(gbd_region_name gbd_superregion_name gbd_analytical_region_name gbd_analytical_superregion_id indic_cod gbd_non_develop* existence_start) keep(1 3)
	tab iso3 if _merge == 1
	drop _merge
	
** explore specification options

	//rename covariates
	drop pop*
	rename ln_LDI_id ln_LDI_pc
	rename mean_yrseduc education_yrs_pc 
	
	// generate possible specifications
	
	gen iwater_mean_logit = logit(iwater_mean)
	gen ipiped_mean_logit = logit(ipiped_mean/iwater_mean) /*run this as a proportion of improved*/
	gen isanitation_mean_logit = logit(isanitation_mean)
	gen isewer_mean_logit = logit(isewer_mean/isanitation_mean) /*run this as a proportion of improved*/
	**gen icombined_mean_logit = logit(icombined_mean)
	
	gen percenturban_logit = logit(percenturban)
	replace iwater_mean_logit = . if outlier_water == 1
	replace ipiped_mean_logit = . if outlier_piped == 1
	replace isanitation_mean_logit = . if outlier_sanitation == 1
	replace isewer_mean_logit = . if outlier_sewer==1
	**replace icombined_mean_logit = . if outlier_combined == 1
	
	gen iothersan_mean = isanitation_mean - isewer_mean
	gen iothersan_sem = sqrt((isanitation_sem^2) + (isewer_sem^2))
	gen iothersan_mean_logit = logit(iothersan_mean)

	// save dataset for CodMod covariate calculation
	compress
	save "$input_folder/input_data_for_covariate", replace

