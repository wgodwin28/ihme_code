// File Name: plot_smoothing.do

// File Purpose: Plot smoothing results for water and sanitation data
// Author: Leslie Mallinger
// Date: 7/20/10
// Edited on: 2/15/2011

// Additional Comments: 


clear all
macro drop _all
set mem 500m
set more off
capture log close
capture restore, not 


** create locals for relevant files and folders
local log_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation/code/model/02.gpr"
local gpr_output_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation/model/gpr_output"
local spacetime_output_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation/smoothing/spacetime results"
local graph_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation/graphs/smoothed"


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
** local modelname w_paper s_paper w_codmod s_codmod
local modelname w_paper s_paper c_paper
local sex B
local outcome_type prev


** loop through models to be plotted
** local model w`iteration_num'
foreach model of local modelname {
	// open datset and initialize plot
	use "`gpr_output_folder'/gpr_results_`model'_with_orig_data.dta", clear
	
	if regexm("`model'", "w") {
		append using "`spacetime_output_folder'/water_outliers.dta"
		local parameter Water
	}
	if regexm("`model'", "s") {
		append using "`spacetime_output_folder'/sanitation_outliers.dta"
		local parameter Sanitation
	}
	if regexm("`model'", "c") & "`model'" != "w_codmod" & "`model'" != "s_codmod" {
		append using "`spacetime_output_folder'/combined_outliers.dta"
		local parameter Combined
	}
	
	pdfstart using "`graph_folder'/`model'_plots.pdf"
	di _n "Plotting Model `model'" _c
	
	drop if year < 1980


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
					
					twoway scatter actual_`outcome_type' year if plot == "MICS", /// 
						mcolor("166 206 227") msymbol("circle") || /// 
					scatter actual_`outcome_type' year if plot == "DHS", /// 
						mcolor("31 120 180") msymbol("circle") || ///
					scatter actual_`outcome_type' year if plot == "RHS", ///
						mcolor("178 223 138") msymbol("circle") || ///
					scatter actual_`outcome_type' year if plot == "LSMS", ///
						mcolor("51 160 44") msymbol("circle") || ///
					scatter actual_`outcome_type' year if plot == "Census", ///
						mcolor("251 154 153") msymbol("circle") || ///
					scatter actual_`outcome_type' year if plot == "IPUMS", ///
						mcolor("227 26 28") msymbol("circle") || ///
					scatter actual_`outcome_type' year if plot == "Other", /// 
						mcolor("253 191 111") msymbol("square") || ///
					scatter actual_`outcome_type' year if plot == "Report", ///
						mcolor("255 127 0") msymbol("triangle") || ///
					scatter actual_`outcome_type' year if plot == "JMP", ///
						mcolor("106 61 154") msymbol("triangle_hollow") || ///
					scatter actual_`outcome_type' year if (national == 0), ///
						mcolor("black") msymbol("X") || ///
					scatter actual_`outcome_type' year if plot == "Outlier", ///
						mcolor("red") msymbol("X") || ///
					line step1_`outcome_type' year, ///
						lcolor(gray) lpattern(_) || ///
					line step2_`outcome_type' year, ///
						lcolor(black) || ///
					line gpr_mean year, ///
						lcolor(green) || ///
					line gpr_lower year, ///
						lcolor(green) lpattern(_) || ///
					line gpr_upper year, ///
						lcolor(green) lpattern(_) ///
					title("`nm'") ///
					subtitle("Improved `parameter'") ///
					legend(label(1 "MICS") label(2 "DHS") label(3 "RHS") label(4 "LSMS") label(5 "Census") ///
						label(6 "IPUMS") label(7 "Other") label(8 "Report") label(9 "JMP") label(10 "No PSU/Weight/Subnat.") ///
						label(11 "Outlier") label(12 "OLS Step 1") label(13 "OLS Step 2") label(14 "GPR") ///
						order(1 2 3 4 5 6 7 8 9 10 11 12 13 14) ///
						cols(4) size(vsmall)) ///
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
	capture erase "`graph_folder'/`model'_plots.log"
}

