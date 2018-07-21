// File Purpose: Calculate prevalence of filter use by water source type
// Author: Leslie Mallinger/Astha KC
// Date: 4/1/10
// Edited on: 1/10/2011 (updated to reflect new file paths; specified as rough prevalence rather than good estimates)
//	2/13/2011 (no longer rough estimates, now using appropriate categorizations)
// 1/27/2013 (modified to estimate prevalence for new categories of water and sanitation)

** // Additional Comments: 

** *************************************** NEW SECTION *********************************************
** // DEBUGGING ONLY!
local prevtype "final"
local survey DHS 
local dataloc "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/data"
local graphloc "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/graphs"
local makehist 0
** *************************************************************************************************

**setup housekeeping
clear all
set more off

** open dataset with variable list, remove entries without the necessary information, and store variable data in a mata matrix
//use "`dataloc'/`survey'/varlist_`survey'", clear
use "C:/Users/wgodwin/Desktop/hwt_trial", replace		
**drop surveys with no information on flush toilets OR filter use
drop if noinfo==1

mata: `survey'_vars=st_sdata(.,("countryname", "iso3", "startyear", "endyear", "filedir", "filename", ///
	"psu", "weight", "w_srcedrnk", "w_filter", "w_boil", "w_bleach", "w_solar", "t_type"))
local maxobs = _N

** create vectors for storing results
mata: filedir = J(`maxobs', 1, "")
mata: filename = J(`maxobs', 1, "")
mata: nopsu = J(`maxobs', 1, "")
mata: noweight = J(`maxobs', 1, "")

local varlist iunimproved ipiped isrcedrnk itreat itreat2 itreat_improved itreat2_improved tr_improved untr_improved ///
	itreat_piped itreat2_piped tr_piped untr_piped itreat_unimproved itreat2_unimproved tr_unimproved untr_unimproved isanitation iflush 
foreach var of local varlist {
	mata: `var'_mean = J(`maxobs', 1, .)
	mata: `var'_sem = J(`maxobs', 1, .)
}

** loop through each file with applicable survey data
**local filenum 1
forvalues filenum = 1(1)`maxobs' {

	// create locals with file-specific information, then display it
	mata: st_local("countryname", `survey'_vars[`filenum', 1])
	mata: st_local("iso3", `survey'_vars[`filenum', 2])
	mata: st_local("startyear", `survey'_vars[`filenum', 3])
	mata: st_local("endyear", `survey'_vars[`filenum', 4])
	mata: st_local("filedir", `survey'_vars[`filenum', 5])
	mata: st_local("filename", `survey'_vars[`filenum', 6])
	mata: st_local("psu", `survey'_vars[`filenum', 7])
	mata: st_local("weight", `survey'_vars[`filenum', 8])
	mata: st_local("w_srcedrnk", `survey'_vars[`filenum', 9])
	mata: st_local("w_filter", `survey'_vars[`filenum', 10])
	mata: st_local("w_boil", `survey'_vars[`filenum', 11])
	mata: st_local("w_bleach", `survey'_vars[`filenum', 12])
	mata: st_local("w_solar", `survey'_vars[`filenum', 13])
	mata: st_local("t_type", `survey'_vars[`filenum', 14])

	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'" _newline "filename: `filename'" _newline "filenum: `filenum'"
	di "**********************************************************************************"
	
	// open file with variable labels, restrict to just the current survey and relevant variables
	//use "`dataloc'/`survey'/varlabels_`survey'_`prevtype'", clear
	use "C:/Users/wgodwin/Desktop/final", clear
	keep filename w_srcedr* t_type*
	keep if filename == "`filename'"
	
	// reshape to long format, so extracting improved and unimproved label names will be easy
	reshape long w_srcedr_o w_srcedr_s w_srcedr_i t_type_o t_type_s t_type_i, i(filename) j(type)
	
	levelsof w_srcedr_o if w_srcedr_i == 1, local(improved_water)
	levelsof w_srcedr_o if w_srcedr_i == 0, local(unimproved_water)
	levelsof w_srcedr_o if w_srcedr_i == 0.5, local(halfimproved_water)
	levelsof w_srcedr_o if w_srcedr_s == "bottled water", local(bottled_water)
	levelsof w_srcedr_o if (w_srcedr_s == "household connection"), local(piped_water) 
	
	levelsof t_type_o if t_type_i == 1, local(improved_sanitation)
	levelsof t_type_o if t_type_i == 0, local(unimproved_sanitation)
	levelsof t_type_o if t_type_i == 0.5, local(halfimproved_sanitation)
	levelsof t_type_o if (t_type_s == "pour-flush latrine" | t_type_s == "public sewer" | t_type_s == "septic system"), local(pub_sewer)
	
	// record whether bottled water is an option for water source
	tab w_srcedr_s if w_srcedr_s == "bottled water"
	if r(N) > 0 {
		local bottled 1
	}
	else {
		local bottled 0
	}
	
	//record whether piped water is an option for water source
	tab w_srcedr_s if w_srcedr_s == "household connection"
	if r(N) > 0 {
		local piped 1
	}
	else {
		local piped 0
	}
	
	//record whether sewer is an option for toilet type
	tab t_type_s if (t_type_s == "pour-flush latrine" | t_type_s == "public sewer" | t_type_s == "septic system")
	if r(N) > 0 {
		local sewer 1
	}
	else {
		local sewer 0 
		}
		
	// open actual survey file
	use `psu' `weight' `w_filter' `w_boil' `w_bleach' `w_solar' `w_srcedrnk' `t_type' using "`filedir'/`filename'", clear
	
	// save filename and country-year in matrix for observation matching in getmata step; set survey weights; save psu and weight information
	mata: filename[`filenum', 1] = "`filename'"
	if "`weight'" != "" {	// weight exists
		if "`psu'" != "" {	// weight and psu exist
			mata: nopsu[`filenum', 1] = "0"
		}
		else {	// weight exists, but not psu
			mata: nopsu[`filenum', 1] = "1"
		}
		mata: noweight[`filenum', 1] = "0"
		svyset `psu' [pweight = `weight']
	}
	else {	// weight doesn't exist
		if "`psu'" != "" {	// psu exists, but not weight
			mata: nopsu[`filenum', 1] = "0"
			svyset `psu'
		}
		else {	// neither psu nor weight exists
			mata: nopsu[`filenum', 1] = "1"
		}
		mata: noweight[`filenum', 1] = "1"
	}
	mata: st_local("nopsu", nopsu[`filenum', 1])
	mata: st_local("noweight", noweight[`filenum', 1])
	
	// check whether water filter variable exists
	if "`w_srcedrnk'" != "" & "`w_filter'" != "" & "`w_boil'" != "" & "`w_bleach'" != "" & "`w_solar'" != ""{
		** check whether variable has entries
		summarize `w_srcedrnk' 
		if r(N) == 0 {	// no entries
			display "variable empty"
		}
		else {	// variable has entries
				// transfer variable to string rather than integer
			capture decode `w_srcedrnk', gen(w_sd_lab)
			if ! _rc {	// variable has label values
				replace w_sd_lab = trim(w_sd_lab)
				
				// create variable for whether source is improved or not; fill in accordingly
				gen w_srcedrnk_i = . 
				foreach type of local improved_water {
					replace w_srcedrnk_i = 1 if w_sd_lab == "`type'"
				}
				foreach type of local unimproved_water {
					replace w_srcedrnk_i = 0 if w_sd_lab == "`type'"
				}
				foreach type of local halfimproved_water {
					replace w_srcedrnk_i = 0.5 if w_sd_lab == "`type'"
				}
				
				// special treatment for bottled water
				foreach type of local bottled_water {
					replace w_srcedrnk_i = 1 if w_sd_lab == "`type'"
				}
				
				//create variable for new category for piped water
				gen w_piped_i = .
				foreach type of local piped_water {
					replace w_piped_i = 1 if w_sd_lab == "`type'"
					replace w_piped_i = 0 if w_piped_i != 1 
					replace w_srcedrnk_i = 0 if w_piped_i == 1 /*to ensure that improved does not include piped water*/
				}
				
				//create variable for  unimproved water
				gen w_unimproved_i = .
				foreach type of local unimproved_water {
					replace w_unimproved_i = 1 if w_sd_lab == "`type'"
					replace w_unimproved_i = 0 if w_unimproved_i != 1 
				}
				
				// create variables for new water categories; fill in accordingly	
				/*households that filter their drinking water*/
				gen w_filter_i = `w_filter' 
				replace w_filter_i = 0 if w_filter_i!=1
				
				/*households that boil their drinking water*/
				gen w_boil_i = `w_boil'
				replace w_boil_i = 0 if w_boil_i!=1
				
				/*households that bleach/chlorinate their drinking water*/
				gen w_bleach_i = `w_bleach'
				replace w_bleach_i = 0 if w_bleach_i!=1
				
				/*households that use solar disinfection for drinking water*/
				gen w_solar_i = `w_solar'
				replace w_solar_i = 0 if w_solar_i!=1
				
				/*households that boil/filter their drinking water*/
				gen w_treat_i = 0 
				replace w_treat_i = 1 if (w_filter_i == 1 | w_boil_i == 1)
				
				/*households that use solar/chlorine to disinfect drinking water*/
				gen w_treat2_i = 0 
				replace w_treat2_i = 1 if (w_bleach_i == 1 | w_solar_i == 1) & w_treat_i!=1
				
				//create variables for new water categories combining water source type and HWT
				/*piped water + boil/filter*/
				gen w_piped_treat_i = . 
				replace w_piped_treat_i = 1 if (w_treat_i == 1 & w_piped_i == 1) 
				replace w_piped_treat_i = 0 if (w_treat_i == 0 & w_piped_i == 1) 
				
				/*piped water + solar/chlorine*/
				gen w_piped_treat2_i = . 
				replace w_piped_treat2_i = 1 if (w_treat2_i == 1 & w_piped_i == 1)
				replace w_piped_treat2_i = 0 if (w_treat2_i == 0 & w_piped_i == 1)
				
				/*piped water + any HWT*/
				gen w_piped_tr_i = .
				replace w_piped_tr_i = 1 if (w_piped_treat_i == 1 | w_piped_treat2_i == 1)
				replace w_piped_tr_i = 0 if (w_piped_i == 1 & w_piped_tr_i!=1 )
				
				/*piped water + untreated*/
				gen w_piped_untr_i = 0 
				replace w_piped_untr_i = 1 if (w_piped_treat_i==0 & w_piped_treat2_i==0)
				replace w_piped_untr_i = 0 if (w_piped_i==1 & w_piped_untr_i!=1 )
				
				/*other improved source + boil/filter*/
				gen w_improved_treat_i = . 
				replace w_improved_treat_i = 1 if (w_treat_i == 1 & w_srcedrnk_i == 1)
				replace w_improved_treat_i = 0 if (w_treat_i == 0 & w_srcedrnk_i == 1)
				
				/*other improved source + solar/chlorine*/
				gen w_improved_treat2_i = . 
				replace w_improved_treat2_i = 1 if (w_treat2_i == 1 & w_srcedrnk_i == 1)
				replace w_improved_treat2_i = 0 if (w_treat2_i == 0 & w_srcedrnk_i == 1)
				
				/*other improved source + any HWT*/
				gen w_improved_tr_i = .
				replace w_improved_tr_i = 1 if (w_improved_treat_i == 1 | w_improved_treat2_i == 1)
				replace w_improved_tr_i = 0 if (w_srcedrnk_i == 1 & w_improved_tr_i!=1)
				
				/*other improved source + untreated*/
				gen w_improved_untr_i = . 
				replace w_improved_untr_i = 1 if (w_improved_treat_i==0 & w_improved_treat2_i==0)
				replace w_improved_untr_i = 0 if (w_srcedrnk_i == 1 & w_improved_untr_i!=1)
				
				/*unimproved source + boil/filter*/
				gen w_unimproved_treat_i = . 
				replace w_unimproved_treat_i = 1 if (w_treat_i == 1 & w_unimproved_i == 1)
				replace w_unimproved_treat_i = 0 if (w_treat_i == 0 & w_unimproved_i == 1)
				
				/*unimproved source + solar/chlorine*/
				gen w_unimproved_treat2_i = . 
				replace w_unimproved_treat2_i = 1 if (w_treat2_i == 1 & w_unimproved_i == 1)
				replace w_unimproved_treat2_i = 0 if (w_treat2_i == 0 & w_unimproved_i == 1)
				
				
				/*unimproved source + any HWT*/
				gen w_unimproved_tr_i = . 
				replace w_unimproved_tr_i = 1 if (w_unimproved_treat_i == 1 | w_unimproved_treat2_i == 1)
				replace w_unimproved_tr_i = 0 if (w_unimproved_i == 1 & w_unimproved_tr_i!=1)
				
				/*unimproved source + untreated*/
				gen w_unimproved_untr_i = . 
				replace w_unimproved_untr_i = 1 if (w_unimproved_treat_i==0 & w_unimproved_treat2_i==0)
				replace w_unimproved_untr_i = 0 if (w_unimproved_i == 1 & w_unimproved_untr_i!=1)
				
				//estimate survey-weighted prevalence of filter or boil water i.e. combined treatment of water; save outputs of interest in matrices
				local vars piped srcedrnk unimproved treat treat2 
				foreach var of local vars {
				
				if "`nopsu'" == "1" & "`noweight'" == "1" {
					mean w_`var'_i
				}
				else {
					svy: mean w_`var'_i
				}
				mata: i`var'_mean[`filenum', 1] = st_matrix("e(b)")
				mata: i`var'_sem[`filenum', 1] = st_matrix("e(V)")
				mata: i`var'_sem[`filenum', 1] = sqrt(i`var'_sem[`filenum', 1])
				
				}
				
				//estimate survey-weighted prevalence of households that use different water sources and different HWT ; save outputs of interest in matrices
				local newcats improved piped unimproved 
				foreach cat of local newcats 	{
				if "`nopsu'" == "1" & "`noweight'" == "1" {
					mean w_`cat'_treat_i
				}
				else {
					svy: mean w_`cat'_treat_i
				}
				mata: itreat_`cat'_mean[`filenum', 1] = st_matrix("e(b)")
				mata: itreat_`cat'_sem[`filenum', 1] = st_matrix("e(V)")
				mata: itreat_`cat'_sem[`filenum', 1] = sqrt(itreat_`cat'_sem[`filenum', 1])
				
				//estimate survey-weighted prevalence of households that use solar/chlorine for disinfection and improved source (except piped) ; save outputs of interest in matrices
				if "`nopsu'" == "1" & "`noweight'" == "1" {
					mean w_`cat'_treat2_i
				}
				else {
					svy: mean w_`cat'_treat2_i
				}
				mata: itreat2_`cat'_mean[`filenum', 1] = st_matrix("e(b)")
				mata: itreat2_`cat'_sem[`filenum', 1] = st_matrix("e(V)")
				mata: itreat2_`cat'_sem[`filenum', 1] = sqrt(itreat2_`cat'_sem[`filenum', 1])
				
				//estimate survey-weighted prevalence of households that use any HWT for disinfection and improved source (except piped) ; save outputs of interest in matrices
				if "`nopsu'" == "1" & "`noweight'" == "1" {
					mean w_`cat'_tr_i
				}
				else {
					svy: mean w_`cat'_tr_i
				}
				mata: tr_`cat'_mean[`filenum', 1] = st_matrix("e(b)")
				mata: tr_`cat'_sem[`filenum', 1] = st_matrix("e(V)")
				mata: tr_`cat'_sem[`filenum', 1] = sqrt(tr_`cat'_sem[`filenum', 1])
				
				//estimate survey-weighted prevalence of households that DO NOT use filter/boil/solar/chlorine for disinfection and improved source (except piped) ; save outputs of interest in matrices
					if "`nopsu'" == "1" & "`noweight'" == "1" {
					mean w_`cat'_untr_i
				}
				else {
					svy: mean w_`cat'_untr_i
				}
				mata: untr_`cat'_mean[`filenum', 1] = st_matrix("e(b)")
				mata: untr_`cat'_sem[`filenum', 1] = st_matrix("e(V)")
				mata: untr_`cat'_sem[`filenum', 1] = sqrt(untr_`cat'_sem[`filenum', 1])
				}
				
			}
			
		}
		
	}
				
				
	// check whether toilet type variable exists
	if "`t_type'" != "" {
		** check whether variable has entries
		summarize `t_type'
		if r(N) == 0 {	// no entries
			display "variable empty"
		}
		else {	// variable has entries
			// transfer variable to string rather than integer
			capture decode `t_type', gen(t_type_lab)
			if ! _rc {
				replace t_type_lab = trim(t_type_lab)
				
				// create variable for whether type is improved or not; fill in accordingly
				gen flush_i = 0
				replace flush_i = 1 if (regexm(t_type_lab, "flush") | regexm(t_type_lab, "septic"))
				summarize flush_i
				
				if r(N) == 0 {	// all unknown
					display "variable empty"
				}
				else {
					// estimate survey-weighted prevalence of improved toilet types; save outputs of interest in matrices
					if "`nopsu'" == "1" & "`noweight'" == "1" {
						mean flush_i
					}
					else {
						svy: mean flush_i
					}
					mata: iflush_mean[`filenum', 1] = st_matrix("e(b)")
					mata: iflush_sem[`filenum', 1] = st_matrix("e(V)")
					mata: iflush_sem[`filenum', 1] = sqrt(iflush_sem[`filenum', 1])
					
				}
			}
		}
	}
}


/** open file with list of surveys - add on data for new categories
use "`dataloc'/`survey'/datfiles_`survey'", clear
getmata ipiped_mean ipiped_sem isrcedrnk_mean isrcedrnk_sem iunimproved_mean iunimproved_sem itreat_mean itreat_sem itreat2_mean itreat2_sem itreat_improved_mean itreat_improved_sem ///
	itreat2_improved_mean itreat2_improved_sem itreat_piped_mean itreat_piped_sem itreat2_piped_mean itreat2_piped_sem itreat_unimproved_mean itreat_unimproved_sem itreat2_unimproved_mean itreat2_unimproved_sem iflush_mean iflush_sem nopsu noweight, id(filename) 
capture destring startyear, replace

**save dataset
drop if nopsu == "" & noweight == ""
save "`dataloc'/`survey'/prev_newcats_`survey'.dta", replace*/

use "`dataloc'/`survey'/datfiles_`survey'", clear
getmata itreat_improved_mean itreat_improved_sem itreat2_improved_mean itreat2_improved_sem tr_improved_mean tr_improved_sem untr_improved_mean untr_improved_sem itreat_piped_mean itreat_piped_sem itreat2_piped_mean itreat2_piped_sem tr_piped_mean tr_piped_sem untr_piped_mean untr_piped_sem itreat_unimproved_mean itreat_unimproved_sem itreat2_unimproved_mean itreat2_unimproved_sem tr_unimproved_mean tr_unimproved_sem untr_unimproved_mean untr_unimproved_sem nopsu noweight, id(filename) 
capture destring startyear, replace

**check to see if categories add up to 100%
foreach source in "piped" "improved" "unimproved" {
	egen `source'_total = rowtotal(tr_`source'_mean* untr_`source'_mean*)
	}

**save dataset
drop if nopsu == "" & noweight == ""
save "`dataloc'/`survey'/prev_newcats_`survey'_08062014.dta", replace

**To verify if estimates have been generated properly - generate remaining categories**
gen iuntreated_piped = ipiped_mean - (itreat_piped_mean + itreat2_piped_mean)
gen iuntreated_improved = isrcedrnk_mean - (itreat_improved_mean + itreat2_improved_mean)
gen iuntreated_unimproved = (1 -(ipiped_mean + isrcedrnk_mean)) - (itreat_unimproved_mean + itreat2_unimproved_mean)
gen iuntreated_unimproved = iunimproved_mean - (itreat_unimproved_mean + itreat2_unimproved_mean)

**check to see if all categories add up to 100%
egen total = rowtotal(iuntreated_piped iuntreated_unimproved iuntreated_improved itreat2_unimproved_mean itreat_unimproved_mean itreat2_piped_mean itreat_piped_mean itreat2_improved_mean itreat_improved_mean)

egen total = rowtotal(iuntreated_piped iuntreated_unimproved iuntreated_improved itreat2_unimproved_mean itreat_unimproved_mean itreat2_piped_mean itreat_piped_mean itreat2_improved_mean itreat_improved_mean)
		
**graph calculated prevalence
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graphloc'/`survey'_newcats_prev.pdf"
		
		levelsof country, local(country)
		preserve
		foreach c of local country {	
		keep if country == "`c'"
		
		graph bar ipiped_mean iscredrnk_mean itreat_improved_mean itreat2_improved_mean itreat_piped_mean itreat2_piped_mean ///
		itreat_unimproved_mean itreat2_unimproved_mean, legend(off) over(startyear) ///
		showyvars yvaroptions(relabel(1 "other improved & boil/filter" 2 "other improved & solar/chlorine" 3 "piped & boil/filter" 4 "piped & solar/chlorine" ///
		5 "unimproved & boil/filter" 6 "unimproved & solar/chlorine") label(angle(45) labsize(vsmall))) asyvar nofill ytitle("Proportion") title("`c'") ///
		plotregion(fcolor(white)) graphregion(fcolor(white)) 
					
		pdfappend
		
		restore, preserve
			}
			
		pdffinish
		restore


//END OF CODE


