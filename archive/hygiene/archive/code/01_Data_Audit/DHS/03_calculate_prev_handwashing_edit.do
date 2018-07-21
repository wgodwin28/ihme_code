
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


// load variable file
use "$prefix/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence/DHS/varlist_dhs.dta", clear
local maxobs = _N

// loop through surveys
forvalues i = 1/`=_N' {

// assigns filepath and variable list
	local filepath = filepath_full[`i']
	local psu = psu[`i']
	local pweight = weight[`i']
	local urbanicity = urban[`i']
	local station = w_hwss[`i']
	local soap = w_soap[`i']
	local water = w_water[`i']
	local under_5 = "hv014"
	
	foreach vari in psu pweight urbanicity station soap water under_5 {
		local `vari' = lower("``vari''")
	}

// extract and append data
	preserve
	
	// run extraction program
		svy_extract, filepaths(`filepath') primary_vars(`psu' `pweight' `urbanicity' `station' `soap' `water' `under_5')
		
	// rename extracted variables
		foreach vari in psu pweight urbanicity station soap water under_5 {
			cap rename ``vari'' `vari'
			cap rename ``vari''__s `vari'__s
		}
		
		append using `data'
		save `data', replace
	restore

}

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

save "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence/DHS/dhs_raw2.dta", replace
use "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence/DHS/dhs_raw2.dta", clear
// drop unwanted
drop if file == "J:/DATA/MACRO_DHS/COG/2011_2012/COG_DHS6_2011_2012_HH_Y2013M10D15.DTA" | file == "J:/DATA/MACRO_DHS/EGY/2005/EGY_DHS5_2005_HH_Y2008M09D23.DTA" | file == "J:/DATA/MACRO_DHS/KAZ/1999/KAZ_DHS4_1999_HH_Y2008M09D23.DTA" | file == "J:/DATA/MACRO_DHS/MAR/2003_2004/MAR_DHS4_2003_2004_HH_Y2008M09D23.DTA" | file == "J:/DATA/MACRO_DHS/MLI/2006/MLI_DHS5_2006_HH_Y2008M09D23.DTA" | file == "J:/DATA/MACRO_DHS/NER/2006/NER_DHS5_2006_HH_Y2008M09D23.DTA" | file == "J:/DATA/MACRO_DHS/UZB/2002/UZB_SP_DHS4_2002_HH_Y2008M09D23.DTA" | file == "J:/DATA/MACRO_DHS/ZWE/1999/ZWE_DHS4_1999_HH_Y2008M10D22.DTA"
drop if (station == . & water == . & soap == .) | (station == -9999 & water == -9999 & soap == -9999)

/*
levelsof file, l(files)
foreach file of local files {
	preserve
	keep if file=="`file'"
	di in red _N
	restore
} */
// replace nulls
replace station = . if station == -9999
replace water = . if water == -9999
replace soap = . if soap == -9999

// generate urbanicity marker
decode urbanicity, gen(urb_rur)

// generate station indicator
gen indic_station = 1 if inlist(station, -9987, -9997, -9986)

// replace indic_station = 0 if !inlist(station, -9998, -9997, -9996, -9994, -9991) & indic_station == .
replace indic_station = 0 if inlist(station, -9994, -9993, -9992, -9991, -9990, -9989, -9988, 9) & indic_station == .
// replace indic_station = 0 if !inlist(station, -9987, -9997, -9986) & indic_station == .

// generate water indicator
gen indic_water = 1 if inlist(water,-9994,-9996)
replace indic_water = 0 if inlist(water,-9997,-9995,-9998, 9, .) & indic_water == .

// generate soap indicator
gen indic_soap = 1 if soap == -9997
replace indic_soap = 0 if soap == -9998 | indic_soap == .

// generate handwashing variable with missingness excluded
gen handwashing = 1 if indic_station == 1 & indic_water == 1 & indic_soap == 1
replace handwashing = 0 if indic_station == 0

// declare surveyset and tabulate with missingness excluded
levelsof file, local(files)
foreach file of local files {

// for all households
	preserve
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

// generate handwashing variable with missingness as 0
replace handwashing = 0 if handwashing == .

// declare surveyset and tabulate with missingness as 0
foreach file of local files {

// for all households
	preserve
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
save "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\data\prevalence/DHS/dhs_all_tab_2015.dta", replace

use `tabulated_under_5', clear
save "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\data\prevalence/DHS/dhs_under_5_tab_2015.dta", replace

use `tabulated_m', clear
save "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\data\prevalence/DHS/dhs_all_m_tab_2015.dta", replace

use `tabulated_m_under_5', clear
save "J:\WORK\01_covariates\02_inputs\water_sanitation\hygiene\data\prevalence/DHS/dhs_under_5_m_tab_2015.dta", replace

