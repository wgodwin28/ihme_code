//// File Name: gen_prev_newcat.do
// File Purpose: combine output from proportion models to split each source type group by HWT use 
// Author: Astha KC 
// Date: 3/17/2014

// Additional Comments: 

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

local final_output		"J:/WORK/01_covariates/02_inputs/water_sanitation/output_data/risk_factors"

local date "06062014"

//Prep GPR draws 

	//improved water
	use "`source_results'/gpr_results_w_covar.dta", clear
	keep iso3 year gpr_draw*
	forvalues n = 1/1000 {
		rename gpr_draw`n' iwater_mean`n'
		gen iunimp_mean`n' = 1 - iwater_mean`n'
		}
	
	tempfile water
	save `water', replace
	
	//piped water
	use "`source_results'/gpr_results_piped_covar.dta", clear
	keep iso3 year gpr_draw*
	merge 1:1 iso3 year using `water', keep(1 3) nogen
	forvalues n = 1/1000 {
		rename gpr_draw`n' ipiped_mean`n'
		gen iimp_mean`n' = iwater_mean`n' - ipiped_mean`n'
		}
	tempfile water_cats
	save `water_cats', replace

//Prep draws from proportion models 
local models "imp_treat imp_treat2 piped_treat piped_treat2 unimp_treat unimp_treat2"
foreach model of local models {
	use "`prop_results'/gpr_results_`model'.dta"
	sort iso3 year
	keep iso3 year gpr_draw*
	
		forvalues n = 1/1000 {
			rename gpr_draw`n' prop_`model'`n'
			}
	
	tempfile `model'
	save ``model'', replace
} 

/**using new prop models from spacetime
local sources improved unimproved piped
foreach source of local sources 	{
	local models treat treat2 
	foreach model of local models {

	use "`prop_results'/`source'/`model'_B_results.dta"
	sort iso3 year
	keep iso3 year step2_prev
	duplicates drop
	rename step2_prev prop_`source'_`model'

	tempfile `source'`model'
	save ``source'`model'', replace
	} 
		}*/
	
//Merge relevant proportions with coverage for each level
/*use "`source_results'/piped_covar_B_results.dta"
merge m:1 iso3 year using `pipedtreat', keepusing(prop_piped_treat) nogen keep(1 3)
merge m:1 iso3 year using `pipedtreat2', keepusing(prop_piped_treat2) nogen keep(1 3)

gen prev_piped_t = prop_piped_treat * step2_prev
gen prev_piped_t2 = prop_piped_treat2 * step2_prev
gen prev_piped_untr = step2_prev - (prev_piped_t + prev_piped_t2)

outsheet iso3 year location_name step2_prev prev_piped_t prev_piped_t2 prev_piped_untr using "C:\Users\asthak\Desktop\Presentations\piped.xls", replace*/

//merge all draws
use `water_cats', clear
local sources imp unimp piped
foreach source of local sources {
merge m:1 iso3 year using ``source'_treat' , keepusing(prop_`source'_treat*) nogen keep(1 3)
merge m:1 iso3 year using ``source'_treat2', keepusing(prop_`source'_treat2*) nogen keep(1 3)
}

local sources imp unimp piped
foreach source of local sources {
	
	forvalues n = 1/1000 {
	
	gen prev_`source'_t_`n' = prop_`source'_treat`n' * i`source'_mean`n'
	gen prev_`source'_t2_`n' = prop_`source'_treat2`n'* i`source'_mean`n'
	gen prev_`source'_untr_`n' = i`source'_mean`n' - (prev_`source'_t_`n' + prev_`source'_t2_`n')
	}
		}

keep iso3 year prev_*
			
//merge location variables
	preserve
	use `country_codes', clear
	drop if iso3==""
	tempfile codes
	save `codes', replace
	restore
	
merge m:1 iso3 using `codes', keepusing(location_name gbd_analytical_region_name gbd_analytical_superregion_id gbd_analytical_superregion_name) keep(1 3) nogen


/*Bin all high income countries into TMRED*/
forvalues n = 1/1000 {

	replace prev_piped_untr_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_piped_t2_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_imp_t_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_imp_t2_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_imp_untr_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_unimp_t_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_unimp_t2_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_unimp_untr_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace prev_piped_t_`n' = 1 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America" 
	
	}
	
**save data**
save "`final_output'/newcat_final_prev_water_`date'.dta", replace

*********************************************
*****Prepare draws for STACKED GRAPHS**********
*********************************************
*****Using smoothing results********************
*********************************************
	use "`graphloc'/newcat_final_prev_`date'.dta", clear
	
	keep iso3 location_name year iso3 prev_piped_t prev_piped_t2 prev_piped_untr prev_improved_t prev_improved_t2 prev_improved_untr ///
		prev_unimproved_t prev_unimproved_t2 prev_unimproved_untr

	rename (prev_piped_t prev_piped_t2 prev_piped_untr prev_improved_t prev_improved_t2 prev_improved_untr ///
		prev_unimproved_t prev_unimproved_t2 prev_unimproved_untr) (exp_cat9 exp_cat8 exp_cat7 exp_cat6 exp_cat5 exp_cat4 exp_cat3 exp_cat2 exp_cat1) 

*******************************
*****using GPR results***********
*****************************
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
	
	**save data for stacked bar graph**
	preserve
	keep if year == 1990 | year == 2005 | year == 2010 | year == 2013
	saveold "`graphloc'/stacked_bargraph_cats_`date'.dta", replace
	restore
	
	
	order iso3 location_name year, first
	reshape long exp_cat, i(iso3 location_name year) j(cat) 
	rename exp_cat exp_prev
	gen exp_cat = cat
	drop cat
	
	
	**Change reverse order**
	tostring(exp_cat), replace
	replace exp_cat = "Piped & filtered"  if exp_cat=="9"
	replace exp_cat = "Piped & chlorinated" if exp_cat=="8"
	replace exp_cat = "Piped & untreated" if exp_cat=="7"
	replace exp_cat = "Improved & filtered" if exp_cat=="6"
	replace exp_cat = "Improved & chlorinated" if exp_cat=="5"
	replace exp_cat = "Improved & untreated" if exp_cat=="4"
	replace exp_cat = "Unimproved & filtered" if exp_cat=="3"
	replace exp_cat = "Unimproved & chlorinated" if exp_cat=="2"
	replace exp_cat = "Unimproved & untreated" if exp_cat=="1"
	
	drop if exp_prev==.
	
	saveold "`graphloc'/stacked_graph_cats_`date'.dta", replace
	
	**save data for stacked bar graph**
	keep if year == 1990 | year == 2005 | year == 2010 | year == 2013
	saveold "`graphloc'/stacked_bargraph_cats_`date'.dta", replace


**************************
*******Calculate PAF*******
**************************
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

gen paf_num = ((prev_piped_t_mean*1)+(prev_piped_t2_mean*1.54) +(prev_piped_untr_mean*1.89) + (prev_imp_t_mean*1.16) + ///
	(prev_imp_t2_mean*1.79) + (prev_imp_untr_mean*2.18) + (prev_unimp_t_mean*1.30) + (prev_unimp_t2_mean*2.01) + ///
	(prev_unimp_untr_mean*2.45)) - (1*1)
	
gen paf_denom = ((prev_piped_t_mean*1)+(prev_piped_t2_mean*1.54) +(prev_piped_untr_mean*1.89) + (prev_imp_t_mean*1.16) + ///
	(prev_imp_t2_mean*1.79) + (prev_imp_untr_mean*2.18) + (prev_unimp_t_mean*1.30) + (prev_unimp_t2_mean*2.01) + ///
	(prev_unimp_untr_mean*2.45))

gen paf = paf_num/paf_denom

tempfile paf
save `paf', replace

**Collapse to gen global/regional estimates**

**prep country codes file
use "J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA", clear
drop if iso3==""
tempfile codes
save `codes', replace 

**prep region super region file**
use `codes', clear
keep gbd_analytical_region_name gbd_analytical_superregion_name
duplicates drop
tempfile regions
save `regions', replace 

***Population data***
use "J:/WORK/02_mortality/04_outputs/02_results/envelope.dta", clear
keep if age==99 & sex_name=="Both" & year>=1980
keep iso3 location_id location_name year age sex mean_pop 
tempfile all_pop
sort iso3 
save `all_pop', replace

use `paf', clear
merge 1:m iso3 year using `all_pop', keep(1 3) nogen
merge m:1 iso3 using `codes', keep(1 3) keepusing(gbd_analytical_region_name) nogen 

replace mean_pop = int(mean_pop)
collapse (mean) paf [fw=mean_pop], by(gbd_analytical_region_name year)

collapse (mean) paf [fw=mean_pop], by(year)

merge m:1 gbd_analytical_region_name using `regions', keepusing(gbd_analytical_superregion_name)

graph hbar paf  if year == 2010 , over(gbd_analytical_region_name) 

gen order = . 
replace order = 1 if regexm(gbd_analytical_region_name, "Asia") 
replace order = 2 if gbd_analytical_region_name=="Australasia" | gbd_analytical_region_name=="Caribbean" | gbd_analytical_region_name=="Oceania"
replace order = 3 if regexm(gbd_analytical_region_name, "Europe") 
replace order = 4 if regexm(gbd_analytical_region_name, "America")
replace order = 5 if regexm(gbd_analytical_region_name, "Africa")
sort order gbd_analytical_region_name
 
graph hbar paf  if year == 2013 , over(gbd_analytical_region_name) 
graph export "J:\WORK\01_covariates\02_inputs\water_sanitation\documentation\materials for IAC\paf_graph_2013.pdf", as(pdf) replace


//Graph to see if this works
local iso3s ECU PER SLV KEN MAR BGD
	foreach iso3 of local iso3s {
	twoway (line step2_prev year) || (line prev_piped_t year) || (line prev_piped_t2 year) || (line prev_piped_untr year) if iso3=="BGD", title("BGD") ///
	xlabel(1980(5)2013)
	graph export "`graphloc'/`iso3'_03182014.pdf", replace
}