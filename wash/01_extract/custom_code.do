// Purpose:Custom_code to prep WaSH and HAP indicators for tabulation
// Date: 12/28/2016

// HAP toggle
local hh_size_adj = 1
local shared = 1
/*
// Construct handwashing indicator
	cap confirm variable hw_soap hw_station hw_water
	if !_rc {
		di in red "creating handwashing indicator..."
		gen handwashing = 1 if hw_soap == 1 & hw_station == 1 & hw_water == 1
		replace handwashing = 0 if handwashing == .
	}

// Improved and piped water indicator generation
	cap confirm variable w_source_drink_mapped
	if !_rc {
		di in red "creating water indicator..."
		gen improved_water = 1 if w_source_drink_mapped == "improved" 
		replace improved_water = 0 if w_source_drink_mapped == "unimproved" | w_source_drink_mapped == "piped"
		gen piped = 1 if w_source_drink_mapped == "piped"
		replace piped = 0 if w_source_drink_mapped == "improved" | w_source_drink_mapped == "unimproved" | w_source_drink_mapped == "bottle" 
	}
	
	// Use source of non-drinking water to classify bottled water
		cap confirm variable w_source_other_mapped
		if !_rc {
			replace improved_water = 1 if w_source_other_mapped == "improved" & w_source_drink_mapped == "bottle"
			replace improved_water = 0 if w_source_other_mapped == "unimproved" & w_source_drink_mapped == "bottle"
		}

	 // Construct handwashing from PMA surveys
	//if regexm(file_path, "PMA2020") {
	//	cap confirm variable hw_station
	//	if !_rc {
	//		gen handwashing = .
	//		replace handwashing = 1 if improved_water == 1 & hw_station == 1
	//		replace handwashing = 0 if handwashing != 1
	//	}
	//Account for the fact that PMA datasets are at the individual level
	// duplicates drop strata EA_ID household, force
	//}

// Improved and sewer sanitation indicator generation
	cap confirm variable t_type_mapped
	if !_rc {
		di in red "creating toilet indicator..."
		gen improved_san = 1 if t_type_mapped == "improved"
		replace improved_san = 0 if t_type_mapped == "unimproved" | t_type_mapped == "sewer" | t_type_mapped == "open_def"
		gen sewer = 1 if t_type_mapped == "sewer"
		replace sewer = 0 if t_type_mapped == "improved" | t_type_mapped == "unimproved" | t_type_mapped == "open_def"
		if regexm(ihme_loc_id, "IND") {
			gen open_def = 1 if t_type_mapped == "open_def"
			replace open_def = 0 if t_type_mapped == "improved" | t_type_mapped == "unimproved" | t_type_mapped == "sewer"
		}
		// shared sanitation check
		if `shared' == 1 {
			cap confirm variable shared_san
			if !_rc {
				replace improved_san = 0 if shared_san == 1
				replace sewer = 0 if shared_san == 1
				gen shared = 1 if shared_san == 1
				replace shared = 0 if shared_san == 0
			}
		}
	}


// Filter/boil indicator creation
	cap confirm variable w_boil w_filter w_treat piped
	if !_rc {
		gen wash_water_itreat_piped = .
		replace wash_water_itreat_piped = 1 if (w_boil == 1 | w_filter == 1) & (piped == 1)
		replace wash_water_itreat_piped = 0 if piped == 1 & wash_water_itreat_piped != 1
	
		// gen improved_only = 1 if improved_water == 1 & piped == 0
		// replace improved_only = 0 if improved_only == .
		gen wash_water_itreat_imp = .
		replace wash_water_itreat_imp = 1 if (w_boil == 1 | w_filter == 1) & (improved_water == 1)
		replace wash_water_itreat_imp = 0 if improved_water == 1 & wash_water_itreat_imp != 1

		gen unimproved = 1 if improved_water == 0 & piped == 0
		replace unimproved = 0 if improved_water == 1 | piped == 1
		gen wash_water_itreat_unimp = 1 if (w_boil == 1 | w_filter == 1) & (unimproved == 1) 
		replace wash_water_itreat_unimp = 0 if unimproved == 1 & wash_water_itreat_unimp != 1
	}

// ANY HWT indicator creation
	cap confirm variable w_boil w_filter w_solar w_bleach w_treat piped
	if !_rc {
		gen wash_water_tr_piped = . 
		replace wash_water_tr_piped = 1 if (w_solar == 1 | w_bleach == 1 | w_boil == 1 | w_filter == 1) & (piped == 1)
		replace wash_water_tr_piped = 0 if piped == 1 & wash_water_tr_piped != 1

		gen wash_water_tr_imp = .
		replace wash_water_tr_imp = 1 if (w_solar == 1 | w_bleach == 1 | w_boil == 1 | w_filter == 1) & (improved_water == 1)
		replace wash_water_tr_imp = 0 if improved_water == 1 & wash_water_tr_imp != 1

		gen wash_water_tr_unimp = . 
		replace wash_water_tr_unimp = 1 if (w_solar == 1 | w_bleach == 1 | w_boil == 1 | w_filter == 1) & (unimproved == 1)
		replace wash_water_tr_unimp = 0 if unimproved == 1 & wash_water_tr_unimp != 1
	}

	// For surveys that don't ask about solar disinfection
	cap confirm variable wash_water_tr_piped
	if _rc {
		cap confirm variable w_boil w_filter w_bleach w_treat piped
		if !_rc {
		gen wash_water_tr_piped = . 
		replace wash_water_tr_piped = 1 if (w_bleach == 1 | w_boil == 1 | w_filter == 1) & (piped == 1)
		replace wash_water_tr_piped = 0 if piped == 1 & wash_water_tr_piped != 1

		gen wash_water_tr_imp = .
		replace wash_water_tr_imp = 1 if (w_bleach == 1 | w_boil == 1 | w_filter == 1) & (improved_water == 1)
		replace wash_water_tr_imp = 0 if improved_water == 1 & wash_water_tr_imp != 1

		gen wash_water_tr_unimp = . 
		replace wash_water_tr_unimp = 1 if (w_bleach == 1 | w_boil == 1 | w_filter == 1) & (unimproved == 1)
		replace wash_water_tr_unimp = 0 if unimproved == 1 & wash_water_tr_unimp != 1
		}
	}
// Household air pollution indicator
	local fuels "gas biomass coal crop kerosene wood dung other"
	cap confirm variable cooking_fuel_mapped
	if !_rc {
		gen hap_expose = .
		replace hap_expose = 0 if cooking_fuel_mapped == "gas" | cooking_fuel_mapped == "kerosene"
		replace hap_expose = 1 if cooking_fuel_mapped == "biomass" | cooking_fuel_mapped == "coal" | cooking_fuel_mapped == "crop" | cooking_fuel_mapped == "wood" | cooking_fuel_mapped == "dung"
		// foreach fuel of local fuels {
			// gen hap_`fuel' = .
			// replace hap_`fuel' = 1 if cooking_fuel_mapped == "`fuel'"
			// replace hap_`fuel' = 0 if cooking_fuel_mapped != "`fuel'" & cooking_fuel_mapped != ""
		// }
	}

// Generate vars with no observations for missing vars so Zane's collapse won't break
local vars improved_water piped_mod improved_san sewer handwashing hap_expose any_hwt_piped any_hwt_imp any_hwt_unimp boil_filter_piped boil_filter_imp boil_filter_unimp
foreach var of local vars {
	cap confirm variable `var'
	if !_rc {
		cap assert mi(`var')
		if !_rc {
			drop `var'
		}
	}
}
*/
// Adjust for family size
if `hh_size_adj' == 1 {
	if survey_module == "HH" {
		cap confirm numeric variable hh_size pweight
		if !_rc {
			replace hh_size = 35 if hh_size > 35 & hh_size != .
			replace pweight = pweight * hh_size
		}
	}	
}
/*
// Tag if has no indicators of interest
cap confirm variable improved_water
if _rc {
	cap confirm variable improved_san
	if _rc {
		cap confirm variable hap_expose
		if _rc {
			gen empty = 1
		}
	}
}
*/
// Clean and save
	local vars "cooking_fuel w_source_drink water_std sanitation_std mins_ws mins_ws_zero shared_san shared_san_num_greater_ten shared_san_num w_source_other w_settle w_cloth w_bleach w_boil w_filter w_treat w_solar hw_soap1 hw_soap2 hw_soap3 age_year hw_station hw_water hw_soap"
	foreach var of local vars {
		cap confirm variable `var'
		if !_rc {
			drop `var'
		}
	}
