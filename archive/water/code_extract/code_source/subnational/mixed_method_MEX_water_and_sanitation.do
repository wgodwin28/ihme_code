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
	
	adopath + "$prefix/WORK/01_covariates/common/lib"

// /////////////////////////////////////////////////
// CONFIGURATION COMPLETE 
// /////////////////////////////////////////////////

clear all
set more off

// Load NATIONAL Water and Sanitation coverage estimates 
	use "C:/Users/asthak/Documents/Covariates/Water and Sanitation/model/gpr_output/gpr_results_s_covar_with_orig_data.dta", clear
	keep if iso3 == "MEX"
	keep iso3 year gpr_mean
	rename gpr_mean sanitation_mean_natl
	duplicates drop
	tempfile sanitation_mex
	save `sanitation_mex', replace

	use "C:/Users/asthak/Documents/Covariates/Water and Sanitation/model/gpr_output/gpr_results_w_covar_with_orig_data.dta", clear
	keep if iso3 == "MEX"
	keep iso3 year gpr_mean
	rename gpr_mean water_mean_natl
	duplicates drop
	tempfile water_mex
	save `water_mex', replace
	
// Load PROVINCIAL sanitation and water coverage estimates
	insheet using "C:/Users/asthak/Documents/Covariates/MEX/Water and Sanitation/improved_sanitation.csv", clear
	keep state year indic_mean 
	rename (state year indic_mean) (location_name year sanitation_mean_prov)
	replace sanitation_mean_prov=sanitation_mean_prov/100
	drop if location_name=="México"
	sort location_name year 
	tempfile sanitation_prov
	save `sanitation_prov', replace
	
	insheet using "C:/Users/asthak/Documents/Covariates/MEX/Water and Sanitation/prop_sust_access_water.csv", clear
	keep state year indic_mean 
	rename (state year indic_mean) (location_name year water_mean_prov)
	replace water_mean_prov=water_mean_prov/100
	drop if location_name=="México"
	sort location_name year 
	tempfile water_prov
	save `water_prov', replace
	
//Load population data 
	use "J:/WORK/02_mortality/04_outputs/02_results/envelope_gbd2013_v6.dta", clear
	keep if regexm(iso3, "MEX") & sex==3 & age==99
	keep location_name year age mean_pop
	drop if year<1980
	/*rename subnational_name location_name
	replace location_name="Mexico" if location_name==""
	collapse (rawsum) mean_pop, by(location_name year)
	drop if year<1980*/
	
		//merge subnational iso3s
		preserve
		use "J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA", clear
		drop if iso3==""
		tempfile codes
		save `codes', replace
		restore
		merge m:1 location_name using `codes', keepusing(iso3)
		drop if _merge==2
		drop _merge location_name
		
	//estimate pop_weight for each province year
	reshape wide mean_pop, i(year) j(iso3, string)
	
	local iso3s XAM XBM XEM XFM XHM XIM XJM XMA XMB XMC XMD XME XMF XMH XMI XMJ XMK XML XMM XMN XMO XMP XMQ XMR XMS XMT XMU XMV XMW XMX XMY XMZ MEX
	foreach iso3 of local iso3s {
		replace mean_pop`iso3'=mean_pop`iso3'/mean_popMEX
		}
		
	reshape long mean_pop, i(year) j(iso3,string)
	merge m:1 iso3 using `codes', keepusing(location_name location_id) keep(1 3) nogen
	rename mean_pop pop_weight
	sort iso3 year
	tempfile popweight_prov
	save `popweight_prov', replace
	
	
//merge with national and subnational estimates for coverage
	insheet using "C:\Users\asthak\Documents\Covariates\MEX\Water and Sanitation\prov_template.csv", clear
	merge m:1 year using `sanitation_mex', keepusing(sanitation_mean_natl) keep(1 3) nogen
	merge m:1 year using `water_mex', keepusing(water_mean_natl) keep(1 3) nogen
	merge 1:m year location_name using `sanitation_prov', keepusing(sanitation_mean_prov) keep(1 3) nogen
	merge 1:m year location_name using `water_prov', keepusing(water_mean_prov) keep(1 3) nogen
	replace location_name = "Coahuila" if location_name=="Coahuila de Zaragoza"
	merge m:1 location_name year using `popweight_prov', keepusing(pop_weight iso3 location_id) keep(1 3) nogen
	
	//transform data into logit space
	gen logit_sanitation_mean_natl = logit(sanitation_mean_natl)
	gen logit_sanitation_mean_prov = logit(sanitation_mean_prov)
	gen logit_water_mean_natl = logit(water_mean_natl)
	gen logit_water_mean_prov = logit(water_mean_prov)
	
	order location_name iso3 year pop_weight, first
	sort year iso3
		
// /////////////////////////////////////////////////
// Regressions
// /////////////////////////////////////////////////

	//Run mixed effects regressions with mean national coverage
		
		//sanitation
		xtmixed logit_sanitation_mean_prov logit_sanitation_mean_natl || iso3: /*USE THIS*/
		predict logit_sanitation_mean_prov_pred, fit
		
		gen sanitation_mean_prov_pred = invlogit(logit_sanitation_mean_prov_pred)
		label variable sanitation_mean_prov_pred "Provincial coverage"
		label variable sanitation_mean_natl "National coverage"
		label variable sanitation_mean_prov "Reported provincial estimates"

		
		// Graph regression of coverage - SANITATION
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/subnational/mex/model/compare_MEX_sanitation_REiso3_4252014.pdf"

			levelsof location_name, local(locs)
			preserve
			foreach loc of local locs {
				keep if location_name == "`loc'"
				twoway scatter sanitation_mean_prov year, msymbol(Oh) || line sanitation_mean_natl year || line sanitation_mean_prov_pred year, title("`loc'") xlabel(1980(10)2013)
				
				pdfappend
				
				restore, preserve
			}
			
		pdffinish
		restore
		
		//water
		xtmixed logit_water_mean_prov logit_water_mean_natl || iso3: logit_water_mean_natl
		predict logit_water_mean_prov_pred, fit
		
		gen water_mean_prov_pred = invlogit(logit_water_mean_prov_pred)
		label variable water_mean_prov_pred "Provincial coverage"
		label variable water_mean_natl "National coverage"
		label variable water_mean_prov "Reported provincial estimates"
		
		// Graph regression of coverage - WATER
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/subnational/mex/model/compare_MEX_water_REiso3_4252014.pdf"

			levelsof location_name, local(locs)
			preserve
			foreach loc of local locs {
				keep if location_name == "`loc'"
				twoway scatter water_mean_prov year, msymbol(Oh) || line water_mean_natl year || line water_mean_prov_pred year, title("`loc'") xlabel(1980(10)2013)
				
				pdfappend
				
				restore, preserve
			}
			
		pdffinish
		restore
		
	//SAVE FILES for covariates database
	tostring(location_id), replace
	replace iso3 = "MEX" + "_" + location_id
	destring(location_id), replace
	
	preserve
	rename water_mean_prov_pred mean_value
	keep iso3 location_id year mean_value
	order iso3 location_id year, first
	save "J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/MEX/water_MEX_covar.dta", replace
	restore
	rename sanitation_mean_prov_pred mean_value
	keep iso3 location_id year mean_value
	order iso3 location_id year, first
	save "J:/WORK/01_covariates/02_inputs/water_sanitation/data/subnational/MEX/sanitation_MEX_covar.dta", replace
		
// END OF FILE 