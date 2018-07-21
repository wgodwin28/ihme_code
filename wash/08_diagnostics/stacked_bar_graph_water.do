// Author: Will Godwin
// Purpose: Create stacked bar plots for each country for water categories.
// Housekeeping
// do "/snfs2/HOME/wgodwin/risk_factors2/wash/08_diagnostics/stacked_bar_graph_water.do"
clear all 
set more off
set maxvar 32767
	
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Set relevant locals
local graphloc 			"$j/WORK/05_risk/risks/wash_water/diagnostics/exposure/stacked"
local dataloc			"$j/WORK/05_risk/risks/wash_water/data/exp/04_output"
local c_date= c(current_date)
local date = subinstr("`c_date'", " " , "_", .)
//local date "27_Jun_2018"
adopath + "$j/temp/central_comp/libraries/current/stata"


// Prep country names to be merged on later
	get_location_metadata, location_set_id(22) clear
	keep if level >= 3
	keep location_id location_ascii_name super_region_id region_name ihme_loc_id
	tempfile codes
	save `codes', replace 

// open dataset and rename to avoid wildcard issue of hq categories combining with regular piped categories
use "`dataloc'/allcat_prev_water_`date'", clear
foreach source in t t2 untr {
	forvalues n = 0/999 {
		rename prev_piped_`source'_hq_`n' prev_hq_piped_`source'_`n'
	}	
}
// open dataset
	/* generate mean */ // Now combining high quality piped with regular piped for visulaizing purposes
	fastrowmean prev_bas_piped_t_*, mean_var_name(prev_piped_t_mean)
	fastrowmean prev_hq_piped_t_*, mean_var_name(prev_piped_t_hq_mean)
	//gen prev_piped_t_mean = prev_piped_t_mean2 + prev_piped_t_hq_mean

	fastrowmean prev_bas_piped_untr_*, mean_var_name(prev_piped_untr_mean)
	fastrowmean prev_hq_piped_untr_*, mean_var_name(prev_piped_untr_hq_mean)
	//gen prev_piped_untr_mean = prev_piped_untr_mean2 + prev_piped_untr_hq_mean

	fastrowmean prev_bas_piped_t2_*, mean_var_name(prev_piped_t2_mean)
	fastrowmean prev_hq_piped_t2_*, mean_var_name(prev_piped_t2_hq_mean)
	//gen prev_piped_t2_mean = prev_piped_t2_mean2 + prev_piped_t2_hq_mean

	fastrowmean prev_imp_t_*, mean_var_name(prev_imp_t_mean)  
	fastrowmean prev_imp_t2_*, mean_var_name(prev_imp_t2_mean)   
	fastrowmean prev_imp_untr_*, mean_var_name(prev_imp_untr_mean)
	fastrowmean prev_unimp_t_*, mean_var_name(prev_unimp_t_mean)
	fastrowmean prev_unimp_t2_*, mean_var_name(prev_unimp_t2_mean)
	fastrowmean prev_unimp_untr_*, mean_var_name(prev_unimp_untr_mean)
	
	// clean up and save	
	keep location_id year_id *mean
	rename (prev_piped_t_hq_mean prev_piped_t2_hq_mean prev_piped_untr_hq_mean prev_piped_t_mean prev_piped_t2_mean prev_piped_untr_mean prev_imp_t_mean prev_imp_t2_mean prev_imp_untr_mean prev_unimp_t_mean prev_unimp_t2_mean prev_unimp_untr_mean) (exp_cat1 exp_cat2 exp_cat3 exp_cat4 exp_cat5 exp_cat6 exp_cat7 exp_cat8 exp_cat9 exp_cat10 exp_cat11 exp_cat12)
	//rename (prev_piped_t_mean prev_piped_t2_mean prev_piped_untr_mean prev_imp_t_mean prev_imp_t2_mean prev_imp_untr_mean prev_unimp_t_mean prev_unimp_t2_mean prev_unimp_untr_mean) (exp_cat1 exp_cat2 exp_cat3 exp_cat4 exp_cat5 exp_cat6 exp_cat7 exp_cat8 exp_cat9)
	// drop prev_*
	tempfile temp
	save `temp', replace

	// compile population and region variables
	merge m:1 location_id using `codes', keep(1 3) keepusing(super_region_id region_name location_ascii_name) nogen
	replace location_ascii_name = "Asir" if location_ascii_name=="'Asir" // Account for formatting issue of apostrophe"
	
	// Separate out High-Income countries that serve as TMREL
	// gen exp_cat0 = 0
	// drop if super_region_id==64 & region_name!="Southern Latin America"
	// replace exp_cat4 = 0 if super_region_id==64 & region_name!="Southern Latin America"
	// replace exp_cat0 = 1 if super_region_id==64 & region_name!="Southern Latin America" 
	// Plus HK and Macao
	// drop if location_id==354 | location_id==361
	// replace exp_cat4 = 0 if location_id==354 | location_id==361
	// replace exp_cat0 = 1 if location_id==354 | location_id==361
	
	gen total = exp_cat1 + exp_cat2 + exp_cat3 + exp_cat4 + exp_cat5 + exp_cat6 + exp_cat7 + exp_cat8 + exp_cat9 + exp_cat10 + exp_cat11 + exp_cat12
	
	// open dataset prepared for stacked bar graph 
	
		do "$j/Usable/Tools/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graphloc'/water_exp_stackedbar_`date'.pdf"
		sort location_id year_id
		// encode region_name, gen(region_code)
			levelsof location_id, local(locations) 
			foreach loc of local locations {
				preserve
				keep if location_id == `loc'
				local nm = location_ascii_name
				graph bar exp_cat1 exp_cat2 exp_cat3 exp_cat4 exp_cat5 exp_cat6 exp_cat7 exp_cat8 exp_cat9 exp_cat10 exp_cat11 exp_cat12, over(year_id, gap(0) ///
				label(angle(45) labsize(vsmall))) stack bar(1, fcolor(midblue) lcolor(midblue)) bar(2, fcolor(ebblue) lcolor(ebblue)) bar(3, fcolor(eltblue) ///
				lcolor(eltblue)) bar(4, fcolor(orange) lcolor(orange)) bar(5, fcolor(yellow) lcolor(yellow)) bar(6, fcolor(orange_red) lcolor(orange_red)) ///
				bar(7, fcolor(brown) lcolor(brown)) bar(8, fcolor(maroon) lcolor(maroon)) bar(9, fcolor(gs8) lcolor(gs8)) bar(10, fcolor(dkgreen) lcolor(dkgreen)) bar(11, fcolor(red) lcolor(red)) bar(12, fcolor(sienna) lcolor(sienna)) title("`nm'") ///
				legend(label(1 "Piped & filtered(HQ)") label(2 "Piped & chlorinated(HQ)") label(3 "Piped & untreated(HQ)") label(4 "Piped & filtered") label(5 "Piped & chlorinated") label(6 "Piped & untreated") label(7 "Improved & filtered") ///
				label(8 "Improved & chlorinated") label(9 "Improved & untreated") label(10 "Unimproved & filtered") ///
				label(11 "Unimproved & chlorinated") label(12 "Unimproved & untreated") size(vsmall) col(3)) ylabel(#5, labsize(small)) ylabel(0(.2)1)
				pdfappend
				restore
			}
	pdffinish, view


