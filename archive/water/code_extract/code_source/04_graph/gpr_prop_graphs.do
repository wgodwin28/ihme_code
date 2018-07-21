**Filename: gpr_prop_graphs.do

**Purpose: Graph GPR results of WSH proportion models 
**Author: Astha KC
**Date:04/21/2014

**set relevant locals
local gpr_output	"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/02_Analyses/data/gpr/gpr_output"
local gpr_graphloc	"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/02_Analyses/graphs/gpr"

local date 04292014
	
****GPR***
	local measures imp_treat imp_treat2 piped_treat piped_treat2 unimp_treat unimp_treat2
	foreach measure of local measures {
		
		**use "`gpr_output'/gpr_results_`measure'_with_orig_data.dta", clear
		
		keep if iso3=="MWI" | iso3=="GMB" | iso3=="ARG" | iso3=="IND" | iso3=="THA"
		
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
			scatter actual_prev year, mcolor(blue)  || ///
			line step1_prev step2_prev year, lcolor(dknavy dknavy) lpattern(solid dash) || ///
			line gpr_mean gpr_upper gpr_lower year, lcolor(green green green) lpattern(solid dash dash) ///
			title("`nm'") lwidth(medium medium) ///
			legend(label(1 "Observed") label(2 "OLS") label(3 "Spacetime") label(4 "gpr mean") ///
				label(5 "gpr upper") label(6 "gpr lower") size(vsmall) col(4))  ///
				ylabel(#5, labsize(small)) ylabel(0(.2)1) xlabel(1980(5)2015)
			pdfappend
			restore
		}
	}
	pdffinish, view
}		

**End of Code**

			scatter actual_prev year if plot=="DHS", mcolor(blue)  || ///
			scatter actual_prev year if plot=="IPUMS", mcolor(red)  || ///
			scatter actual_prev year if plot=="LSMS", mcolor(orange)  || ///
			scatter actual_prev year if plot=="MICS", mcolor(ltblue)  || ///
			scatter actual_prev year if plot=="Other Survey", mcolor(olive_teal)  || ///
			scatter actual_prev year if plot=="RHS", mcolor(orange_red)  || ///
			scatter actual_prev year if plot=="Subnational", mcolor(blue) msymbol(+) || ///
			scatter actual_prev year if plot=="WHS", mcolor(pink)  || ///