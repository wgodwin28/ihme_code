// File Name: calculate_prev.ado

// File Purpose: Calculate prevalence of filter use and toilets with flush or sewer connection. 
// Author: Leslie Mallinger/Astha KC
// Date: 4/1/10
// Edited on: 1/10/2011 (updated to reflect new file paths; specified as rough prevalence rather than good estimates)
//	2/13/2011 (no longer rough estimates, now using appropriate categorizations)
// 1/27/2013 (modified to estimate prevalence for new categories of water and sanitation)

** // Additional Comments: 

** *************************************** NEW SECTION *********************************************
** // DEBUGGING ONLY!
local survey DHS 
local dataloc "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/data"
local graphloc "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/graphs"
local makehist 0
** *************************************************************************************************

**setup housekeeping
clear all
set more off

** open dataset with variable list, remove entries without the necessary information, and store variable data in a mata matrix
use "`dataloc'/`survey'/varlist_`survey'", clear

**drop surveys with no information on flush toilets OR filter use
drop if noinfo==1

mata: `survey'_vars=st_sdata(.,("countryname", "iso3", "startyear", "endyear", "filedir", "filename", ///
	"psu", "weight", "w_filter", "w_boil", "t_type"))
local maxobs = _N

** create vectors for storing results
mata: filedir = J(`maxobs', 1, "")
mata: filename = J(`maxobs', 1, "")
mata: nopsu = J(`maxobs', 1, "")
mata: noweight = J(`maxobs', 1, "")

local varlist ifilter iboil itreat iflush 
foreach var of local varlist {
	mata: `var'_mean = J(`maxobs', 1, .)
	mata: `var'_sem = J(`maxobs', 1, .)
}

** loop through each file with applicable survey data
local filenum 1
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
	mata: st_local("w_filter", `survey'_vars[`filenum', 9])
	mata: st_local("w_boil", `survey'_vars[`filenum', 10])
	mata: st_local("t_type", `survey'_vars[`filenum', 11])

	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'" _newline "filename: `filename'" _newline "filenum: `filenum'"
	di "**********************************************************************************"

	// open actual survey file
	use `psu' `weight' `w_filter' `w_boil' `t_type' using "`filedir'/`filename'", clear
	
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
	if "`w_filter'" != "" & "`w_boil'" != "" {
		** check whether variable has entries
		summarize `w_filter'
		if r(N) == 0 {	// no entries
			display "variable empty"
		}
		else {	// variable has entries
				// create variable for whether households boil/filter/treat water; fill in accordingly
				gen w_filter_i = `w_filter' 
				replace w_filter_i = 0 if w_filter_i!=1
				
				gen w_boil_i = `w_boil'
				replace w_boil_i = 0 if w_boil_i!=1
				
				gen w_treat_i = 0 
				replace w_treat_i = 1 if (w_filter_i == 1 | w_boil_i == 1)
				
				// estimate survey-weighted prevalence for filtering water; save outputs of interest in matrices
				if "`nopsu'" == "1" & "`noweight'" == "1" {
					mean w_filter_i
				}
				else {
					svy: mean w_filter_i
				}
				mata: ifilter_mean[`filenum', 1] = st_matrix("e(b)")
				mata: ifilter_sem[`filenum', 1] = st_matrix("e(V)")
				mata: ifilter_sem[`filenum', 1] = sqrt(ifilter_sem[`filenum', 1])
				
				//estimate survey-weighted prevalence of boiling water; save outputs of interest in matrices
				if "`nopsu'" == "1" & "`noweight'" == "1" {
					mean w_boil_i
				}
				else {
					svy: mean w_boil_i
				}
				mata: iboil_mean[`filenum', 1] = st_matrix("e(b)")
				mata: iboil_sem[`filenum', 1] = st_matrix("e(V)")
				mata: iboil_sem[`filenum', 1] = sqrt(ifilter_sem[`filenum', 1])
				
				//estimate survey-weighted prevalence of filter or boil water i.e. combined treatment of water; save outputs of interest in matrices
				
				if "`nopsu'" == "1" & "`noweight'" == "1" {
					mean w_treat_i
				}
				else {
					svy: mean w_treat_i
				}
				mata: itreat_mean[`filenum', 1] = st_matrix("e(b)")
				mata: itreat_sem[`filenum', 1] = st_matrix("e(V)")
				mata: itreat_sem[`filenum', 1] = sqrt(ifilter_sem[`filenum', 1])
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

** open file with list of surveys - add on filter use and sewer connection data
use "`dataloc'/`survey'/varlist_`survey'", clear
getmata ifilter_mean ifilter_sem iboil_mean iboil_sem itreat_mean itreat_sem iflush_mean iflush_sem nopsu noweight, id(filename)
capture destring startyear, replace

use "`dataloc'/`survey'/datfiles_`survey'", clear
getmata ifilter_mean ifilter_sem iboil_mean iboil_sem itreat_mean itreat_sem iflush_mean iflush_sem nopsu noweight, id(filename)
capture destring startyear, replace

**save dataset
save "`dataloc'/`survey'/prev_`survey'.dta", replace
		
**graph calculated prevalence
		do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		pdfstart using "`graphloc'/`survey'_prev.pdf"
		gen countryyear = country + endyear 
		
		levelsof countryyear, local(cy)
		preserve
		foreach c of local cy {	
		keep if countryyear == "`c'"
		
		graph bar ifilter_mean iboil_mean itreat_mean iflush_mean, title("`c'") 
		pdfappend
					
		restore, preserve
			}
			
		pdffinish
		restore


//END OF CODE


