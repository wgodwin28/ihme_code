// File Name: lookfor_vars_rhs.do

// File Purpose: Look for appropriate variables in RHS surveys
// Author: Leslie Mallinger
// Date: 4/23/10 (modified from "J:\Project\COMIND\Water and Sanitation\Data Audit\Code\lookfor_vars_dhs1.do")
// Edited on: 1/4/2011 (updated to reflect new file paths)

// Additional Comments: 


clear all
set mem 500m
set maxvar 8000
set more off
capture log close


** create locals for relevant files and folders
local dat_folder_new_rhs "${data_folder}/RHS"


** open dataset and store data in a mata matrix
use "`dat_folder_new_rhs'/datfiles_rhs", clear
mata: files=st_sdata(.,("countryname", "filedir", "filename"))
local maxobs = _N


** create a vector for each of the variables of interest
local vars psu weight urban w_srcedrnk t_type
foreach var of local vars {
	mata: `var' = J(`maxobs', 1, "")
}


** loop through survey files, looking for and saving relevant variables in each one
forvalues filenum = 1(1)`maxobs' {
	// save countryname and filename as locals, then print to keep track of position in the loop
	mata: st_local("countryname", files[`filenum', 1])
	mata: st_local("filedir", files[`filenum', 2])
	mata: st_local("filename", files[`filenum', 3])
	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'" _newline "filename: `filename'" _newline "filenum: `filenum'"
	di "**********************************************************************************"
	
	// open file (only first 50 observations for speed), then lookfor variables of interest and save in appropriate vector
	use "`filedir'/`filename'" if _n < 50, clear
	
		// primary sampling unit
		lookfor "primary sampling unit" "psu" "grappe"  "paquete"
		mata: psu[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "cluster number" "upm" "primaria" "segment" "edno" "ed_no" "region"
			mata: psu[`filenum', 1] = "`r(varlist)'"
		}
		
		// sample weight
		lookfor "sample weight" "pesomef" "poids" "household weight"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "weight" "ponder" "peso" "factor"
			mata: weight[`filenum', 1] = "`r(varlist)'"
		}
		
		// urban/rural
		lookfor "type of place of residence" "urban" "area"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "milieu" "urbrur" "strata"
			mata: urban[`filenum', 1] = "`r(varlist)'"
		}
		
		// source of drinking water
		lookfor "drinking water" "fuente principal" "donde obtienen agua"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "potable" "abastecimiento" "agua para beber" "agua beber" "servicio de agua" /// 
				"obtiene el agua" "tipo de agua"
			mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
			if "`r(varlist)'" == "" {
				lookfor "water" "agua" "eau"
				mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
			}
		}
		
		// type of toilet facility
		lookfor "type of toilet" "sanitario" "servicio higienico" "cuarto de" "fezes"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "toilet" "toilettes" "higi�nico" "desague de aguas servidas"
			mata: t_type[`filenum', 1] = "`r(varlist)'"
		}
}


** move variables from Mata into Stata datset
use "`dat_folder_new_rhs'/datfiles_rhs", clear
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
compress
save "`dat_folder_new_rhs'/varlist_temp_rhs", replace
	
	
use "`dat_folder_new_rhs'/varlist_temp_rhs", clear

	
** clean up entries with more than one variable listed
	// psu
	replace psu = "psu" if regexm(psu, "psu")
	replace psu = "" if iso3 == "CPV" & startyear == "1998"
	replace psu = "hbcd" if iso3 == "CZE" & startyear == "1993"
	replace psu = "segment" if iso3 == "ECU" & (startyear == "1989" | startyear == "1994" | startyear == "1999" | startyear == "2004")
	replace psu = "mpaquete" if iso3 == "GTM" & (startyear == "2002" | startyear == "2008")
	replace psu = "sector" if iso3 == "HND" & (startyear == "1991" | startyear == "1996")
	replace psu = "segmento" if iso3 == "HND" & startyear == "2001"
	replace psu = "region" if iso3 == "JAM" & startyear == "1993"
	replace psu = "parish" if iso3 == "JAM" & startyear == "1997"
	replace psu = "par" if iso3 == "JAM" & startyear == "2002"
	replace psu = "raion" if iso3 == "MDA" & startyear == "1997"
	replace psu = "noupal" if iso3 == "MOZ" & startyear == "2001"
	replace psu = "seccen" if iso3 == "NIC" & startyear == "1992"
	replace psu = "segme" if iso3 == "NIC" & startyear == "2006"
	replace psu = "segment" if iso3 == "PRI" & startyear == "1995"
	replace psu = "emp" if iso3 == "PRY" & (startyear == "1995" | startyear == "1998")
	replace psu = "n_congl" if iso3 == "PRY" & (startyear == "2004" | startyear == "2008")
	replace psu = "qn100" if iso3 == "SLV" & startyear == "1988"
	replace psu = "segm" if iso3 == "SLV" & startyear == "1993"
	replace psu = "" if iso3 == "UKR" & startyear == "1999"
	bro psu if regexm(psu, " ")
		** 
	
	// weight
	replace weight = "pesomef" if regexm(weight, "pesomef")
	replace weight = "dwt" if iso3 == "ALB" & startyear == "2002"
	replace weight = "" if iso3 == "BLZ" & startyear == "1999"
	replace weight = "wt" if iso3 == "CZE" & startyear == "1993"
	replace weight = "wt" if iso3 == "GEO" & (startyear == "1999" | startyear == "2005")
	replace weight = "" if iso3 == "HND" & startyear == "1991"
	replace weight = "wt" if iso3 == "JAM" & (startyear == "1993" | startyear == "2002")
	replace weight = "wt" if iso3 == "MDA" & startyear == "1997" 
	replace weight = "wt" if iso3 == "MOZ" & startyear == "2001"
	replace weight = "wt" if iso3 == "NIC" & startyear == "1992"
	replace weight = "" if iso3 == "UKR" & startyear == "1999"
	bro weight if regexm(weight, " ")
		** 
	
	// urban
	replace urban = "area" if regexm(urban, "area")
	replace urban = "strata" if (iso3 == "ALB" & startyear == "2002") | (iso3 == "NIC" & startyear == "1992") ///
		| (iso3 == "BLZ" & startyear == "1991")
	replace urban = "mharea" if iso3 == "GTM" & startyear == "2002"
	replace urban = "estrato" if iso3 == "HND" & startyear == "1996"
	replace urban = "" if (iso3 == "CRI" & startyear == "1993") | (iso3 == "PRI" & startyear == "1995")
	bro urban if regexm(urban, " ")
		** missing entries for CRI 1993, PRI 1995
		** SOME ENTRIES MISSING -- FIXME if you use this variable
	
	// w_srcedrnk
	replace w_srcedrnk = "H004" if iso3 == "BLZ" & startyear == "1999"
	replace w_srcedrnk = "p16d p18d p19d" if iso3 == "CPV" & startyear == "1998"
	replace w_srcedrnk = "" if iso3 == "CRI" & (startyear == "1991" | startyear == "1993")
	replace w_srcedrnk = "" if iso3 == "GEO" & startyear == "1999"
	replace w_srcedrnk = "vagua1" if iso3 == "HND" & startyear == "1991"
	replace w_srcedrnk = "" if iso3 == "JAM" & startyear == "1993"
	replace w_srcedrnk = "q112" if iso3 == "JAM" & startyear == "1997"
	replace w_srcedrnk = "q114" if iso3 == "JAM" & startyear == "2002"
	replace w_srcedrnk = "p101agua" if iso3 == "NIC" & startyear == "1992"
	replace w_srcedrnk = "p1517" if iso3 == "PRI" & startyear == "1995"
	replace w_srcedrnk = "p1100agu" if iso3 == "SLV" & startyear == "1998"
	replace w_srcedrnk = "p1209agu" if iso3 == "SLV" & startyear == "2002"
	replace w_srcedrnk = "p1103agu" if iso3 == "SLV" & startyear == "2008"
	bro w_srcedrnk if regexm(w_srcedrnk, " ")
		** missing entries for CRI 1991, CRI 1993, MDA 1997, MOZ 2001, UKR 1999
		** no labels for HND 2001, JAM 1997
	
	// t_type
	replace t_type = "" if iso3 == "ALB" & startyear == "2002"
	replace t_type = "h101" if iso3 == "BLZ" & startyear == "1991"
	replace t_type = "H005" if iso3 == "BLZ" & startyear == "1999"
	replace t_type = "" if iso3 == "CPV" & startyear == "1998"
	replace t_type = "tiposshh" if iso3 == "ECU" & startyear == "1999"
	replace t_type = "p1410ssh" if iso3 == "ECU" & startyear == "2004"
	replace t_type = "" if iso3 == "GEO" & startyear == "1999"
	replace t_type = "q801" if iso3 == "GEO" & startyear == "2005"
	replace t_type = "vsanit2" if iso3 == "HND" & startyear == "1991"
	replace t_type = "p15sshh" if iso3 == "HND" & startyear == "1996"
	replace t_type = "q113" if iso3 == "JAM" & startyear == "1997"
	replace t_type = "" if iso3 == "MDA" & startyear == "1997"
	replace t_type = "p105ssan" if iso3 == "NIC" & startyear == "1992"
	replace t_type = "" if iso3 == "SLV" & startyear == "1998"
	replace t_type = "p1217ssh" if iso3 == "SLV" & startyear == "2002"
	replace t_type = "sshh" if iso3 == "SLV" & startyear == "2008"
	bro t_type if regexm(t_type, " ")
		** missing entries for ALB 2002, CPV 1998
		** no label for HND 1991, JAM 1997
		
		
gen noinfo = 0
replace noinfo = 1 if w_srcedrnk == "" & t_type == ""

foreach var of local vars {
	replace `var' = "NOINFO" if noinfo == 1
}
	

** save 
compress
save "`dat_folder_new_rhs'/varlist_rhs", replace
