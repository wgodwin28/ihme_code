
//Housekeeping
clear all 
set more off
set maxvar 30000

//Set relevant locals
local source_results	"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output"
local prop_results		"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/02_Analyses/data/gpr/gpr_output"
local graphloc 			"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/graphs"
local country_codes 	"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
local dataloc			"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/03_Final_Prep/output"

local date "06062014"

**prep country codes file
use "J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA", clear
drop if iso3==""
tempfile codes
save `codes', replace 

***Population data***
use "J:/WORK/02_mortality/04_outputs/02_results/envelope.dta", clear
keep if age==99 & sex_name=="Both" & year>=1980
keep iso3 location_id location_name year age sex mean_pop 
tempfile all_pop
sort iso3 
save `all_pop', replace

//open dataset
use "`dataloc'/final_prev_`date'.dta", clear
	
	/*generate mean*/
	egen prev_piped_untr_mean = rowmean(prev_piped_untr_*)
	egen prev_piped_t2_mean = rowmean(prev_piped_t2_*)  
	egen prev_imp_t_mean = rowmean(prev_imp_t_*)  
	egen prev_imp_t2_mean = rowmean(prev_imp_t2_*)   
	egen prev_imp_untr_mean = rowmean(prev_imp_untr_*)  
	egen prev_unimp_t_mean = rowmean(prev_unimp_t_*)
	egen prev_unimp_t2_mean = rowmean(prev_unimp_t2_*) 
	egen prev_unimp_untr_mean = rowmean(prev_unimp_untr_*)  
	egen prev_piped_t_mean = rowmean(prev_piped_t_*)
	
	keep iso3 year location_name *mean
	rename (prev_piped_t_mean prev_piped_t2_mean prev_piped_untr_mean prev_imp_t_mean prev_imp_t2_mean prev_imp_untr_mean ///
		 prev_unimp_t_mean prev_unimp_t2_mean prev_unimp_untr_mean) (exp_cat1 exp_cat2 exp_cat3 exp_cat4 exp_cat5 exp_cat6 exp_cat7 exp_cat8 exp_cat9) 
	keep if year==2013
	
	**compile pop and region variables
	merge 1:m iso3 year using `all_pop', keep(1 3) nogen
	merge m:1 iso3 using `codes', keep(1 3) keepusing(gbd_analytical_region_name) nogen  
	
	replace mean_pop = int(mean_pop)
	collapse (mean) exp_cat3 exp_cat2 exp_cat4 exp_cat5 exp_cat6 exp_cat7 exp_cat8 exp_cat9 exp_cat1 [fw=mean_pop], by(gbd_analytical_region_name year)
	
	gen total = exp_cat3 + exp_cat2 + exp_cat4 + exp_cat5 + exp_cat6 + exp_cat7 + exp_cat8 + exp_cat9 + exp_cat1
	
	
	gen order = . 
	replace order = 1 if regexm(gbd_analytical_region_name, "Asia") 
	replace order = 2 if gbd_analytical_region_name=="Australasia" | gbd_analytical_region_name=="Caribbean" | gbd_analytical_region_name=="Oceania"
	replace order = 3 if regexm(gbd_analytical_region_name, "Europe") 
	replace order = 4 if regexm(gbd_analytical_region_name, "America")
	replace order = 5 if regexm(gbd_analytical_region_name, "Africa")
	sort order gbd_analytical_region_name
	
	**open dataset prepared for stacked bar graph 
	
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graphloc'/water_exp_stackedbar_region_06062014.pdf"
		sort iso3 year
		encode gbd_analytical_region_name, gen(region_code)
		levelsof region_code, l(regs) c
		foreach r of local regs {
		levelsof iso3 if region_code == `r', l(isos) 
		foreach i of local isos {
			preserve
			keep if iso3 == "`i'"
			local nm = location_name
			graph bar exp_cat1 exp_cat2 exp_cat3 exp_cat4 exp_cat5 exp_cat6 exp_cat7 exp_cat8, over(gbd_analytical_region_name) stack ///
			title("`nm'") legend(label(1 "Piped & filtered") label(2 "Piped & chlorinated") label(3 "Piped & untreated") label(4 "Improved & filtered") label(5 "Improved & chlorinated") ///
				label(6 "Improved & untreated") label(7 "Unimproved & filtered") label(8 "Unimproved & chlorinated") ///
				size(vsmall) col(3)) ylabel(#5, labsize(small)) ylabel(0(.2)1)
			pdfappend
			restore
		}
	}
	pdffinish, view
	
	graph export "J:\WORK\01_covariates\02_inputs\water_sanitation\documentation\materials for IAC\water_stackedbar.pdf", as(pdf) replace

	
