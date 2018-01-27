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
local prevtype "final"
local survey DHS 
local dataloc	 "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence"
local san_dataloc "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit"
local makehist 0
**local graphloc "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/graphs"
** *************************************************************************************************

**setup housekeeping
clear all
set more off

** open dataset with variable list, remove entries without the necessary information, and store variable data in a mata matrix
use "`dataloc'/`survey'/varlist_`survey'", clear
drop if _n==7 | _n==67 /*new survey with BFA 2012-2013*/

**drop surveys with no information on flush toilets OR filter use
drop if noinfo==1

mata: `survey'_vars=st_sdata(.,("countryname", "iso3", "startyear", "endyear", "filedir", "filename", ///
	"psu", "weight", "w_hwss", "w_soap", "w_water", "t_type"))
local maxobs = _N

** create vectors for storing results
mata: filedir = J(`maxobs', 1, "")
mata: filename = J(`maxobs', 1, "")
mata: nopsu = J(`maxobs', 1, "")
mata: noweight = J(`maxobs', 1, "")

local varlist ihwws_unimproved ihwws_improved ihwws_sewer 
foreach var of local varlist {
	mata: `var'_mean = J(`maxobs', 1, .)
	mata: `var'_sem = J(`maxobs', 1, .)
}

** loop through each file with applicable survey data
forvalues filenum = 1(1)`maxobs' {
**local filenum 3

	// create locals with file-specific information, then display it
	mata: st_local("countryname", `survey'_vars[`filenum', 1])
	mata: st_local("iso3", `survey'_vars[`filenum', 2])
	mata: st_local("startyear", `survey'_vars[`filenum', 3])
	mata: st_local("endyear", `survey'_vars[`filenum', 4])
	mata: st_local("filedir", `survey'_vars[`filenum', 5])
	mata: st_local("filename", `survey'_vars[`filenum', 6])
	mata: st_local("psu", `survey'_vars[`filenum', 7])
	mata: st_local("weight", `survey'_vars[`filenum', 8])
	mata: st_local("w_hwss", `survey'_vars[`filenum', 9])
	mata: st_local("w_soap", `survey'_vars[`filenum', 10])
	mata: st_local("w_water", `survey'_vars[`filenum', 11])
	mata: st_local("t_type", `survey'_vars[`filenum', 12])

	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'" _newline "filename: `filename'" _newline "filenum: `filenum'"
	di "**********************************************************************************"
	
	// open file with variable labels, restrict to just the current survey and relevant variables
	use "`san_dataloc'/`survey'/varlabels_`survey'_`prevtype'", clear
	
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
	
	//record whether sewer is an option for toilet type
	tab t_type_s if (t_type_s == "pour-flush latrine" | t_type_s == "public sewer" | t_type_s == "septic system")
	if r(N) > 0 {
		local sewer 1
	}
	else {
		local sewer 0 
		}
		
	// open actual survey file
	use `psu' `weight' `w_hwss' `w_soap' `w_water' `t_type' using "`filedir'/`filename'", clear
	
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
				
	// check whether toilet type variable exists
	if "`t_type'" != "" & "`w_hwss'" != "" & "`w_soap'" != "" & "`w_water'"!="" {
	
		** check whether variable has entries
		capture
		summarize `w_hwss'
		if r(N) == 0 | _rc != 0 {	// no entries
			display "variable empty"
		}
		else {	// variable has entries
			// transfer variable to string rather than integer
			capture decode `t_type', gen(t_type_lab)
			if ! _rc {
				replace t_type_lab = trim(t_type_lab)
				
				
				//create variable for whether toilet is connected to a public sewer
				gen t_sewer_i = . 
				
				foreach type of local pub_sewer {
					replace t_sewer_i = 1 if t_type_lab == "`type'" & t_type_lab!=""
					replace t_sewer_i = 0 if t_sewer_i!=1 & t_type_lab!=""
				}
				
				// create variable for whether type is improved or not; fill in accordingly
				gen t_type_i = .
				
				foreach type of local improved_sanitation {
					replace t_type_i = 1 if t_type_lab == "`type'" & t_sewer_i==0
				}
				foreach type of local unimproved_sanitation {
					replace t_type_i = 0 if t_type_lab == "`type'" | t_sewer_i == 1 
				}
				
				//create variable for observed handwashing station with soap and water
				**observed handwashing station
				gen w_station_i = 1 if `w_hwss'==1
				replace w_station_i = 0 if (`w_hwss'== 0 | `w_hwss'!=1)
				replace w_station_i = . if `w_hwss' == . 
				
				**observed water at handwashing station
				gen w_water_i = 1 if `w_water'== 1
				replace w_water_i = . if `w_water' == . 
				replace w_water_i = 0 if (`w_water' == 0 | `w_water'!=1)
				
				**observed soap at handwashing station 
				gen w_soap_i = 1 if `w_soap' == 1
				replace w_soap_i = . if `w_soap' == .
				replace w_soap_i = 0 if (`w_soap' == 0 | `w_soap'!=1)
				
				**observed handwashing station + water + soap
				gen w_hwss = 1 if (w_station_i == 1 & w_water_i == 1 & w_soap_i == 1)
				replace w_hwss = 0 if w_hwss!=1
				replace w_hwss = . if (w_station_i == . | w_water_i == . | w_soap_i == .)
				
				//create variable combining handwashing and toilet type
				gen hwws_unimproved_i = 1 if (w_hwss == 1 & t_type_i == 0 & t_sewer_i == 0)
				replace hwws_unimproved_i = 0 if (w_hwss == 0 & t_type_i == 0 & t_sewer_i == 0)
				
				gen hwws_improved_i = 1 if (w_hwss == 1 & t_type_i == 1 & t_sewer_i == 0)
				replace hwws_improved_i = 0 if (w_hwss == 0 & t_type_i == 1 & t_sewer_i == 0)
				
				gen hwws_sewer_i = 1 if (w_hwss == 1 & t_type_i == 0 & t_sewer_i == 1)
				replace hwws_sewer_i = 0 if (w_hwss == 0 & t_type_i == 0 & t_sewer_i == 1)
				
				summarize hwws_unimproved_i
				if r(N) == 0 {	// all unknown
					display "variable empty"
				}
				else {
					// estimate survey-weighted prevalence of unimproved toilet + handwashing stations
					if "`nopsu'" == "1" & "`noweight'" == "1" {
						mean hwws_unimproved_i 
					}
					else {
						svy: mean hwws_unimproved_i
					}
					mata: ihwws_unimproved_mean[`filenum', 1] = st_matrix("e(b)")
					mata: ihwws_unimproved_sem[`filenum', 1] = st_matrix("e(V)")
					mata: ihwws_unimproved_sem[`filenum', 1] = sqrt(ihwws_unimproved_sem[`filenum', 1])
					
					}
					
					
				summarize hwws_sewer_i
				if r(N) == 0 {	// all unknown
					display "variable empty"
				}
				else {
					//estimate survey-weighted prevalence of sewer connected toilet + handwashing station
					if "`sewer'" == "1" {
					if "`nopsu'" == "1" & "`noweight'" == "1" {

						mean hwws_sewer_i
					}
					else {
						svy: mean hwws_sewer_i
					}
					mata: ihwws_sewer_mean[`filenum', 1] = st_matrix("e(b)")
					mata: ihwws_sewer_sem[`filenum', 1] = st_matrix("e(V)")
					mata: ihwws_sewer_sem[`filenum', 1] = sqrt(ihwws_sewer_sem[`filenum', 1])
					}
					
				summarize hwws_improved_i
				if r(N) == 0 {	// all unknown
					display "variable empty"
				}
				else {
					//estimated survey-weighted prevalence of other improved toilet + handwashing station
					if "`nopsu'" == "1" & "`noweight'" == "1" {
						mean hwws_improved_i 
					}
					else {
						svy: mean hwws_improved_i
					}
					mata: ihwws_improved_mean[`filenum', 1] = st_matrix("e(b)")
					mata: ihwws_improved_sem[`filenum', 1] = st_matrix("e(V)")
					mata: ihwws_improved_sem[`filenum', 1] = sqrt(ihwws_improved_sem[`filenum', 1]) 
					
						}
					
					}
				}
			}
		}
	}
}


** open file with list of surveys - add on data for new categories
use "`dataloc'/`survey'/varlist_`survey'", clear
drop psu weight urban w_hwss w_soap w_water t_type noinfo

getmata ihwws_unimproved_mean ihwws_unimproved_sem ihwws_sewer_mean ihwws_sewer_sem ihwws_improved_mean ihwws_improved_sem nopsu noweight, id(filename)
capture destring startyear, replace

drop if nopsu == "" & noweight == ""
drop if ihwws_unimproved_mean==. & ihwws_sewer_mean==. & ihwws_improved_mean==.

**save dataset
save "`dataloc'/`survey'/prev_san_prop_`survey'.dta", replace

**To verify if estimates have been generated properly - generate remaining categories**
gen inohwws_unimproved_mean = ihwws_sewer_mean ihwws_improved_mean
gen inohwws_piped = ipiped_mean - (itreat_piped_mean + itreat2_piped_mean)
gen iuntreated_improved = isrcedrnk_mean - (itreat_improved_mean + itreat2_improved_mean)
gen iuntreated_unimproved = (1 -(ipiped_mean + isrcedrnk_mean)) - (itreat_unimproved_mean + itreat2_unimproved_mean)
gen iuntreated_unimproved = iunimproved_mean - (itreat_unimproved_mean + itreat2_unimproved_mean)

**check to see if all categories add up to 100%
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


