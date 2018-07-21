// File Name: categorize_by_country_perminc_logistic.do

// File Purpose: Calculate prevalence of each type of water source / toilet type by permanent income value using
	// a logistic regression
// Author: Leslie Mallinger
// Date: 10/4/10
// Edited on: 1/11/2011 (updated to reflect new file paths)

// Additional Comments: 


clear all
set mem 500m
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local codes_folder "J:/Usable/Common Indicators/Country Codes"
local dhs_key_folder "J:/Project/COMIND/PERMINC/Results/DHS"
local dat_folder_new_dhs "${data_folder}/DHS"
local graph_folder "C:/Users/tomflem/Documents/Covariates/Updates/water_sanitation/model/graphs"
local perminc_type country


** customize graph scheme, initialize pdfmaker script, open pdf to print to
set scheme s1color
capture confirm file "C:/Program Files (x86)/Adobe/Acrobat 9.0/Acrobat/acrodist.exe"
if _rc == 0 do "J:/Usable/Tools/ADO/pdfmaker.do"
else do "J:/Usable/Tools/ADO/pdfmaker_Acrobat10.do"
pdfstart using "`graph_folder'/sources_by_`perminc_type'_perminc_urbelec_logistic.pdf"


** insheet excel file with list of surveys to analyze - merge to link necessary information
	// remove duplicates from file with DHS matching key, so that the merge will work
	use "`dhs_key_folder'/All_country_stats"
	drop if iso3 == "" & year == .
	tempfile DHSkey
	save `DHSkey', replace

	// open file with list of surveys, merge with DHS matching key
	use "`dat_folder_new_dhs'/datfiles_dhs", clear
	keep iso3 startyear
	rename startyear year
	duplicates drop
	merge 1:1 iso3 year using `DHSkey', keep(3) keepusing(dhscode) nogenerate
	
	// link to filename and variable names so we can open and use the survey
	rename year startyear
	merge 1:m iso3 startyear using "`dat_folder_new_dhs'/varlist_dhs", keep(1 3 4) nogenerate update
	
	// organize
	order dhscode countryname iso3 ihme_country startyear endyear filedir filename, first
	sort countryname startyear
	tostring dhscode startyear, replace
	
	
** remove entries without the necessary information, and store variable data in a mata matrix
drop if psu == "NOINFO"
drop if education == ""

** remove entries that don't work for some reason (mostly hhid's don't match)
drop if (iso3 == "CMR" & startyear == "2004") | (iso3 == "DOM" & startyear == "1991") | ///
	(iso3 == "DOM" & startyear == "2007") | (iso3 == "EGY" & startyear == "1992") | ///
	(iso3 == "ERI" & startyear == "1995") | (iso3 == "GHA" & startyear == "2008") | ///
	(iso3 == "IND" & startyear == "1998") | (iso3 == "IDN" & startyear == "1991") | ///
	(iso3 == "JOR" & startyear == "1990") | (iso3 == "MDA" & startyear == "2005") | ///
	(iso3 == "SEN" & startyear == "1997")
	
** remove entries where hhid's don't match
drop if (iso3 == "PRY" & startyear == "1990") | (iso3 == "VNM" & startyear == "1997") | ///
	(iso3 == "ZMB" & startyear == "1992")
	
** remove entries that won't converge for country_quintile
drop if (iso3 == "GAB" & startyear == "2000") | (iso3 == "HTI" & startyear == "2005") | ///
	(iso3 == "KEN" & startyear == "1993") | (iso3 == "MLI" & startyear == "2001") | ///
	(iso3 == "PER" & startyear == "2000")
	
** remove entries that won't converge for global_quintile if applicable
if "`perminc_type'" == "global" {
	drop if (iso3 == "BEN" & startyear == "1996") | (iso3 == "DOM" & startyear == "1996") | ///
		(iso3 == "EGY" & startyear == "2005") | (iso3 == "EGY" & startyear == "2008") | ///
		(iso3 == "IDN" & startyear == "2002") | (iso3 == "NGA" & startyear == "2008") | ///
		(iso3 == "UZB" & startyear == "1996")
}

** remove entries that won't converge when using electricity and urban
drop if (iso3 == "KHM" & startyear == "2000") | (iso3 == "IND" & startyear == "2005") | ///
	(iso3 == "JOR" & startyear == "1997") | (iso3 == "KGZ" & startyear == "1997") | ///
	(iso3 == "MDG" & startyear == "1997") | (iso3 == "ZWE" & startyear == "2005")
	
** remove entries without urban variable
drop if (iso3 == "ZAF" & startyear == "1998")

** remove entries that won't work now that we've changed the categorizations
drop if (iso3 == "GIN" & startyear == "1999") | (iso3 == "PER" & startyear == "1996")

drop svyver
rename svyver_real svyver
tostring svyver, replace
mata: dhs_vars=st_sdata(.,("dhscode", "countryname", "iso3", "startyear", "endyear", "filedir", ///
	"filename", "svyver", "psu", "weight", "w_srcedrnk", "t_type", "education", "electricity", "urban"))
local maxobs = _N


** create vectors for storing results
mata: filedir = J(`maxobs', 1, "")
mata: filename = J(`maxobs', 1, "")
mata: nopsu = J(`maxobs', 1, .)
mata: noweight = J(`maxobs', 1, .)



** loop through each file with applicable survey data
** local filenum 1
forvalues filenum = 1(1)`maxobs' {
	// create locals with file-specific information, then display it
	mata: st_local("dhscode", dhs_vars[`filenum', 1])
	mata: st_local("countryname", dhs_vars[`filenum', 2])
	mata: st_local("iso3", dhs_vars[`filenum', 3])
	mata: st_local("startyear", dhs_vars[`filenum', 4])
	mata: st_local("endyear", dhs_vars[`filenum', 5])
	mata: st_local("filedir", dhs_vars[`filenum', 6])
	mata: st_local("filename", dhs_vars[`filenum', 7])
	mata: st_local("svyver", dhs_vars[`filenum', 8])
	mata: st_local("psu", dhs_vars[`filenum', 9])
	mata: st_local("weight", dhs_vars[`filenum', 10])
	mata: st_local("w_srcedrnk", dhs_vars[`filenum', 11])
	mata: st_local("t_type", dhs_vars[`filenum', 12])	
	mata: st_local("education", dhs_vars[`filenum', 13])
	mata: st_local("electricity", dhs_vars[`filenum', 14])
	mata: st_local("urban", dhs_vars[`filenum', 15])

	display in red "countryname: `countryname'" _newline "filename: `filename'" _newline "filenum: `filenum'"
	
	// open file with variable labels, restrict to just the current survey and relevant variables
	use "`dat_folder_new_dhs'/varlabels_dhs_rough", clear
	keep filename w_srcedr* t_type*
	keep if filename == "`filename'"
	
	// reshape to long format, so extracting improved and unimproved label names will be easy
	reshape long w_srcedr_o w_srcedr_s w_srcedr_i t_type_o t_type_s t_type_i, i(filename) j(type)
	
	levelsof w_srcedr_o if w_srcedr_i == 1, local(improved_water)
	levelsof w_srcedr_o if w_srcedr_i == 0, local(unimproved_water)
	levelsof w_srcedr_o if w_srcedr_i == 0.5, local(halfimproved_water)
	levelsof w_srcedr_o if w_srcedr_s == "bottled water", local(bottled_water)
	levelsof t_type_o if t_type_i == 1, local(improved_sanitation)
	levelsof t_type_o if t_type_i == 0, local(unimproved_sanitation)
	levelsof t_type_o if t_type_i == 0.5, local(halfimproved_sanitation)
	
	// record whether bottled water is an option for water source
	tab w_srcedr_s if w_srcedr_s == "bottled water"
	if r(N) > 0 {
		local bottled 1
	}
	else {
		local bottled 0
	}
	
	// open survey file
	use `psu' hhid `hhmemnum' `weight' `w_srcedrnk' `t_type' `education' `electricity' `urban' ///
		using "`filedir'/`filename'", clear
	
	// standardize education variable
	gen yrs_education = .
	replace yrs_education = 0 if `education' == 0
	replace yrs_education = 1 if `education' > 0 & `education' < 6
	replace yrs_education = 2 if `education' >= 6 & `education' < 30
	
	// standardize electricity variable
	replace `electricity' = . if `electricity' != 0 & `electricity' != 1
	
	// standardize urban variable
	replace `urban' = 0 if `urban' == 2
	replace `urban' = . if `urban' != 0 & `urban' != 1
	
	// deal with situations where urban or electricity variables don't have entries
	summ `urban'
	if `r(N)' == 0 {
		local urban
	}
	summ `electricity'
	if `r(N)' == 0 {
		local electricity
	}
	
	
	** *************************************** NEW SECTION *********************************************
	// FIXME special treatment for some surveys - add code here once done debugging
	duplicates drop	
	
	** if "`filename'" == "CRUDE_INT_DHS_COL_1990_1990_HH_V23092008.DTA" {
		** duplicates drop hhid, force
	** }
	** *************************************************************************************************
	
	// merge to link to permanent income quintile
	merge 1:1 hhid using "`dhs_key_folder'/Global/Global_income_`dhscode'", ///
		keep(3) keepusing(country_p_income country_quintile global_p_income global_quintile) nogenerate
	
	// save filename and country-year in matrix for observation matching in getmata step; set survey weights; save psu and weight information
	mata: filename[`filenum', 1] = "`filename'"
	if "`survey'" != "chns" {
		if "`weight'" != "" {
			if "`psu'" != "" {
				mata: nopsu[`filenum', 1] = 0
			}
			else {
				mata: nopsu[`filenum', 1] = 1
			}
			mata: noweight[`filenum', 1] = 0
			svyset `psu' [pweight = `weight']
		}
		else {
			mata: nopsu[`filenum', 1] = 0
			mata: noweight[`filenum', 1] = 1
			svyset `psu'
		}
	}
	else {
		mata: nopsu[`filenum', 1] = 1
		mata: noweight[`filenum', 1] = 1
	}
	
	// assign households to improved/unimproved and run logistic regression
		** check whether water source variable exists
		if "`w_srcedrnk'" != "" {
			// check whether variable has entries
			summarize `w_srcedrnk'
			if r(N) == 0 {	// no entries
				display "variable empty"
			}
			else {	// variable has entries
				** transfer variable to string rather than integer
				decode `w_srcedrnk', gen(w_sd_lab)
				replace w_sd_lab = trim(w_sd_lab)
				
				** create variable for whether source is improved or not; fill in accordingly
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
				
				** special treatment for bottled water
				if "`w_srceothr'" != "" & `bottled' == 1 {  // need to classify bottled water more specifically
					// check whether other source variable has entries
					summarize `w_srceothr'
					if r(N) == 0 {  // no entries
						display "variable empty"
						replace w_srcedrnk_i = 0.5 if w_sd_lab == `bottled_water'
					}
					else {  // variable has entries
						** transfer variable to string rather than integer
						decode `w_srceothr', gen(w_so_lab)
						replace w_so_lab = trim(w_so_lab)
						
						** fill in whether source is improved or not
						foreach type of local bottled_water {
							foreach type2 of local improved_waterothr {
								replace w_srcedrnk_i = 1 if w_sd_lab == "`type'" & w_so_lab == "`type2'"
							}
							foreach type2 of local unimproved_waterothr {
								replace w_srcedrnk_i = 0 if w_sd_lab == "`type'" & w_so_lab == "`type2'"
							}
							foreach type2 of local halfimproved_waterothr {
								replace w_srcedrnk_i = 0.5 if w_sd_lab == "`type'" & w_so_lab == "`type2'"
							}
							foreach type2 of local bottled_waterothr {
								replace w_srcedrnk_i = 0.5 if w_sd_lab == "`type'" & w_so_lab == "`type'"
							}
						}
					}
				}
				else {  // no additional information available
					foreach type of local bottled_water {
						replace w_srcedrnk_i = 0.5 if w_sd_lab == "`type'"
					}
				}
	
				** run regression on households with known status
				svy: logistic w_srcedrnk_i `perminc_type'_quintile yrs_education `urban' `electricity' ///
					if (w_srcedrnk_i == 0 | w_srcedrnk_i == 1), coef
				predict w_srcedrnk_i_pred
			}
		}
		
		** check whether toilet type variable exists
		if "`t_type'" != "" {
			// check whether variable has entries
			summarize `t_type'
			if r(N) == 0 {	// no entries
				display "variable empty"
			}
			else {	// variable has entries
				** transfer variable to string rather than integer
				decode `t_type', gen(t_type_lab)
				replace t_type_lab = trim(t_type_lab)
				
				** create variable for whether type is improved or not; fill in accordingly
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
				
				** run regression on households with known status
				svy: logistic t_type_i `perminc_type'_quintile yrs_education `urban' `electricity' ///
					if (t_type_i == 0 | t_type_i == 1), coef
				predict t_type_i_pred
			}
		}
	
	// calculate and plot mean probability of improved, by type
	local vars w_srcedrnk t_type
	** local var w_srcedrnk
	foreach var of local vars {
		preserve 
			// extract value label name and create mata vectors to link label number with label string
			local labname: value label ``var''
			matalabel `labname', generate(labname labnum labstring)
			
			// create tempfile with key linking label number with label string
			clear
			getmata labnum labstring
			tempfile labkey
			save `labkey', replace
		restore
		
		preserve
			if "`var'" == "w_srcedrnk" {
				foreach type of local bottled_water {
					replace `var'_i = . if w_sd_lab == "`type'"
				}
			}
			keep ``var'' `var'_i
			drop if ``var'' == .
			duplicates drop
			rename ``var'' labnum
			label drop `labname'
			
			tempfile impkey
			save `impkey', replace			
		restore
	
		tempfile temp
		save `temp', replace
			// drop label so mean will report category number rather than name (this gets around 
			// character limits in the locals that it stores afterwards)
			label drop `labname'
		
			// perform calculation and save results
			svy: mean `var'_i_pred, over(``var'')
			mata: meanmat = st_matrix("e(b)")
			local meancats = e(over_labels)
			local numcats = e(N_over)
			mata: meancats = J(`numcats', 1, .)
			forvalues cat = 1(1)`numcats' {
				local catnum: word `cat' of `meancats'
				mata: meancats[`cat', 1] = `catnum'
			}

			** modify matrix with means to be more a column vector rather than a row vector
			mata: meanmat = colshape(meanmat, 1)
			
			** link matrix with means to label numbers and label strings
			clear
			getmata labnum=meancats mean=meanmat
			merge 1:1 labnum using `labkey', keep(3) nogenerate
			merge 1:1 labnum using `impkey', keep(3) nogenerate
			
			** remove commas from label names
			replace labstring = subinstr(labstring, ",", "", .)
			
			** make labstring a numeric variable for plotting
			encode labstring, gen(category)
		
			** graph proportion by 
			graph twoway bar mean category, ///
				horizontal	///
				title("`countryname' `startyear'") ///
				subtitle("`var'") ///
				ylabel(1(1)`numcats', valuelabel angle(horizontal) labsize(small)) ///
				xlabel(0(0.2)1) ///
				xtitle("Probability of Improved") ///
			|| scatter category mean, ///
				mlabel(`var'_i) ///
			|| function y = 0.5, horizontal range(0 `numcats')
			pdfappend
			
			** calculate mean probability for improved and unimproved, leaving ambiguous categories intact
			preserve
				keep if `var'_i != 1 & `var'_i != 0
				tempfile ambiguous
				save `ambiguous', replace
			restore
			
			collapse mean if `var'_i == 0 | `var'_i == 1, by(`var'_i)
			append using `ambiguous'
			
			** create variables for distance from improved and unimproved
			levelsof mean if `var'_i == 1, local(improved_mean)
			levelsof mean if `var'_i == 0, local(unimproved_mean)
			gen dist_improved = abs(mean - `improved_mean')
			gen dist_unimproved = abs(mean - `unimproved_mean')
			
			** reduce to ambiguous categories and update improvement status
			keep if `var'_i != 1 & `var'_i != 0
			replace `var'_i = 0 if dist_improved > dist_unimproved
			replace `var'_i = 1 if dist_unimproved > dist_improved
			
			** clean up and save
			keep `var'_i labstring
			gen filedir = "`filedir'"
			gen filename = "`filename'"
			gen startyear = "`startyear'"
			gen iso3 = "`iso3'"
			tempfile `iso3'_`startyear'_`var'
			save ``iso3'_`startyear'_`var'', replace
		use `temp', clear
	}
}
pdffinish

clear
forvalues filenum = 1(1)`maxobs' {
	// create locals with file-specific information
	mata: st_local("iso3", dhs_vars[`filenum', 3])
	mata: st_local("startyear", dhs_vars[`filenum', 4])
	
	// append tempfiles with designations for ambiguous categories
	capture append using ``iso3'_`startyear'_w_srcedrnk'
	capture append using ``iso3'_`startyear'_t_type'
}


preserve
keep if w_srcedrnk_i != .
drop t_type_i
save "`dat_folder_new_dhs'/ambiguous_water_results", replace
restore
keep if t_type_i != .
drop w_srcedrnk_i
save "`dat_folder_new_dhs'/ambiguous_sanitation_results", replace


