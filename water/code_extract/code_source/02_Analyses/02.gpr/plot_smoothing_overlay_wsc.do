// File Name: plot_smoothing_overlay_wsc.do

// File Purpose: Plot GPR results for water, sanitation, and combined data
// Author: Leslie Mallinger
// Date: 8/27/2011
// Edited on: 

// Additional Comments: 


clear all
macro drop _all
set mem 500m
set more off
capture log close
capture restore, not 


** create locals for relevant files and folders
local log_folder "J:/Project/COMIND/Water and Sanitation/Smoothing/GPR Code"
local gpr_output_folder "J:/Project/COMIND/Water and Sanitation/Smoothing/GPR Results"
local spacetime_output_folder "J:/Project/COMIND/Water and Sanitation/Smoothing/Spacetime Results"
local codes_folder "J:/Usable/Common Indicators/Country Codes"
local graph_folder "J:/Project/COMIND/Water and Sanitation/Graphs/Smoothed"


** initialize pdfmaker
	set scheme s1color
	capture confirm file "C:/Program Files (x86)/Adobe/Acrobat 9.0/Acrobat/acrodist.exe"
	if _rc == 0 {
		do "J:/Usable/Tools/ADO/pdfmaker.do"
	}
	else {
		do "J:/Usable/Tools/ADO/pdfmaker_Acrobat10.do"
	}
	
** prepare
local modelname w_paper s_paper c_paper
local sex B
local outcome_type prev


** combine results for water, sanitation, and combined
foreach i in w s c {
	use "`gpr_output_folder'/gpr_results_`i'_paper.dta", clear
	keep iso3 year gpr_mean
	rename gpr_mean `i'_mean
	tempfile `i'
	save ``i'', replace
}
use `w', clear
merge 1:1 iso3 year using `s', nogen
merge 1:1 iso3 year using `c', nogen
drop if year < 1980

preserve
	use "`codes_folder'/countrycodes_official.dta", clear
	keep if countryname == countryname_ihme
	drop if iso3 == ""
	tempfile codes
	save `codes', replace
restore

merge m:1 iso3 using `codes', keepusing(gbd_region countryname) keep(3) nogen
rename gbd_region region

pdfstart using "`graph_folder'/paper_wsc_overlay_plots.pdf"

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
					local nm = countryname
					
					twoway line w_mean year, lcolor(red) || ///
					line s_mean year, lcolor(blue) || ///
					line c_mean year, lcolor(green) ///
					title("`nm'") ///
					subtitle("Improved Water, Sanitation, and Combined") ///
					legend(label(1 "Water") label(2 "Sanitation") label(3 "Combined")) ///
					xlabel(1980(5)2010) ///
					ylabel(0(0.2)1) ///
					xtitle("Year") ///
					ytitle("Prevalence")
					
					pdfappend
				restore
			}
		}
	}
	qui pdffinish, view
	capture erase "`graph_folder'/paper_wsc_overlay_plots.log"