//Purpose: To produce stacked bar graphs to display distribution of households by water source type and household water treatment use status
//Date: 6/14/2014
//Author: Astha KC


	**housekeeping**
	clear all
	set more off
	
	**set relevant locals
	local country_codes	 	"J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
	local graphloc 			"J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/graphs"

	**prep country codes
	use "`country_codes'", clear
	drop if iso3==""
	tempfile codes
	save `codes', replace
	
	**open dataset prepared for stacked bar graph
		use "`graphloc'/stacked_bargraph_cats_`date'.dta", clear
		merge m:1 iso3 using `codes', keep(1 3) keepusing(gbd_analytical_region_name) nogen
	
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graphloc'/water_exp_stackedbar_06062014.pdf"
		sort iso3 year
		encode gbd_analytical_region_name, gen(region_code)
		levelsof region_code, l(regs) c
		foreach r of local regs {
		levelsof iso3 if region_code == `r', l(isos) 
		foreach i of local isos {
			preserve
			keep if iso3 == "`i'"
			local nm = location_name
			graph bar exp_cat1 exp_cat2 exp_cat3 exp_cat4 exp_cat5 exp_cat6 exp_cat7 exp_cat8 exp_cat9, over(year) stack ///
			title("`nm'") legend(label(1 "Piped & filtered") label(2 "Piped & chlorinated") label(3 "Piped & untreated") label(4 "Improved & filtered") label(5 "Improved & chlorinated") ///
				label(6 "Improved & untreated") label(7 "Unimproved & filtered") label(8 "Unimproved & chlorinated") label(9 "Unimproved & untreated") ///
				size(vsmall) col(3)) ylabel(#5, labsize(small)) ylabel(0(.2)1)
			pdfappend
			restore
		}
	}
	pdffinish, view
	
	graph bar exp_cat1 exp_cat2 exp_cat3 exp_cat4 exp_cat5 exp_cat6 exp_cat7 exp_cat8, over(year) stack ///
			title("`nm'") legend(label(1 "Piped & filtered") label(2 "Piped & chlorinated") label(3 "Piped & untreated") label(4 "Improved & filtered") label(5 "Improved & chlorinated") ///
				label(6 "Improved & untreated") label(7 "Unimproved & filtered") label(8 "Unimproved & chlorinated") ///
				size(vsmall) col(3)) ylabel(#5, labsize(small)) ylabel(0(.2)1)
	
//end of code