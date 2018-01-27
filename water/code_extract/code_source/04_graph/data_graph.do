**Filename: data_graph.do

**Purpose: Graph results of exploratory analyses done to estimate proportion with access to safe drinking water
**Author: Astha KC
**Date: 2/7/2014

**set relevant locals
local dataloc		"J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Compiled"
local graphloc 		"J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/prevalence"
local date 04092014
	
**graph spacetime data
	local measures ipiped_mean isanitation_mean isewer_mean iwater_mean
	use "`dataloc'/prev_all_final.dta", clear
	rename startyear year
	sort iso3 year
	encode gbd_region_name, gen(region_code)
	levelsof region_code, l(regs) c
	foreach measure of local measures {
		
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graphloc'/`measure'_`date'.pdf"
		foreach r of local regs {
		levelsof iso3 if region_code == `r', l(isos) 
		foreach i of local isos {
			preserve
			keep if iso3 == "`i'"
			local nm = location_name
			scatter `measure' year if plot=="DHS", mcolor(blue)  || ///
			scatter `measure' year if plot=="IPUMS", mcolor(red)  || ///
			scatter `measure' year if plot=="LSMS", mcolor(orange)  || ///
			scatter `measure' year if plot=="MICS", mcolor(ltblue)  || ///
			scatter `measure' year if plot=="Other Survey", mcolor(olive_teal)  || ///
			scatter `measure' year if plot=="RHS", mcolor(orange_red)  || ///
			scatter `measure' year if plot=="Subnational", mcolor(blue) msymbol(+) || ///
			scatter `measure' year if plot=="WHS", mcolor(pink)  ///
			title("`nm'") lwidth(medium medium) ///
			legend(label(1 "DHS") label(2 "IPUMS") label(3 "LSMS") label(4 "MICS") ///
				label(5 "Other Survey") label(6 "RHS") label(7 "Subnational") label(8 "WHS") ///
				size(vsmall) col(4))  ///
			ylabel(#5, labsize(small)) ylabel(0(.2)1) xlabel(1980(5)2015)
			pdfappend
			restore
		}
	}
	pdffinish, view

	}
		
**End of Code**