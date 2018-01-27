// File Name: plot_prev_all.do

// File Purpose: Plot prevalence of improved water sources and toilet types for applicable surveys
// Author: Leslie Mallinger
// Date: 4/15/10
// Edited on: 2/14/2011 (changed to use new estimates, plot in "Second Attempt" folder)

// Additional Comments: 

clear all
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local graph_folder "J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/prevalence"
local dat_folder_compiled "${data_folder}/Compiled"


** initialize pdfmaker
	set scheme s1color
	capture confirm file "C:/Program Files (x86)/Adobe/Acrobat 11.0/Acrobat/acrodist.exe"
	if _rc == 0 {
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
	}
	else {
		do "J:/Usable/Tools/ADO/pdfmaker_Acrobat10.do"
	}


local prevtypes rough final
foreach prevtype of local prevtypes {
	use "`dat_folder_compiled'/prev_all_`prevtype'.dta", clear
	rename location_name countryname
	local measures Water Sanitation Piped Sewer
	foreach m of local measures {
		local lower_m = strlower("`m'")
		levelsof countryname, local(country)
		
		pdfstart using "`graph_folder'/prevalence_`lower_m'_`prevtype'.pdf"
		foreach c of local country {		
			twoway scatter i`lower_m'_mean startyear if plot == "MICS" & countryname == "`c'", /// 
					mcolor("166 206 227") msymbol("circle") || /// 
				scatter i`lower_m'_mean startyear if plot == "DHS" & countryname == "`c'", /// 
					mcolor("31 120 180") msymbol("circle") || ///
				scatter i`lower_m'_mean startyear if plot == "RHS" & countryname == "`c'", ///
					mcolor("178 223 138") msymbol("circle") || ///
				scatter i`lower_m'_mean startyear if plot == "LSMS" & countryname == "`c'", ///
					mcolor("51 160 44") msymbol("circle") || ///
				scatter i`lower_m'_mean startyear if plot == "Census" & countryname == "`c'", ///
					mcolor("251 154 153") msymbol("circle") || ///
				scatter i`lower_m'_mean startyear if plot == "IPUMS" & countryname == "`c'", ///
					mcolor("227 26 28") msymbol("circle") || ///
				scatter i`lower_m'_mean startyear if plot == "Other" & countryname == "`c'", /// 
					mcolor("253 191 111") msymbol("square") || ///
				scatter i`lower_m'_mean startyear if plot == "Report" & countryname == "`c'", ///
					mcolor("255 127 0") msymbol("triangle") || ///
				scatter i`lower_m'_mean startyear if plot == "JMP" & countryname == "`c'", ///
					mcolor("106 61 154") msymbol("triangle_hollow") || ///
				scatter i`lower_m'_mean startyear if (nopsu == "1" | noweight == "1" | subnational == 1 | plot == "Subnational") & countryname == "`c'", ///
					mcolor("black") msymbol("X") ///
				title("`c'") ///
				subtitle("Improved `m'") ///
				legend(label(1 "MICS") label(2 "DHS") label(3 "RHS") label(4 "LSMS") label(5 "Census") ///
					label(6 "IPUMS") label(7 "Other") label(8 "Report") label(9 "JMP") label(10 "No PSU/Weight/Subnat.") ///
					cols(4) size(vsmall)) ///
				xlabel(1980(5)2010) /// 
				ylabel(0(0.2)1) ///
				xtitle("Year") /// 
				ytitle("Prevalence")
			pdfappend
		}
		pdffinish, view
		**capture erase "`graph_folder'/prevalence_`lower_m'_`prevtype'.log"
	}
}
	

	
// NEXT COLORS:  255 255 51, 166 86 40	

