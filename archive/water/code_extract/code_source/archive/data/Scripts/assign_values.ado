// File Name: assign_values.ado

// File Purpose: Assign improved/unimproved values to each household; export reduced survey
// Author: Leslie Mallinger
// Date: 1/14/2011 (modified from calculate_rough_prev.ado)
// Edited on: 

// Additional Comments: 


** ** define program name and syntax
	capture program drop assign_values
	program define assign_values

	syntax, survey(string) newdataloc(string)


** *************************************** NEW SECTION *********************************************
// DEBUGGING ONLY!
** local survey dhs4
** local newdataloc "J:/Project/COMIND/Water and Sanitation/Data Audit/Data/DHS"
** *************************************************************************************************


** open dataset with variable list, remove entries without the necessary information, and store variable data in a mata matrix
use "`newdataloc'/varlist_`survey'", clear

drop if psu == "NOINFO"
** drop if psu == ""
** drop if hhmemnum == ""
** drop if weight == ""
** drop if w_srcedrnk == ""
** drop if t_type == ""

capture tostring startyear, replace

mata: `survey'_vars=st_sdata(.,("countryname", "iso3", "startyear", "endyear", "filedir", "filename", "psu", "hhmemnum", /// 
	"weight", "w_srcedrnk", "t_type", "w_srceothr"))
local maxobs = _N


** create vectors for storing results
mata: filedir = J(`maxobs', 1, "")
mata: filename = J(`maxobs', 1, "")
mata: nopsu = J(`maxobs', 1, .)
mata: noweight = J(`maxobs', 1, .)

local varlist iwater isanitation
foreach var of local varlist {
	mata: `var'_mean = J(`maxobs', 1, .)
	mata: `var'_sem = J(`maxobs', 1, .)
	mata: `var'_uncertain = J(`maxobs', 1, .)
}


** loop through each file with applicable survey data
forvalues filenum = 1(1)`maxobs' {
	// create locals with file-specific information, then display it
	mata: st_local("countryname", `survey'_vars[`filenum', 1])
	mata: st_local("iso3", `survey'_vars[`filenum', 2])
	mata: st_local("startyear", `survey'_vars[`filenum', 3])
	mata: st_local("endyear", `survey'_vars[`filenum', 4])
	mata: st_local("filedir", `survey'_vars[`filenum', 5])
	mata: st_local("filename", `survey'_vars[`filenum', 6])
	mata: st_local("psu", `survey'_vars[`filenum', 7])
	mata: st_local("hhmemnum", `survey'_vars[`filenum', 8])
	mata: st_local("weight", `survey'_vars[`filenum', 9])
	mata: st_local("w_srcedrnk", `survey'_vars[`filenum', 10])
	mata: st_local("t_type", `survey'_vars[`filenum', 11])
	mata: st_local("w_srceothr", `survey'_vars[`filenum', 12])

	display in red "countryname: `countryname'" _newline "filename: `filename'" _newline "filenum: `filenum'"

	// open file with variable labels, restrict to just the current survey and relevant variables
	use "`newdataloc'/varlabels_`survey'", clear
	keep filename w_srcedr* t_type* w_srceo*
	keep if filename == "`filename'"
	
	// reshape to long format, so extracting improved and unimproved label names will be easy
	reshape long w_srcedr_o w_srcedr_s w_srcedr_i t_type_o t_type_s t_type_i w_srceo_o w_srceo_s /// 
		w_srceo_i, i(filename) j(type)
	
	levelsof w_srcedr_o if w_srcedr_i == 1, local(improved_water)
	levelsof w_srcedr_o if w_srcedr_i == 0, local(unimproved_water)
	levelsof w_srcedr_o if w_srcedr_i == 0.5, local(halfimproved_water)
	levelsof w_srcedr_o if w_srcedr_s == "bottled water", local(bottled_water)
	levelsof t_type_o if t_type_i == 1, local(improved_sanitation)
	levelsof t_type_o if t_type_i == 0, local(unimproved_sanitation)
	levelsof t_type_o if t_type_i == 0.5, local(halfimproved_sanitation)
	levelsof w_srceo_o if w_srceo_i == 1, local(improved_waterothr)
	levelsof w_srceo_o if w_srceo_i == 0, local(unimproved_waterothr)
	levelsof w_srceo_o if w_srceo_i == 0.5, local(halfimproved_waterothr)
	levelsof w_srceo_o if w_srceo_s == "bottled water", local(bottled_waterothr)
	
	** // record whether bottled water is an option for water source
	** tab w_srcedr_s if w_srcedr_s == "bottled water"
	** if r(N) > 0 {
		** local bottled 1
	** }
	** else {
		** local bottled 0
	** }
	
	// open actual survey file
	capture use hhid `w_srcedrnk' `t_type' `w_srceothr' using "`filedir'/`filename'", clear
	if _rc != 0 {
		use `w_srcedrnk' `t_type' `w_srceothr' using "`filedir'/`filename'", clear
	}
	
	// special treatment for DHS Senegal, 1999: skip pattern for water source
	if "`filename'" == "SEN_DHS4_1999_HH_Y2008M11D03.DTA" {
		display "Senegal!"
		
		** standardize labels
		replace m15 = 11 if m15 == 12
		
		** make new variable that combines the information from m15, m17, m18
		gen water = .
		replace water = m15 if m17 == 1
		replace water = m18 if m17 == 2
		replace water = m18 if m17 == . & m18 != .
		
		** apply label
		label copy m18 waterl
		label define waterl 13 "robinet public", add
		label values water waterl
		
		** drop original variables
		drop m17 m18
		
		** change local with variable list
		mata: st_local("w_srcedrnk", "water")
		local varlist_new water m19
		local w_srcedrnk water
	}

	// special treatment for RHS Cape Verde, 1998: skip pattern for water source
	if "`filename'" == "CPV_RHS_1998_WN.DTA" {
		display "Cape Verde!"
		
		** make new variable that combines the information from p16d, p18d, p19d
		gen water = .
		replace water = p16d if p18d == 1	// other water and drinking water are the same
		replace water = p19d if p18d == 2	// other water and drinking water are different
		replace water = p19d if p18d == . & p19d != .
		label values water LABAU
		
		** drop original variables
		drop p18d p19d
		
		** change local with variable list
		mata: st_local("w_srcedrnk", "water")
		local varlist_new water
		local w_srcedrnk water
	}

	// special treatment for RHS Honduras, 2001: no label in dataset
	if "`filename'" == "HND_RHS_2001_WN.DTA" {
		label define p1agua 1 "Llave dentro de la vivienda" ///
			2 "Llave fuera de la vivienda pero dentro de la propiedad" /// 
			3 "Llave fuera de la propiedad a menos de 100 M" /// 
			4 "Llave fuera de la propiedad a 100 M o mas" /// 
			5 "Fuente natural: rio, quebrada, naciente, vertiente, lago" /// 
			6 "Pozo malacate (sin bomba)" /// 
			7 "Pozo con bomba (electrica o manual)" /// 
			8 "La compran/carro cisterna" /// 
			9 "Fuente de agua protegida" /// 
			10 "Manguera (fuente no especificada)" /// 
			11 "Se la regalan" /// 
			88 "Otro"
		label values p1agua p1agua
		
		label define p3sshh 1 "Inodoro(lavable)" ///
			2 "Letrina hidraulica/tasa campesina" ///
			3 "Letrina de fosa simple" ///
			4 "No tiene/al aire libre" ///
			8 "Otro"
		label values p3sshh p3sshh
	}

	// special treatment for RHS Belize, 1991: no label in dataset
	if "`filename'" == "BLZ_RHS_1991_WN.DTA" {
		label define H100 1 "Piped into residence" ///
			2 "Piped into yard or plot" ///
			3 "Public tap" ///
			4 "Well with handpump" ///
			5 "Well without handpump" ///
			6 "River, spring, surface water" ///
			7 "Tanker truck, other vendor" ///
			8 "Vat, drum" ///
			9 "Other (specify)"
		label values H100 H100
		
		label define H101 1 "Flush" ///
			2 "Bucket" ///
			3 "Pit latrine" ///
			4 "No facilities" ///
			8 "Other (specify)"
		label values H101 H101
	}

	// special treatment for RHS Belize, 1999: no label in dataset
	if "`filename'" == "BLZ_RHS_1999_WN.DTA" {
		label define H004 1 "Private, piped into dwelling" ///
			2 "Private vat / drum / well not piped" ///
			3 "Public piped into dwelling" ///
			4 "Public piped into yard" ///
			5 "Public standpipe or handpump"
		label values H004 H004
		
		label define H005 1 "W.C. linked to WASA sewer system" ///
			2 "W.C. linked to septic tank" ///
			3 "Pit latrine, ventilated and elevated" ///
			4 "Pit latrine, ventilated and not elevated" ///
			5 "Pit latrine, ventilated compost"
		label values H005 H005
	}

	// special treatment for RHS Ecuador, 1989: no weights in file
	if "`filename'" == "ECU_RHS_1989_WN.DTA" {
		replace `weight' = 1
	}
	
	// special treatment for WHS Guatemala, WHS Slovenia: no PSU in file
	if "`filename'" == "GTM.dta" | "`filename'" == "SVN.dta" {
		replace `psu' = 1
	}
	
	
	// check whether water source variable exists
	if "`w_srcedrnk'" != "" {
		** check whether variable has entries
		summarize `w_srcedrnk'
		if r(N) == 0 {	// no entries
			display "variable empty"
		}
		else {	// variable has entries
			// transfer variable to string rather than integer
			decode `w_srcedrnk', gen(w_sd_lab)
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
			foreach type of local bottled_water {
				replace w_srcedrnk_i = 1 if w_sd_lab == "`type'"
			}
			
			** // special treatment for bottled water
			** if "`w_srceothr'" != "" & `bottled' == 1 {  // need to classify bottled water more specifically
				** ** check whether other source variable has entries
				** summarize `w_srceothr'
				** if r(N) == 0 {  // no entries
					** display "variable empty"
					** replace w_srcedrnk_i = 0.5 if w_sd_lab == `bottled_water'
				** }
				** else {  // variable has entries
					** // transfer variable to string rather than integer
					** decode `w_srceothr', gen(w_so_lab)
					** replace w_so_lab = trim(w_so_lab)
					
					** // fill in whether source is improved or not
					** foreach type of local bottled_water {
						** foreach type2 of local improved_waterothr {
							** replace w_srcedrnk_i = 1 if w_sd_lab == "`type'" & w_so_lab == "`type2'"
						** }
						** foreach type2 of local unimproved_waterothr {
							** replace w_srcedrnk_i = 0 if w_sd_lab == "`type'" & w_so_lab == "`type2'"
						** }
						** foreach type2 of local halfimproved_waterothr {
							** replace w_srcedrnk_i = 0.5 if w_sd_lab == "`type'" & w_so_lab == "`type2'"
						** }
						** foreach type2 of local bottled_waterothr {
							** replace w_srcedrnk_i = 0.5 if w_sd_lab == "`type'" & w_so_lab == "`type'"
						** }
					** }
				** }
			** }
			** else {  // no additional information available
				** foreach type of local bottled_water {
					** replace w_srcedrnk_i = 0.5 if w_sd_lab == "`type'"
				** }
			** }
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
			decode `t_type', gen(t_type_lab)
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
		}
	}
	
	
	// save file with categorization by household
	save "`newdataloc'/Categorized/`iso3'_`startyear'", replace	
}



		

end


