// /////////////////////////////////////////////////
// CONFIGURE ENVIRONMENT
// /////////////////////////////////////////////////

	if c(os) == "Unix" {
		global prefix "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global prefix "J:"
	}

// /////////////////////////////////////////////////
// CONFIGURATION COMPLETE 
// /////////////////////////////////////////////////
clear all
set more off

//Set appropriate locals
	local CHN_national				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output/gpr_results_piped_covar_with_orig_data.dta"
	local CHN_subnational 			"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/CHN"
	local CHN_statistical_yearbook 	"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/CHN/CHN_water_statistical_yearbook.csv"
	local CHN_urbanicity 			"J:/WORK/01_covariates/02_inputs/malnutrition/subnational/CHN/data/CHN_urbanicity.dta"
	local country_codes 			"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
	local graph_folder 				"J:/WORK/01_covariates/02_inputs/water_sanitation/output_graphs/subnational/chn/model"
	local data_folder 				"J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/chn"

//Get china province names to iso3/locationid
	clear
	#delim ;
	odbc load, exec("
		SELECT locations.location_id, locations.name, loc_parent.local_id as iso3 
		FROM locations
			JOIN locations_indicators USING (location_id)
			JOIN locations_hierarchy ON location_id=descendant
			JOIN locations AS loc_parent ON ancestor=loc_parent.location_id
		WHERE locations_hierarchy.version_id = 2 AND locations_indicators.version_id=2 AND
			indic_cod = 1 AND locations_hierarchy.type='gbd' AND (distance=1 OR
			locations_hierarchy.root=1) AND loc_parent.local_id = 'CHN'
	") dsn(epi) clear;
	#delim cr
	replace name = lower(name)
	tempfile province_names
	save `province_names'
	
//Prep countrycodes
	use "`country_codes'"
	drop if iso3==""
	tempfile codes
	save `codes', replace
	
// Load provincial  estimates
/*	***1995*** 
	**NOTE: exclude 1995 because this only includes the urban population
	import excel using "J:/WORK/05_risk/01_database/02_data/air_hap/01_exp/02_nonlit/02_inputs/01_survey/CHINA_1995_8-4.xls", clear cellrange(A5:L128) firstrow
	
	keep A B K L 
	rename (A B K L) (name total_households usingtapwater notapwater)
	drop if name == "" | regexm(name, "Monolayer") | regexm(name, "Multilayer") | name=="Total"

	replace name = lower(name) 
	merge 1:1 name using `province_names', assert(2 3) keep(3) nogen
	drop name
	gen year = 1995
	
	**generate mean & sample_size to generate an estimate of variance
	gen ipiped_mean = usingtapwater/total_households
	gen sample_size = total_households
	
	tempfile piped_prov
	save `piped_prov', replace */
	
	***2000**
	import excel using "J:/WORK/05_risk/01_database/02_data/air_hap/01_exp/02_nonlit/02_inputs/01_survey/CHINA_2000_8-3.xlsx", clear cellrange(A4:U36) firstrow

	rename *, lower
	rename (a b) (name total_households)
	drop if name == ""
	keep name total_households *tapwater
	
	**generate mean & sample_size to generate an estimate of variance
	gen ipiped_mean = usingtapwater/total_households
	gen sample_size = total_households
	
	** Clean up name variable and merge on location ids
	replace name = lower(name)
	drop if name == "total"
	replace name = substr(name, 1, length(name) - 1)
	replace name = "tibet" if name == "xizang"
	merge 1:1 name using `province_names', assert(2 3) keep(3) nogen
	drop name
	gen year = 2000
	
	**append using `piped_prov'
	tempfile piped_prov
	save `piped_prov', replace
	
	
	**2005**
	import excel using "J:/WORK/05_risk/01_database/02_data/air_hap/01_exp/02_nonlit/02_inputs/01_survey/CHINA_2005_11-5.xlsx", clear cellrange(A5:U45) firstrow
	
	rename *, lower
	rename (a b)(name total_households)
	drop if name == ""
	keep name total_households *tapwater
	
	**generate mean & sample_size to generate an estimate of variance
	gen ipiped_mean = usingtapwater/total_households
	gen sample_size = total_households
	
	** Clean up name variable and merge on location ids
	replace name = lower(name)
	replace name = "heilongjiang" if name=="heilongjia"
	replace name = "inner mongolia" if name=="inner mong"
	drop if regexm(name, "national")
	merge 1:1 name using `province_names', assert(2 3) keep(3) nogen
	drop name
	
	gen year = 2005
	
	append using `piped_prov'
	save `piped_prov', replace
	
	**2010**
	import excel using "J:/WORK/05_risk/01_database/02_data/air_hap/01_exp/02_nonlit/02_inputs/01_survey/9-3 Main fuel source and other housing amenities China 2010.xls", clear cellrange(A4:V39) firstrow
	
	rename *, lower
	rename (a c)(name total_households)
	drop if name == ""
	keep name total_households *tapwater
	
	** Clean up name variable and merge on location ids
	replace name = lower(name)
	drop if (name=="region" | name=="total")
	replace name = substr(name, 1, length(name) - 1)
	replace name = "tibet" if name == "xizang"
	merge 1:1 name using `province_names', assert(2 3) keep(3) nogen
	drop name
	
	destring(usingtapwater notapwater total_households), replace 
	
	**generate mean & sample_size to generate an estimate of variance
	gen ipiped_mean = usingtapwater/total_households
	gen sample_size = total_households
	gen year = 2010
	
	append using `piped_prov'
	rename iso3 gbd_country_iso3
	merge m:1 location_id using `codes', keep(1 3) keepusing(iso3) nogen
	
	save `piped_prov', replace
	
***Covariates***
// load urbanicity data
	use "`CHN_urbanicity'", clear
	keep iso3 year prop_urban
	duplicates drop iso3 year prop_urban, force
	
	**fill in missing urbanicity numbers
	expand 2 if iso3=="XCB" & year==1989, gen(id)
	replace year = 1990 if id == 1 
	drop id 
	
	expand 2 if iso3=="XCB" & year==1994, gen(id)
	replace year = 1995 if id == 1 
	drop id 
	
	tempfile urbanicity
	save `urbanicity', replace
	
//load ldi pc
	use "J:/WORK/01_covariates/02_inputs/LDI_pc/model/subnational/CHN_ldi_pc.dta", clear
	keep iso3 year LDI_id
	drop if year<1980 | year>2013
	gen ln_LDI = ln(LDI_id)	
	tempfile ldi
	save `ldi', replace

/*weighting the rural coverage prop to estimate national
	use `piped_prov', clear
	merge m:1 iso3 year using `urbanicity', keep(1 3) nogen
	
	replace water_mean_prov = (prop_urban*water_mean_prov) + ((1-prop_urban)*1) if regexm(source_name, "China Health") */
	
// Load national Water and Sanitation prevalence estimates 
	use "`CHN_national'", clear
	keep if iso3 == "CHN"
	keep iso3 year gpr_draw*
	duplicates drop
	tempfile national
	save `national', replace
	
	forvalues d = 1/1000 {
	**local d = 1 
	preserve
	keep iso3 year gpr_draw`d'
	rename gpr_draw`d' piped_mean_natl`d'
	duplicates drop

	tempfile piped_chn
	save `piped_chn', replace
	
	//merge with national and subnational estimates for coverage	
	use `ldi', clear
	merge m:1 year using `piped_chn', keep(1 3) nogen
	merge m:1 iso3 year using `urbanicity', keep(1 3) nogen
	merge m:m iso3 year using `piped_prov', keep(1 3) nogen
	
	gen logit_piped_mean_natl`d' = logit(piped_mean_natl`d')
	gen logit_piped_mean_prov = logit(ipiped_mean)
	
	//merge with location names
	merge m:1 iso3 using `codes', keepusing(location_name location_id)
	drop if _merge==2
	drop _merge
	order location_name iso3 year, first
	
	//Run mixed effect regression with: fixed effect - national coverage, ln_LDI, urbanicity ; random slope: ln_LDI, urbanicity; intercept: subnational iso3 - 
	//[BEST MODEL THUS FAR]

	xtmixed logit_piped_mean_prov logit_piped_mean_natl`d' ln_LDI prop_urban || iso3: ln_LDI prop_urban
	**, iter(1000)
	predict logit_pred`d', fit
		
	gen pred`d' = invlogit(logit_pred`d')
	
	//save individual draws
	if `d'==1 {
	keep iso3 year pred`d'
	duplicates drop 
	tempfile draws
	save `draws', replace
		} 
	else
		{
	keep iso3 year pred`d'
	duplicates drop 
	merge 1:1 iso3 year using `draws', keep(1 3) nogen
	save `draws', replace
	}
	
	restore
}

//save draws for subnational estimates
use `draws', clear
merge m:1 iso3 using `codes', keepusing(location_name location_id) keep(1 3) nogen
merge m:1 year using `national', keepusing(gpr_draw*) keep(1 3) nogen
merge m:m iso3 year using `piped_prov', keep(1 3) nogen

egen piped_prov_pred_mean = rowmean(pred*)
egen piped_prov_pred_upper = rowpctile(pred*), p(97.5)
egen piped_prov_pred_lower = rowpctile(pred*), p(2.5)

egen natl_mean = rowmean(gpr_draw*)

sort iso3 year

**save estimates
save "`data_folder'/piped_chn.dta", replace

drop pred*
//GRAPH RESULTS with draws
	
	// Graph regression 
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graph_folder'/compare_piped_CHN_draws.pdf"

			levelsof location_name, local(locs)
			preserve
			foreach loc of local locs {
				keep if location_name == "`loc'"
					twoway line piped_prov_pred_mean year, lcolor(teal) lpattern(solid) || ///
					line piped_prov_pred_lower year, lcolor(teal) lpattern(dash) || ///
					line piped_prov_pred_upper year, lcolor(teal) lpattern(dash) || ///
					line natl_mean year, lcolor(black) lpattern(solid) || ///
					scatter ipiped_mean year, mcolor(black) ///
					ylabel(0(0.2)1) xlabel(1980(5)2010) title("Piped water") subtitle("`loc'") xtitle("Year", size(small)) ytitle("Proportion with coverage", size(small))legend(size(small)) 	
				
				pdfappend
				
				restore, preserve
			}
			
		pdffinish
		
		restore

// END OF FILE 