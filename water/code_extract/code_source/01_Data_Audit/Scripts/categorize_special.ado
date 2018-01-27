// File Name: categorize_special.ado

// File Purpose: Apply categorization for special surveys where necessary
// Author: Leslie Mallinger
// Date: 7/11/2011
// Edited on: 

// Additional Comments: 


** define program name and syntax
capture program drop categorize_special
program define categorize_special

syntax, filename(string)


di "special categorization for surveys that need it..."

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
	mata: st_local("w_srcedr", "water")
}


// special treatment for RHS Cape Verde, 1998: skip pattern for water source
if "`filename'" == "CPV_RHS_1998_WN_Y2011M01D31.DTA" {
	display "Cape Verde!"
	
	** make new variable that combines the information from p16d, p18d, p19d
	gen water = .
	replace water = p16d if p18d == 1	// other water and drinking water are the same
	replace water = p19d if p18d == 2	// other water and drinking water are different
	replace water = p19d if p18d == . & p19d != .
	label values water p16d
	
	** drop original variables
	drop p18d p19d
	
	** change local with variable list
	mata: st_local("w_srcedr", "water")
}


// special treatment for RHS Jamaica, 1997: no label in dataset
if "`filename'" == "JAM_RHS_1997_WN_Y2011M03D24.dta" {
	label define q112 1 "Public piped into dwelling" ///
		2 "Public piped into yard" ///
		3 "Private piped into dwelling" ///
		4 "Private catchment, not piped" ///
		5 "Public standpipe" ///
		6 "Public catchment" ///
		7 "Spring or river" ///
		8 "Other (specify)" ///
		9 "Not stated"
	label values q112 q112
	
	label define q113 1 "WC linked to sewer" ///
		2 "WC not linked to sewer" ///
		3 "Pit" ///
		4 "Other (specify)" ///
		5 "None" ///
		9 "Not stated/don't know"
	label values q113 q113
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
		5 "Public standpipe or handpump" ///
		6 "Public well" ///
		7 "River, stream, creek, pond, spring" ///
		8 "Purified water" ///
		88 "Other (specify)" ///
		99 "Don’t know/Not stated"
	label values H004 H004
	
	label define H005 1 "W.C. linked to WASA sewer system" ///
		2 "W.C. linked to septic tank" ///
		3 "Pit latrine, ventilated and elevated" ///
		4 "Pit latrine, ventilated and not elevated" ///
		5 "Pit latrine, ventilated compost" ///
		6 "Pit latrine, non ventilated" ///
		7 "None" ///
		88 "Other (specify)" ///
		99 "Don’t know/Not stated"
	label values H005 H005
}	


// special treatment for IPUMS
/*if regexm("`filename'", "IPUMS") {
	display "IPUMS!"
	
	** change water variable
	capture confirm variable watsrc
	if ! _rc {
		replace watsrc = . if watsrc == 0
	}
	
	capture confirm variable watsup
	if ! _rc {
		replace watsup = . if watsup == 0
	}
	
	** check whether sewage and toilet are both there
	capture confirm variable sewage
	if ! _rc {	// sewage exists
		capture confirm variable toilet
		if ! _rc {	// toilet exists
			** make new variable that combines the information from both
			gen toilet_type = .
			replace toilet_type = 1 if sewage == 10	// connected to sewage system or septic tank
			replace toilet_type = 2 if sewage == 11	// sewage system (public sewage disposal)
			replace toilet_type = 3 if sewage == 12	// septic tank (private sewage disposal)
			replace toilet_type = 4 if sewage == 21	// cesspool, cess pit, septic pit
			replace toilet_type = 5 if sewage == 20 & toilet == 10	// not connected, no toilet
			replace toilet_type = 6 if sewage == 20 & toilet == 11	// not connected, no flush toilet
			replace toilet_type = 7 if sewage == 20 & toilet == 20	// not connected, have toilet, type not specified
			replace toilet_type = 8 if sewage == 20 & toilet == 21	// not connected, flush toilet
			replace toilet_type = 9 if sewage == 20 & toilet == 22	// not connected, non-flush, latrine
			replace toilet_type = 10 if sewage == 20 & toilet == 23	// not connected, non-flush, other and unspecified
			replace toilet_type = 11 if sewage == 20 & toilet_type == .	// not connected
			replace toilet_type = 12 if toilet_type == . & toilet == 10	// no toilet
			replace toilet_type = 13 if toilet_type == . & toilet == 11 	// no flush toilet
			replace toilet_type = 14 if toilet_type == . & toilet == 20	// have toilet, type not specified
			replace toilet_type = 15 if toilet_type == . & toilet == 21	// flush toilet
			replace toilet_type = 16 if toilet_type == . & toilet == 22	// non-flush, latrine
			replace toilet_type = 17 if toilet_type == . & toilet == 23	// non-flush, other and unspecified
			replace toilet_type = 18 if toilet_type == .	// unknown
			replace toilet_type = . if sewage == 00 | toilet == 00
			
			** apply label
			label define toilet_type 1 "connected to sewage system or septic tank"
			label define toilet_type 2 "sewage system (public sewage disposal", add
			label define toilet_type 3 "septic tank (private sewage disposal", add
			label define toilet_type 4 "cesspool, cess pit, septic pit", add
			label define toilet_type 5 "not connected, no toilet", add
			label define toilet_type 6 "not connected, no flush toilet", add
			label define toilet_type 7 "not connected, have toilet, type not specified", add
			label define toilet_type 8 "not connected, flush toilet", add
			label define toilet_type 9 "not connected, non-flush, latrine", add
			label define toilet_type 10 "not connected, non-flush, other and unspecified", add
			label define toilet_type 11 "not connected", add
			label define toilet_type 12 "no toilet", add
			label define toilet_type 13 "no flush toilet", add
			label define toilet_type 14 "have toilet, type not specified", add
			label define toilet_type 15 "flush toilet", add
			label define toilet_type 16 "non-flush, latrine", add
			label define toilet_type 17 "non-flush, other and unspecified", add
			label define toilet_type 18 "unknown", add
			label values toilet_type toilet_type
			
			drop toilet sewage
			global changed 1
		}
		else {	// sewage exists, but not toilet
			gen toilet_type = sewage
			replace toilet_type = . if toilet_type == 00
			label define toilet_type_lbl 10 `"Connected to sewage system or septic tank"', add
			label define toilet_type_lbl 11 `"Sewage system (public sewage disposal)"', add
			label define toilet_type_lbl 12 `"Septic tank (private sewage disposal)"', add
			label define toilet_type_lbl 20 `"Not connected to sewage disposal system"', add
			label define toilet_type_lbl 21 `"Cesspool, cess pit, septic pit"', add
			label define toilet_type_lbl 99 `"Unknown"', add
			label values toilet_type toilet_type_lbl
			
			drop sewage
			global changed 1
		}
	}
	else {	// sewage doesn't exist
		capture confirm variable toilet
		if ! _rc {	// toilet exists
			gen toilet_type = toilet
			replace toilet_type = . if toilet_type == 00
			label define toilet_type_lbl 10 `"No toilet"', add
			label define toilet_type_lbl 11 `"No flush toilet"', add
			label define toilet_type_lbl 20 `"Have toilet, type not specified"', add
			label define toilet_type_lbl 21 `"Flush toilet"', add
			label define toilet_type_lbl 22 `"Non-flush, latrine"', add
			label define toilet_type_lbl 23 `"Non-flush, other and unspecified"', add
			label define toilet_type_lbl 99 `"Unknown"', add
			label values toilet_type toilet_type_lbl		
			
			drop toilet
			global changed 1
		}
	}
}
*/

end
