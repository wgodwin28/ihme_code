**Filename: graph.do

**Purpose: Graph results of exploratory analyses done to estimate proportion with access to safe drinking water
**Author: Astha KC
**Date: 2/7/2014


clear all
set more off

**set relevant locals
local spacetime		"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/smoothing/spacetime results"
local graphloc 		"J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/smoothed"
local gpr_output	"J:/WORK/01_covariates/02_inputs/water_sanitation/data/02_Analyses/gpr/gpr_output"
local gpr_graphloc	"J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/gpr"

local date 06092014
	
**graph spacetime data
	local measures s sewer w piped

	foreach measure of local measures {
		
		use "`spacetime'/`measure'_covar_B_results.dta", clear
		if ("`measure'"=="sewer" | "`measure'"=="piped") {
			append using "`spacetime'/`measure'_outliers.dta" 
			}
		if ("`measure'"=="w") {
			append using "`spacetime'/water_outliers.dta" 
			}
		if ("`measure'"=="s") {
			append using "`spacetime'/sanitation_outliers.dta" 
		}
		
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graphloc'/smoothing_covar_`measure'_`date'.pdf"
		sort iso3 year
		encode gbd_analytical_region_name, gen(region_code)
		levelsof region_code, l(regs) c
		foreach r of local regs {
		levelsof iso3 if region_code == `r', l(isos) 
		foreach i of local isos {
			preserve
			keep if iso3 == "`i'"
			local nm = location_name
			scatter actual_prev year if plot=="DHS", mcolor(blue)  || ///
			scatter actual_prev year if plot=="IPUMS", mcolor(red)  || ///
			scatter actual_prev year if plot=="Census", mcolor(red) msymbol(T) || ///
			scatter actual_prev year if plot=="LSMS", mcolor(orange)  || ///
			scatter actual_prev year if plot=="MICS", mcolor(ltblue)  || ///
			scatter actual_prev year if plot=="Other Survey", mcolor(olive_teal)  || ///
			scatter actual_prev year if plot=="RHS", mcolor(cranberry)  || ///
			scatter actual_prev year if plot=="Subnational", mcolor(blue) msymbol(+) || ///
			scatter actual_prev year if plot=="WHS", mcolor(pink)  || ///
			scatter actual_prev year if plot=="Report", mcolor(green) msymbol(T) || ///
			scatter actual_prev year if plot=="Outlier", mcolor(red) msymbol(X) || ///
			line step1_prev step2_prev year, lcolor(dknavy dknavy) lpattern(solid dash) ///
			title("`nm'") lwidth(medium medium) ///
			legend(label(1 "DHS") label(2 "IPUMS") label(3 "Census") label(4 "LSMS") label(5 "MICS") ///
				label(6 "Other Survey") label(7 "RHS") label(8 "Subnational") label(9 "WHS") label(10 "Report") label(11 "Outlier") ///
				label(12 "OLS") label(13 "Spacetime") size(vsmall) col(4))  ///
			ylabel(#5, labsize(small)) ylabel(0(.2)1) xlabel(1980(5)2015)
			pdfappend
			restore
		}
	}
	pdffinish, view

	}
	
	
	****GPR***
	local measures s sewer w piped 
	foreach measure of local measures {
		
		use "`gpr_output'/gpr_results_`measure'_covar_with_orig_data.dta", clear
		if ("`measure'"=="sewer" | "`measure'"=="piped") {
			append using "`spacetime'/`measure'_outliers.dta" 
			}
		if ("`measure'"=="w") {
			append using "`spacetime'/water_outliers.dta" 
			}
		if ("`measure'"=="s") {
			append using "`spacetime'/sanitation_outliers.dta" 
		}
		
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`gpr_graphloc'/gpr_covar_`measure'_`date'.pdf"
		sort iso3 year
		encode gbd_analytical_region_name, gen(region_code)
		levelsof region_code, l(regs) c
		foreach r of local regs {
		levelsof iso3 if region_code == `r', l(isos) 
		foreach i of local isos {
			preserve
			keep if iso3 == "`i'"
			local nm = location_name
			scatter actual_prev year if plot=="DHS", mcolor(blue)  || ///
			scatter actual_prev year if plot=="IPUMS", mcolor(red)  || ///
			scatter actual_prev year if plot=="Census", mcolor(red) msymbol(T)|| ///
			scatter actual_prev year if plot=="LSMS", mcolor(orange)  || ///
			scatter actual_prev year if plot=="MICS", mcolor(ltblue)  || ///
			scatter actual_prev year if plot=="Other Survey", mcolor(olive_teal)  || ///
			scatter actual_prev year if plot=="RHS", mcolor(cranberry)  || ///
			scatter actual_prev year if plot=="Subnational", mcolor(blue) msymbol(+) || ///
			scatter actual_prev year if plot=="WHS", mcolor(pink)  || ///
			scatter actual_prev year if plot=="Report", mcolor(green) msymbol(T) || ///
			scatter actual_prev year if plot=="Outlier", mcolor(red) msymbol(X) || ///
			line step1_prev step2_prev year, lcolor(dknavy dknavy) lpattern(solid dash) || ///
			line gpr_mean gpr_upper gpr_lower year, lcolor(green green green) lpattern(solid dash dash) ///
			title("`nm'") lwidth(medium medium) ///
			legend(label(1 "DHS") label(2 "IPUMS") label(3 "Census report") label(4 "LSMS") label(5 "MICS") ///
				label(6 "Other Survey") label(7 "RHS") label(8 "Subnational") label(9 "WHS") label(10 "Report") label(11 "Outlier") ///
				label(12 "OLS") label(13 "Spacetime") label(14 "gpr mean") label(15 "gpr upper") label(16 "gpr lower") size(vsmall) col(4))  ///
			ylabel(#5, labsize(small)) ylabel(0(.2)1) xlabel(1980(5)2015)
			pdfappend
			restore
		}
	}
	pdffinish, view
}		

**End of Code**
