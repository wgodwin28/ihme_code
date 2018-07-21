// File Name: plot_smoothing_overlay_wsc.do

// File Purpose: Plot GPR results for water and sanitation coverage comparing GPR from 2011 vs. 2013
// Author: Leslie Mallinger
// Date: 8/27/2011
// Edited on: 10/2/2013 by Astha KC 

// Additional Comments: 


clear all
macro drop _all
**set mem 500m
set more off
**capture log close
capture restore, not 


** create locals for relevant files and folders
**local log_folder "J:/Project/COMIND/Water and Sanitation/Smoothing/GPR Code"
local gpr_output_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation/model/gpr_output"
**local spacetime_output_folder "J:/Project/COMIND/Water and Sanitation/Smoothing/Spacetime Results"
local codes_folder "J:/DATA/IHME_COUNTRY_CODES" 
local graph_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation/graphs"



** initialize pdfmaker
	set scheme s1color
	capture confirm file "C:/Program Files (x86)/Adobe/Acrobat 11.0/Acrobat/acrodist.exe"
	if _rc == 0 {
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
	}
	else {
		do "J:/Usable/Tools/ADO/pdfmaker_Acrobat10.do"
	}
	
** prepare
local modelname old new
local sex B
local outcome_type prev


** combine results for water, sanitation, and combined
foreach i in new old {
	use "`gpr_output_folder'/gpr_results_w_`i'.dta", clear
	keep iso3 year gpr_mean gpr_upper gpr_lower
	rename gpr_mean `i'_mean
	rename gpr_lower `i'_lower
	rename gpr_upper `i'_upper
	tempfile `i'
	save ``i'', replace
}
use `new', clear
merge m:1 iso3 year using `old', nogen
drop if year < 1980

preserve
	use "`codes_folder'/IHME_COUNTRY_CODES_Y2013M07D26.DTA", clear
	drop if iso3 == ""
	tempfile codes
	save `codes', replace
restore

merge m:1 iso3 using `codes', keepusing(gbd_region_name location_name) keep(3) nogen
rename gbd_region_name region


** initialize pdfmaker
	set scheme s1color
	capture confirm file "C:/Program Files (x86)/Adobe/Acrobat 11.0/Acrobat/acrodist.exe"
	if _rc == 0 {
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
	}
	else {
		do "J:/Usable/Tools/ADO/pdfmaker_Acrobat10.do"
	}
	
	pdfstart using "`graph_folder'/comparison_w_overlay_plots.pdf"

	// loop through countries, organized by region, and plot
	levelsof region, local(regs)
	foreach r of local regs {
		di " ." _c
		quietly {
			levelsof iso3 if region == "`r'", local(isos)
			foreach c of local isos {
				preserve
				keep if iso3 == "`c'"
					sort year
					local nm = location_name
					
					twoway line new_mean new_upper new_lower year, lcolor(red red red) lpattern(solid dash dash) || ///
					line old_mean old_upper old_lower year, lcolor(blue blue blue) lpattern(solid dash dash)  ///
					title("`nm'") ///
					subtitle("Water coverage - Comparison") ///
					legend(label(1 "new GPR mean") label(2 "new GPR upper") label(3 "new GPR lower") ///
					label(4 "old GPR mean") label(5 "old GPR upper") label(6 "old GPR lower")) ///
					xlabel(1980(5)2015) ///
					ylabel(0(0.2)1) ///
					xtitle("Year") ///
					ytitle("Prevalence")
					
					pdfappend
				restore
			}
		}
}
pdffinish, view
	**capture erase "`graph_folder'/paper_wsc_overlay_plots.log"