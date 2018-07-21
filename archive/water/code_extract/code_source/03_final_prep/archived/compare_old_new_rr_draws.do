**COMPARE OLD AND NEW RRs FOR WATER
**DATE: JULY 13 2015


clear all
set more off
set obs 1

// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 
	
// Set relevant locals
	local rr_draws 		"/clustertmp/WORK/05_risk/02_models/02_results"
	local old_version	6
	local new_version 	8
	
	

	foreach region of "R1" "R13" {
		forvalues n  = 1/9 {
			
			insheet using "`rr_draws'/wash_water/old_version/rr_`region'.csv", comma clear
			forvalues n = 0/999 {
				rename rr_`n' old_`n'
				}
			
			
		}
	}
	
**DEVELOPED 
	insheet using "C:\Users\asthak\Desktop\wash_correlated_draws\old_rr_R13.csv", comma clear
	keep if acause == "diarrhea"
	keep parameter rr_*
	drop *mean *lower *upper
	forvalues n = 1/9 {
	preserve
	keep if parameter == "cat`n'"
	reshape long rr_, i(parameter) j(draw)
	rename rr_ old_cat`n'
	drop parameter
	
	if `n' == 1 {
		tempfile old_developed
		save `old_developed', replace
		}
	else {
		merge 1:1 draw using `old_developed', keep(1 3) nogen
		save `old_developed', replace
		}
	restore
	}
	
	insheet using "C:\Users\asthak\Desktop\wash_correlated_draws\new_rr_R13.csv", comma clear
	keep if acause == "diarrhea"
	keep parameter rr_*
	drop *mean *lower *upper
	forvalues n = 1/9 {
	preserve
	keep if parameter == "cat`n'"
	reshape long rr_, i(parameter) j(draw)
	rename rr_ new_cat`n'
	drop parameter
	
	if `n' == 1 {
		tempfile new_developed
		save `new_developed', replace
		}
	else {
		merge 1:1 draw using `new_developed', keep(1 3) nogen
		save `new_developed', replace
		}
	restore
	}
	
	
	use `old_developed', clear
	merge 1:1 draw using `new_developed', keep(1 3) nogen
	
	forvalues n = 1/9 {
		twoway scatter old_cat`n' new_cat`n'
		graph export "J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/rr/old_new_cat`n'_developed.png", replace
		}

**DEVELOPING
	insheet using "C:\Users\asthak\Desktop\wash_correlated_draws\old_rr_R1.csv", comma clear
	keep if acause == "diarrhea"
	keep parameter rr_*
	drop *mean *lower *upper
	forvalues n = 1/9 {
	preserve
	keep if parameter == "cat`n'"
	reshape long rr_, i(parameter) j(draw)
	rename rr_ old_cat`n'
	drop parameter
	
	if `n' == 1 {
		tempfile old_developing
		save `old_developing', replace
		}
	else {
		merge 1:1 draw using `old_developing', keep(1 3) nogen
		save `old_developing', replace
		}
	restore
	}
	
	insheet using "C:\Users\asthak\Desktop\wash_correlated_draws\new_rr_R1.csv", comma clear
	keep if acause == "diarrhea"
	keep parameter rr_*
	drop *mean *lower *upper
	forvalues n = 1/9 {
	preserve
	keep if parameter == "cat`n'"
	reshape long rr_, i(parameter) j(draw)
	rename rr_ new_cat`n'
	drop parameter
	
	if `n' == 1 {
		tempfile new_developing
		save `new_developing', replace
		}
	else {
		merge 1:1 draw using `new_developing', keep(1 3) nogen
		save `new_developing', replace
		}
	restore
	}
	
	 use `old_developing', clear
	 merge 1:1 draw using `new_developing', keep(1 3) nogen
	 	forvalues n = 1/9 {
		twoway scatter old_cat`n' new_cat`n'
		graph export "J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/rr/old_new_cat`n'_developing.png", replace
		}