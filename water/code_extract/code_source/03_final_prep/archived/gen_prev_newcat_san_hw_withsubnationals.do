//// File Name: gen_prev_newcat_san_hw_withsubnationals.do
// File Purpose: combine sanitation draws with handwashing
// Author: Astha KC 
// Date: 3/17/2014

// Additional Comments: 

//Housekeeping
clear all 
set more off

//Set relevant locals
local source_results	"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output"
local prop_results		"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/02_Analyses/data"
local graphloc 			"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/graphs"
local country_codes 	"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
local dataloc			"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/final prep"

local final_output		"J:/WORK/01_covariates/02_inputs/water_sanitation/output_data/risk_factors"

//Prep dataset

use "`source_results'/gpr_results_s_covar.dta", clear
keep iso3 year gpr_draw*
forvalues n = 1/1000 {
	rename gpr_draw`n' isanitation_`n'
	gen iunimp_`n' = 1 - isanitation_`n'
		}
tempfile sanitation
save `sanitation', replace

use "`source_results'/gpr_results_sewer_covar.dta", clear
keep iso3 year gpr_draw*
forvalues n = 1/1000 {
	rename gpr_draw`n' isewer_`n'
		}

merge 1:1 iso3 year using `sanitation', keep(1 3) nogen
forvalues n = 1/1000 {
	gen iimproved_`n' = isanitation_`n' - isewer_`n'
	
	**rescale draws from all three categories to make sure they add up to 1
	replace iimproved_`n' = (iimproved_`n'/(iimproved_`n'+isewer_`n'+iunimp_`n'))
	replace isewer_`n' = (isewer_`n'/(iimproved_`n'+isewer_`n'+iunimp_`n'))
	replace iunimp_`n' = (iunimp_`n'/(iimproved_`n'+isewer_`n'+iunimp_`n'))
	
	gen total_`n' = (iimproved_`n'+isewer_`n'+iunimp_`n')
		}
drop total* isanitation*

local cats "improved sewer unimp" 
foreach cat of local cats {
	forvalues n = 1/1000 {
	replace i`cat'_`n' = 0.0001 if i`cat'_`n'<0
		}
}

tempfile san_cats
save `san_cats', replace

/* merge country iso3s /region variables*/
preserve
use `country_codes', clear
drop if iso3==""
tempfile codes
save `codes', replace
restore
merge m:1 iso3 using `codes', keepusing(location_name gbd_analytical_region_name gbd_analytical_superregion_id) keep(1 3) nogen

/*Bin all high income countries into TMRED*/
forvalues n = 1/1000 {
	replace iunimp_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace iimproved_`n' = 0 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	replace isewer_`n' = 1 if gbd_analytical_superregion_id==64 & gbd_analytical_region_name!="Southern Latin America"
	}

**save data**
save "`final_output'/newcat_final_prev_san_03202014.dta", replace

******************************************************************************************************************************

**Calculate PAF**
gen paf_num = ((isewer_mean*1) + (iimproved_mean*2.71) + (iunimproved_mean*3.23)) - (1*1)
gen paf_denom =  ((isewer_mean*1) + (iimproved_mean*2.71) + (iunimproved_mean*3.23)) 
gen paf = paf_num/paf_denom
tempfile paf
save `paf', replace

**Collapse to gen global/regional estimates**
***Population data***
use "C:/Users/asthak/Documents/Covariates/Water and Sanitation/smoothing/spacetime input/pop_data.dta", clear
tempfile all_pop
sort iso3 
save `all_pop', replace

use `paf', clear
merge m:1 iso3 year using `all_pop'

collapse (mean) paf, by(gbd_analytical_region_name year)
collapse (mean) paf, by(year)

br if year==1990 | year == 1995 | year == 2000 | year==2005 | year == 2010 | year == 2013

//Graph to see if this works
local iso3s ECU PER SLV KEN MAR BGD
	foreach iso3 of local iso3s {
	twoway (line step2_prev year) || (line prev_piped_t year) || (line prev_piped_t2 year) || (line prev_piped_untr year) if iso3=="BGD", title("BGD") ///
	xlabel(1980(5)2013)
	graph export "`graphloc'/`iso3'_03182014.pdf", replace
}