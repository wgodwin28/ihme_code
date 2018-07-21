// Author: Will Godwin
// Purpose: Create stacked bar plots for combined sanitation categories
// Housekeeping
// do "/snfs2/HOME/wgodwin/risk_factors/sanitation/code/03_final_prep/gen_stacked_bar_graph.do"
clear all 
set more off
set maxvar 30000

// Set relevant locals
local graphloc 			"/home/j/WORK/05_risk/risks/wash_sanitation/diagnostics/v1"
local dataloc			"/home/j/WORK/05_risk/risks/wash_sanitation/data/exp/me_id/uploaded/rough_output"
local date "06282017"

adopath + "/home/j/temp/central_comp/libraries/current/stata"


// Prep country names to be merged on later
	get_location_metadata, location_set_id(22) clear
	keep if level >= 3
	keep location_id location_ascii_name super_region_id region_name ihme_loc_id
	tempfile codes
	save `codes', replace 

/* // Prep population data
	get_demographics, gbd_team(cov)
	get_populations, year_id(2015) location_id($location_ids) sex_id(3) age_group_id(22) clear
	keep location_id year_id age_group_id sex_id pop_scaled
	rename pop_scaled mean_pop
	sort location_id
	tempfile all_pop
	save `all_pop', replace
*/
// open dataset
use "`dataloc'/allcat_prev_san_`date'", clear
	/* generate mean */
	fastrowmean prev_unimp_*, mean_var_name(prev_unimproved_mean)
	fastrowmean prev_improved_*, mean_var_name(prev_improved_mean)
	fastrowmean prev_sewer_*, mean_var_name(prev_sewer_mean)
	keep location_id year_id *mean
	rename (prev_unimproved_mean prev_improved_mean prev_sewer_mean) (exp_cat3 exp_cat2 exp_cat1)
	tempfile temp
	save `temp', replace
	
	// compile population and region variables
	merge m:1 location_id using `codes', keep(1 3) keepusing(super_region_id region_name location_ascii_name) nogen 
	replace location_ascii_name = "Asir" if location_ascii_name=="'Asir" // Account for formatting issue of apostrophe"


	// Separate out High-Income countries that serve as TMREL
	// drop if super_region_id==64 & region_name!="Southern Latin America"
	//drop if location_id==354 | location_id==361
	/* gen exp_cat0 = 0
	replace exp_cat1 = 0 if super_region_id==64 & region_name!="Southern Latin America"
	replace exp_cat0 = 1 if super_region_id==64 & region_name!="Southern Latin America" 
	// Plus HK and Macao
	replace exp_cat1 = 0 if location_id==354 | location_id==361
	replace exp_cat2 = 0 if location_id==354 | location_id==361
	replace exp_cat3 = 0 if location_id==354 | location_id==361
	replace exp_cat0 = 1 if location_id==354 | location_id==361 */

	gen total = exp_cat3 + exp_cat2 + exp_cat1
	
	
	// open dataset prepared for stacked bar graph 
	
		do "/home/j/Usable/Tools/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graphloc'/san_exp_stackedbar_`date'.pdf"
		sort location_id year_id
			levelsof location_id, local(locations) 
			foreach loc of local locations {
				preserve
				keep if location_id == `loc'
				local nm = location_ascii_name
				graph bar exp_cat1 exp_cat2 exp_cat3, over(year_id, gap(0) label(angle(45) labsize(vsmall))) stack bar(1, fcolor(midblue) lcolor(midblue)) ///
				bar(2, fcolor(stone) lcolor(stone)) bar(3, fcolor(gray) lcolor(gray)) title("`nm'") ///
				legend(label(1 "Sewer Connection") label(2 "Improved (excluding Sewer)") label(3 "Unimproved") ///
				fcolor(1 ebblue) size(vsmall) col(4)) ylabel(#5, labsize(small)) ylabel(0(.2)1) 
				pdfappend
				restore
			}
	pdffinish, view

	
**** Clean and export improved and piped gpr data in preparation to send to collaborators ****
/*local input_dir "J:\temp\wgodwin\gpr_output"
	
	adopath + "J:/WORK/10_gbd/00_library/functions"

// Prep country names to be merged on later
	get_location_metadata, location_set_id(9) clear
	keep if level >= 3
	keep location_id location_ascii_name super_region_id region_name ihme_loc_id
	tempfile codes
	save `codes', replace 

	import delimited "`input_dir'/san_imp_output_full_0408.csv", clear
	merge m:1 location_id using `codes', keep(1 3) keepusing(super_region_id region_name location_ascii_name) nogen

// Replace prevalence of 1 for high income countries for purpose of the maps
	replace gpr_mean = 1 if super_region_id==64 & region_name!="Southern Latin America"
	replace gpr_mean = 1 if location_id==354 | location_id==361 // 	plus HK and Macao
	export delimited "`input_dir'/san_imp_output_full_0408_col_map", replace

// Exclude high income countries where we assume TMREL
	drop if super_region_id==64 & region_name!="Southern Latin America"
	drop if location_id==354 | location_id==361 // 	plus HK and Macao

// save
	export delimited "`input_dir'/san_imp_output_full_0408_col", replace

// Do the same for piped sanitation
	import delimited "`input_dir'/san_piped_output_full_0408.csv", clear
	merge m:1 location_id using `codes', keep(1 3) keepusing(super_region_id region_name location_ascii_name) nogen

// Replace prevalence of 1 for high income countries for purpose of the maps
	replace gpr_mean = 1 if super_region_id==64 & region_name!="Southern Latin America"
	replace gpr_mean = 1 if location_id==354 | location_id==361 // 	plus HK and Macao
	export delimited "`input_dir'/san_piped_output_full_0408_col_map", replace

// Exclude high income countries where we assume TMREL
	drop if super_region_id==64 & region_name!="Southern Latin America"
	drop if location_id==354 | location_id==361 // 	plus HK and Macao

// save
	export delimited "`input_dir'/san_piped_output_full_0408_col", replace
