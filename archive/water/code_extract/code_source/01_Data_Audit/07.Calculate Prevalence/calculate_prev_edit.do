// File Name: calculate_prev.ado

// File Purpose: Calculate prevalence of safe water and sanitation for applicable surveys
// Author: Leslie Mallinger
// Date: 4/1/10
// Edited on: 1/10/2011 (updated to reflect new file paths; specified as rough prevalence rather than good estimates)
//	2/13/2011 (no longer rough estimates, now using appropriate categorizations)

** // Additional Comments: 

** define program name and syntax
capture program drop calculate_prev
program define calculate_prev

syntax, survey(string) dataloc(string) prevtype(string) makehist (integer) graphloc(string)

** *************************************** NEW SECTION *********************************************
** // DEBUGGING ONLY!
local survey dhs
local dataloc "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/DHS"
local prevtype "final"
local makehist 0
local graphloc "J:/Project/COMIND/Water and Sanitation/Graphs/Prevalence"
** *************************************************************************************************

do "J:/WORK/01_covariates/02_inputs/water_sanitation/code/01_Data_Audit/Scripts/categorize_special.ado"

** open dataset with variable list, remove entries without the necessary information, and store variable data in a mata matrix
use "`dataloc'/varlist_`survey'", clear

drop if w_srcedrnk == "NOINFO"
drop if filename=="CUB_MICS4_2010_2011_HH_Y2012M11D18.DTA"

mata: `survey'_vars=st_sdata(.,("countryname", "iso3", "startyear", "endyear", "filedir", "filename", ///
	"psu", "weight", "w_srcedrnk", "t_type"))
local maxobs = _N


** create vectors for storing results
mata: filedir = J(`maxobs', 1, "")
mata: filename = J(`maxobs', 1, "")
mata: nopsu = J(`maxobs', 1, "")
mata: noweight = J(`maxobs', 1, "")

local varlist iwater isanitation ipiped isewer icombined
foreach var of local varlist {
	mata: `var'_mean = J(`maxobs', 1, .)
	mata: `var'_sem = J(`maxobs', 1, .)
	mata: `var'_uncertain = J(`maxobs', 1, .) 
}


** initialize plot for histograms
	if "`makehist'" == "1" {
		set scheme s1color
		capture confirm file "C:/Program Files (x86)/Adobe/Acrobat 11.0/Acrobat/acrodist.exe"
		if _rc == 0 {
			do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		}
		else {
			do "C:/Users/asthak/Documents/ADO/pdfmaker_Acrobat11.do"
		}
		pdfstart using "`graphloc'/hist_`survey'.pdf"
	}


** loop through each file with applicable survey data
forvalues filenum = 1(1)`maxobs' {
local filenum 49

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
	mata: st_local("t_type", `survey'_vars[`filenum', 10])

	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'" _newline "filename: `filename'" _newline "filenum: `filenum'"
	di "**********************************************************************************"

	// open file with variable labels, restrict to just the current survey and relevant variables
	use "`dataloc'/varlabels_`survey'_`prevtype'", clear
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
	use `psu' `weight' `w_srcedrnk' `t_type' using "`filedir'/`filename'", clear
	
	// apply special categorization to surveys that need it 
	categorize_special, filename("`filename'")

	if "`filename'" == "SEN_DHS4_1999_HH_Y2008M11D03.DTA" {
		mata: st_local("w_srcedrnk", "water")
		local varlist_new water m19
		local w_srcedrnk water
	}
	if "`filename'" == "CPV_RHS_1998_WN_Y2011M01D31.DTA" {
		local varlist_new water
		local w_srcedrnk water
	}
	if regexm("`filename'", "IPUMS") {
		if $changed == 1 {
			local varlist_new `w_srcedrnk' toilet_type
			local t_type toilet_type
		}
	}
	if "`filename'" == "ECU_RHS_1989_WN.DTA" {
		replace `weight' = 1
	}
	if "`filename'" == "GTM.dta" | "`filename'" == "SVN.dta" {
		replace `psu' = 1
	}
		
	// save filename and country-year in matrix for observation matching in getmata step; set survey weights; save psu and weight information
	mata: filename[`filenum', 1] = "`filename'"
	if "`survey'" == "chns" {
		mata: nopsu[`filenum', 1] = "1"
		mata: noweight[`filenum', 1] = "1"
	}
	else if "`weight'" != "" {	// weight exists
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
	
	// check whether water source variable exists
	if "`w_srcedrnk'" != "" {
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
					replace w_piped_i = 1 if w_sd_lab == "`type'" & w_sd_lab!=""
					replace w_piped_i = 0 if w_piped_i != 1 & w_sd_lab!=""
				}
				
				//disaggregation of aggregated survey responses for water
				global filename = "`filename'"
				do "J:/WORK/01_covariates/02_inputs/water_sanitation/code/01_Data_Audit/07.Calculate Prevalence/disaggregate_categories.do"
				disaggregate_categories, filename("`filename'")

				
				// estimate survey-weighted prevalence of improved water sources; save outputs of interest in matrices
				if "`nopsu'" == "1" & "`noweight'" == "1" {
				** if "`survey'" == "chns" {
					mean w_srcedrnk_i
				}
				else {
					svy: mean w_srcedrnk_i
				}
				mata: iwater_mean[`filenum', 1] = st_matrix("e(b)")
				mata: iwater_sem[`filenum', 1] = st_matrix("e(V)")
				mata: iwater_sem[`filenum', 1] = sqrt(iwater_sem[`filenum', 1])
				
				//// estimate survey-weighted prevalence of piped water - household connection; save outputs of interest in matrices
				if "`piped'" == "1" {
				if "`nopsu'" == "1" & "`noweight'" == "1" {
				** if "`survey'" == "chns" {
					mean w_piped_i
				}
				else {
					svy: mean w_piped_i
				}
				mata: ipiped_mean[`filenum', 1] = st_matrix("e(b)")
				mata: ipiped_sem[`filenum', 1] = st_matrix("e(V)")
				mata: ipiped_sem[`filenum', 1] = sqrt(ipiped_sem[`filenum', 1])
						}
				
				// estimate proportion of sources that are of uncertain improvement status; save outputs of interest in matrices
				if "`nopsu'" == "1" & "`noweight'" == "1" {
				** if "`survey'" == "chns" {
					proportion w_srcedrnk_i
				}
				else {
					svy: proportion w_srcedrnk_i
				}
				mata: propmat = st_matrix("e(b)")
				local labels = e(label1)
				local pos: list posof ".5" in labels
				if `pos' == 0 {
					mata: iwater_uncertain[`filenum', 1] = 0
				}
				else {
					mata: iwater_uncertain[`filenum', 1] = propmat[1, `pos']
				}
				
				
				// plot histogram of improvement distribution
				if "`makehist'" == "1" {
					histogram w_srcedrnk_i, ///
						frequency ///
						color(blue) ///
						xlabel(0(0.5)1) ///
						title("`filename'") ///
						subtitle("Water")
					pdfappend
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
				gen t_type_i = .
				
				foreach type of local improved_sanitation {
					replace t_type_i = 1 if t_type_lab == "`type'"
				}
				foreach type of local unimproved_sanitation {
					replace t_type_i = 0 if t_type_lab == "`type'"
				}
				foreach type of local halfimproved_sanitation {
					replace t_type_i = 0.5 if t_type_lab == "`type'"
				}
				
				//create variable for whether toilet is connected to a public sewer
				gen t_sewer_i = . 
				
				foreach type of local pub_sewer {
					replace t_sewer_i = 1 if t_type_lab == "`type'" & t_type_lab!=""
					replace t_sewer_i = 0 if t_sewer_i!=1  & t_type_lab!=""
				}
				
				//disaggregation of aggregated survey responses for water
				global filename = "`filename'"
				do "J:/WORK/01_covariates/02_inputs/water_sanitation/code/01_Data_Audit/07.Calculate Prevalence/disaggregate_categories_san_edit.do"
				disaggregate_categories_san, filename("`filename'")
				
				summarize t_type_i
				if r(N) == 0 {	// all unknown
					display "variable empty"
				}
				else {
					// estimate survey-weighted prevalence of improved toilet types; save outputs of interest in matrices
					if "`nopsu'" == "1" & "`noweight'" == "1" {
					** if "`survey'" == "chns" {
						mean t_type_i
					}
					else {
						svy: mean t_type_i
					}
					mata: isanitation_mean[`filenum', 1] = st_matrix("e(b)")
					mata: isanitation_sem[`filenum', 1] = st_matrix("e(V)")
					mata: isanitation_sem[`filenum', 1] = sqrt(isanitation_sem[`filenum', 1])
					
					// estimate survey-weighted prevalence of toilets with sewer connection; save outputs of interest in matrices
				if "`sewer'" == "1" {
					if "`nopsu'" == "1" & "`noweight'" == "1" {
					** if "`survey'" == "chns" {
						mean t_sewer_i
					}
					else {
						svy: mean t_sewer_i
					}
					mata: isewer_mean[`filenum', 1] = st_matrix("e(b)")
					mata: isewer_sem[`filenum', 1] = st_matrix("e(V)")
					mata: isewer_sem[`filenum', 1] = sqrt(isewer_sem[`filenum', 1])
						}
					
					// estimate proportion of types that are of uncertain improvement status; save outputs of interest in matrices
					if "`nopsu'" == "1" & "`noweight'" == "1" {
					** if "`survey'" == "chns" {
						proportion t_type_i
					}
					else {
						svy: proportion t_type_i
					}
					mata: propmat = st_matrix("e(b)")
					local labels = e(label1)
					local pos: list posof ".5" in labels
					if `pos' == 0 {
						mata: isanitation_uncertain[`filenum', 1] = 0
					}
					else {
						mata: isanitation_uncertain[`filenum', 1] = propmat[1, `pos']
					}
					
					
					if "`makehist'" == "1" {
						// plot histogram of improvement distribution
						histogram t_type_i, ///
							frequency ///
							color(green) ///
							xlabel(0(0.5)1) ///
							title("`filename'") ///
							subtitle("Sanitation")
						pdfappend
					}
				}
			}
		}
	}
	
	// check whether both toilet and water are filled in
	if "`t_type'" != "" & "`w_srcedrnk'" != "" {
		** check whether variable has entries
		summarize `t_type'
		if r(N) == 0 {	// no toilet entries
			display "variable empty"
		}
		else {	// toilet has entries; check for water
			summarize `w_srcedrnk'
			if r(N) == 0 {	// no water entries
				display "variable empty"
			}
			else {	// water and toilet both have entries	
				** check whether toilet had labels
				capture confirm variable t_type_i
				if ! _rc {	// toilet had labels; check whether water had labels
					capture confirm variable w_srcedrnk_i
					if ! _rc {	// water had labels
						** create variable for whether toilet AND water and improved
						gen combined_i = 0
						replace combined_i = 1 if w_srcedrnk_i == 1 & t_type_i == 1
						summarize combined_i
						if r(N) == 0 {	// all unknown for both
							display "variable empty"
						}
						else {
							// estimate survey-weighted prevalence of improved toilet and improved water; save outputs of interest in matrices
							if "`nopsu'" == "1" & "`noweight'" == "1" {
								mean combined_i 
							}
							else {
								svy: mean combined_i 
							}
							mata: icombined_mean[`filenum', 1] = st_matrix("e(b)")
							mata: icombined_sem[`filenum', 1] = st_matrix("e(V)")
							mata: icombined_sem[`filenum', 1] = sqrt(icombined_sem[`filenum', 1])
						}
					}
				}
			}
		}
	}	
}

** close out of histogram pdf
if "`makehist'" == "1" {
	pdffinish
	capture erase "`graphloc'/hist_`survey'.log"
}

** open file with list of surveys - add on water prevalence data
if "`survey'" =="IPUMS" {
	use "`dataloc'/varlist_`survey'", clear
	drop psu weight urban w_srcedrnk t_type new_file
	}
else {

	use "`dataloc'/datfiles_`survey'", clear
	}
getmata iwater_mean iwater_sem iwater_uncertain ipiped_mean ipiped_sem isanitation_mean isanitation_sem isewer_mean isewer_sem /// 
	isanitation_uncertain icombined_mean icombined_sem nopsu noweight, id(filename)
capture destring startyear, replace

save "`dataloc'/prev_`survey'_`prevtype'.dta", replace
		
end
