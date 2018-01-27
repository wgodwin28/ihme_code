// prep stata
clear all
set more off
set maxvar 30000
if c(os) == "Unix" {
	global prefix "/home/j"
	set odbcmgr unixodbc
	set mem 10g
}
else if c(os) == "Windows" {
	global prefix "J:"
	set mem 5g
}

// load subroutines
run "$prefix/WORK/04_epi/01_database/01_code/02_central/01_code/prod/adofiles/svy_extract.ado"
run "$prefix/WORK/04_epi/01_database/01_code/02_central/01_code/prod/adofiles/svy_encode.ado"
run "$prefix/WORK/04_epi/01_database/01_code/02_central/01_code/prod/adofiles/svy_subpop.ado"

// initialize storage files
tempfile data
save `data', replace emptyok
tempfile tabulated_m
save `tabulated_m', replace emptyok
tempfile tabulated_m_under_5
save `tabulated_m_under_5', replace emptyok
tempfile tabulated
save `tabulated', replace emptyok
tempfile tabulated_under_5
save `tabulated_under_5', replace emptyok

use "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\data\prevalence\MICS\varlist_mics.dta", clear

// drop surveys with no observations
drop if filepath_full=="J:/DATA/UNICEF_MICS/CUB/2014/CUB_MICS5_2014_HH_Y2015M09D28.DTA"
drop if regexm(filepath_full, "ROMA") | module != "HH"

// loop through surveys
forvalues i = 1/`=_N' {
local i 14
local i 15
local i 16
local i 32
local i 31
// assigns filepath and variable list
	local filepath = filepath_full[`i']
	local psu = psu[`i']
	local pweight = weight[`i']
	local urbanicity = urban[`i']
	local station = w_hwss[`i']
	local barsoap = w_barsoap[`i']
	local liqsoap = w_liqsoap[`i']
	local detergent = w_detergent[`i']
	local water = w_water[`i']
	local under_5 = "HH14"
	
	foreach vari in psu pweight urbanicity station barsoap liqsoap detergent water under_5 {
		local `vari' = lower("``vari''")
	}
	

// extract and append data
	preserve
	
	// run extraction program	
		svy_extract, filepaths(`filepath') primary_vars(`psu' `pweight' `urbanicity' `station' `barsoap' `liqsoap' `detergent' `water' `under_5')
		
	// rename extracted variables
		foreach vari in psu pweight urbanicity station barsoap liqsoap detergent water under_5 {
			cap rename ``vari'' `vari'
			cap rename ``vari''__s `vari'__s
		}
		
		append using `data', force
		save `data', replace
	restore
	
	//}
	
// open data file
use `data', clear
	
// combine string and numeric components
foreach var of varlist *__s {
	local varname = subinstr("`var'","__s","",1)
	cap confirm variable `varname', exact
	if _rc {
		encode `var', gen(`varname')
		drop `var'
	}
	else {
		svy_encode `var' `varname'
	}
}

replace urbanicity = -9998 if area == -9998
replace urbanicity = -9994 if area == -9997
drop area hc1e

save "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence/MICS/mics_raw.dta", replace
// use "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence/MICS/mics_raw.dta", clear
	if file == "J:/DATA/UNICEF_MICS/ZWE/2014/ZWE_MICS5_2014_HH_Y2015M04D06.DTA" | file == "J:/DATA/UNICEF_MICS/VNM/2013_2014/VNM_MICS5_2013_2014_HH_Y2015M09D28.DTA" | file == "J:/DATA/UNICEF_MICS/MWI/2013_2014/MWI_MICS5_2013_2014_HH_Y2015M08D14.DTA" | file == "J:/DATA/UNICEF_MICS/KGZ/2014/KGZ_MICS5_2014_HH_Y2015M12D22.DTA" {
	gen handwashing = .
	replace handwashing = 1 if station == 1 | water == 1 | barsoap == 1 
	replace handwashing = 0 if handwashing == .
	}
	if file == "J:/DATA/UNICEF_MICS/MRT/2011/MRT_MICS4_2011_HH_Y2015M03D24.DTA" {
	gen handwashing = .
	replace handwashing = 1 if station == 1 | water == 1 | barsoap == "A"
	replace handwashing = 0 if handwashing == .
	}
// generate station indicator
// gen indic_station = 1 if inlist(station,-9988,-9987,-9986)
gen indic_station = 1 if inlist(station,-9983,-9997,-9985,-9984,-9983,-9982,-9976)
replace indic_station = 0 if inlist(station,-9987,-9999,-9998,-9996,-9995,-9994,-9993,-9989,-9988,-9987,-9978) & indic_station == .
// replace indic_station = 0 if !inlist(station,-9995,-9991,-9990,-9983) & indic_station == .

// generate water indicator
gen indic_water = 1 if inlist(water,-9998,-9986,-9997,-9994,-9987,-9986,-9983)
replace indic_water = 0 if inlist(water,-9999,-9996,-9995,-9993,-9992,-9991,-9990,-9989,-9988,-9985,-9984) & indic_water == .

// generate soap indicators
gen indic_barsoap = 1 if inlist(barsoap,-9994,-9993,-9992)
gen indic_liqsoap = 1 if liqsoap == "B"
gen indic_detsoap = 1 if detergent == "C"

gen indic_soap = 1 if !mi(indic_barsoap) | !mi(indic_liqsoap) | !mi(indic_detsoap)
replace indic_soap = 0 if indic_station != . & indic_soap != 1

// generate handwashing variable with missingness excluded
gen handwashing = 1 if indic_station == 1 & indic_water == 1 & indic_soap == 1
replace handwashing = 0 if indic_station == 0

// declare surveyset and tabulate with missingness excluded
levelsof file, local(files)
foreach file of local files {

// for all households
	preserve
	di in red "starting `file'"
		keep if file == "`file'"
		svyset psu [pweight=pweight]
		svy: mean handwashing 
			matrix mean_matrix = e(b)
			local mean_scalar = mean_matrix[1,1]
			gen hwws_mean = `mean_scalar'

			matrix variance_matrix = e(V)
			local se_scalar = sqrt(variance_matrix[1,1])
			gen hwws_se = `se_scalar'
			
			count
			gen sample_size = `r(N)'
			keep if _n==1
			keep file hwws_mean hwws_se sample_size			
		append using `tabulated'
		save `tabulated', replace
	restore
	
// for households with a child under 5
	preserve
	di in red "starting `file'"
		keep if file == "`file'"
		svyset psu [pweight=pweight]
		keep if under_5 > 0
		svy: mean handwashing 
			matrix mean_matrix = e(b)
			local mean_scalar = mean_matrix[1,1]
			gen hwws_mean = `mean_scalar'

			matrix variance_matrix = e(V)
			local se_scalar = sqrt(variance_matrix[1,1])
			gen hwws_se = `se_scalar'
			
			count
			gen sample_size = `r(N)'
			keep if _n==1
			keep file hwws_mean hwws_se sample_size			
		append using `tabulated_under_5'
		save `tabulated_under_5', replace
	restore
}	

// generate handwashign variable with missingness as 0
replace handwashing = 0 if handwashing == .
	
// declare surveyset and tabulate with missingness as 0
foreach file of local files {

// for all households
	preserve
	di in red "starting `file'"
		keep if file == "`file'"
		svyset psu [pweight=pweight]
		svy: mean handwashing 
			matrix mean_matrix = e(b)
			local mean_scalar = mean_matrix[1,1]
			gen hwws_mean = `mean_scalar'

			matrix variance_matrix = e(V)
			local se_scalar = sqrt(variance_matrix[1,1])
			gen hwws_se = `se_scalar'
			
			count
			gen sample_size = `r(N)'
			keep if _n==1
			keep file hwws_mean hwws_se sample_size			
		append using `tabulated_m'
		save `tabulated_m', replace
	restore
	
// for households with a child under 5
	preserve
	di in red "starting `file'"
		keep if file == "`file'"
		svyset psu [pweight=pweight]
		keep if under_5 > 0
		svy: mean handwashing 
			matrix mean_matrix = e(b)
			local mean_scalar = mean_matrix[1,1]
			gen hwws_mean = `mean_scalar'

			matrix variance_matrix = e(V)
			local se_scalar = sqrt(variance_matrix[1,1])
			gen hwws_se = `se_scalar'
			
			count
			gen sample_size = `r(N)'
			keep if _n==1
			keep file hwws_mean hwws_se sample_size	
		append using `tabulated_m_under_5'
		save `tabulated_m_under_5', replace
	restore
}
	
// save tabulated data
use `tabulated', clear
duplicates tag file, gen(tag)
drop if tag>0
drop tag
save "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\data\prevalence/MICS/mics_all_tab_2015.dta", replace

use `tabulated_under_5', clear
duplicates tag file, gen(tag)
drop if tag>0
drop tag
save "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\data\prevalence/MICS/mics_under_5_tab_2015.dta", replace

use `tabulated_m', clear
duplicates tag file, gen(tag)
drop if tag>0
drop tag
save "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\data\prevalence/MICS/mics_all_m_tab_2015.dta", replace

use `tabulated_m_under_5', clear
duplicates tag file, gen(tag)
drop if tag>0
drop tag
save "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\data\prevalence/MICS/mics_under_5_m_tab_2015.dta", replace

	