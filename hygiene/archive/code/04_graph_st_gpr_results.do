**Filename: graph.do

**Purpose: Graph results of exploratory analyses done to estimate proportion with access to safe drinking water
**Author: Astha KC
**Date: 2/7/2014

**set relevant locals
local spacetime		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/smoothing/spacetime results"
local graphloc 		"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/output/graphs"
local gpr_output	"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/gpr/gpr output"
local gpr_graphloc	"J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/gpr"

local date 06112014
	
**graph spacetime data
	local measures hwws

	foreach measure of local measures {
		
		use "`spacetime'/`measure'_B_results.dta", clear
		
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graphloc'/smoothing_`measure'_`date'.pdf"
		sort iso3 year
		encode gbd_analytical_region_name, gen(region_code)
		levelsof region_code, l(regs) c
		foreach r of local regs {
		levelsof iso3 if region_code == `r', l(isos) 
		foreach i of local isos {
			preserve
			keep if iso3 == "`i'"
			local nm = location_name
			twoway scatter actual_prev year if reference_data == 1, mcolor(black) || ///
			scatter actual_prev year if reference_data == 0, mcolor(red) || ///
			line step1_prev step2_prev year, lcolor(dknavy dknavy) lpattern(solid dash) ///
			title("`nm'") lwidth(medium medium) ///
			legend(label(1 "Observed - Lit") label(2 "Observed - Survey") label(3 "OLS") label(4 "Spacetime") size(vsmall))  ///
			ylabel(#5, labsize(small)) ylabel(0(.2)1) xlabel(1980(5)2015)
			pdfappend
			restore
		}
	}
	pdffinish, view

	}
	
	
	****GPR***
	
	local date 10032014
	local measures hwws
	foreach measure of local measures {
		
		use "`gpr_output'/gpr_results_`measure'_with_orig_data.dta", clear
		
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`gpr_graphloc'/gpr_`measure'_`date'_madglobal.pdf"
		sort iso3 year
		encode gbd_analytical_region_name, gen(region_code)
		levelsof region_code, l(regs) c
		foreach r of local regs {
		levelsof iso3 if region_code == `r', l(isos) 
		foreach i of local isos {
			preserve
			keep if iso3 == "`i'"
			local nm = location_name
			twoway scatter actual_prev year if reference_data == 1, mcolor(black) || ///
			scatter actual_prev year if reference_data == 0, mcolor(red) || ///
			line step1_prev step2_prev year, lcolor(dknavy dknavy) lpattern(solid dash) || ///
			line gpr_mean gpr_upper gpr_lower year, lcolor(green green green) lpattern(solid dash dash) ///
			title("`nm'") lwidth(medium medium) ///
			legend(label(1 "Observed - lit") label(2 "Observed - survey") ///
				label(3 "OLS") label(4 "Spacetime") label(5 "gpr mean") label(6 "gpr upper") label(7 "gpr lower") size(vsmall) col(4))  ///
			ylabel(#5, labsize(small)) ylabel(0(.2)1) xlabel(1980(5)2015)
			pdfappend
			restore
		}
	}
	pdffinish, view
}		

**End of Code**
