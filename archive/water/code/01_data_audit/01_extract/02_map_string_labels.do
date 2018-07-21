// Map the strings of water and sanitation indicators to GBD categories (piped/sewer, improved, unimproved)
// Date: 10/6/2016

////////////////////////////
//	1. Set Up			
///////////////////////////
set more off
set maxvar 10000

// Define incoming args
	local data_dir 		`1'
	local out_dir 		`2'
	local iso3 			`3'
	local file			`4'
	// not ideal but cluster not reconizing paths coming in
	local keyloc 		"/home/j/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Label_Keys" 
	local keyversion 	"assigned_04082014"
	di in red "`keyversion'"

// import the dataset extracted through ubcov
	use "`data_dir'/`iso3'/`file'", clear
	cap confirm variable w_source_drink
	if !_rc {
		cap assert mi(w_source_drink)
		if _rc {
		gen water_std = ""
		replace w_source_drink = lower(w_source_drink)
		// apply tap water split for IND DLHS 1998-1999
			preserve
			gen tap_indic = 1 if w_source_drink == "tap" | w_source_drink == "Tap"
			keep if tap_indic == 1
			if !mi(tap_indic) {
				set seed 12345
				tempvar sortorder
				gen `sortorder' = runiform()
				sort `sortorder'
				gen count= _N
					// arbitrary 35% piped into house for now
					local split = round(count * .35)
				replace w_source_drink = "hhconnection" if _n < `split'
				replace w_source_drink = "tap outside" if _n >= `split'
				tempfile tap_split
				save `tap_split', replace
				restore
				drop if w_source_drink == "tap" | w_source_drink == "Tap"
				append using `tap_split'
			}
			else{
				restore
			}
		tempfile water
		save `water', replace

	// import the codebook with all possible combinations of labels
	insheet using "`keyloc'/label_key_water_`keyversion'.csv", comma clear names
	// insheet using "`keyloc'.csv", comma clear names
		foreach var of varlist hhconnection-unknownwater {
			preserve
				di "`var'"
				keep `var'
				rename `var' w_source_drink
				replace w_source_drink = lower(w_source_drink)
				drop if w_source_drink == ""
				duplicates drop
				merge 1:m w_source_drink using `water'
				replace water_std = "`var'" if _merge == 3
				drop if _merge == 1
				drop _merge
				save `water', replace
			restore
		}
		use `water', clear

	// designate each category as improved, unimproved, etc.
		// improved water designation *****Add water >30 min stipulation if deemed appropriate
			gen improved_water = .
			local imp_vars "hhconnection pubtapstandpipe tubewellborehole prowell prospring rainwater improvedotherwater"
			foreach var of local imp_vars {
				di in red "`var'"
				count if water_std == "`var'"
				if `r(N)' > 0 {
					replace improved_water = 1 if water_std == "`var'"
				} 
			}
		//loop through each unimproved water category
			local unimp_vars "unprowell unprospring carttruck surface unimprovedotherwater otherwater bottled unknownwater"
			foreach var of local unimp_vars {
				di in red "`var'"
				count if water_std == "`var'"
				if `r(N)' > 0 {
					replace improved_water = 0 if water_std == "`var'"
				} 
			}
			replace improved_water = 0.5 if water_std == "halfimprovedwater"

		// generate piped indicator
			gen piped = .
			replace piped = 1 if water_std == "hhconnection"
			replace piped = 0 if water_std != "hhconnection" & water_std !=""
			replace piped = 0 if improved_water == 0 // sanity check that all piped observations fit into improved envelope

	// make sure that all entries are assigned a category
		preserve
			drop if regexm(w_source_drink, "other") | regexm(w_source_drink, "unspec")
			count if water_std == "" & w_source_drink != ""
			if `r(N)' > 0 {
				di in red "WARNING: `r(N)' water entries haven't been assigned to categories!"
					keep if water_std == ""
					keep w_source_drink
					duplicates drop
					outsheet using "`keyloc'/water_files/categorize_`file'.csv", comma replace
			}
		restore
	}
}
// import the dataset extracted through ubcov--probably loop through each survey
	cap confirm variable t_type
	if !_rc {
		cap assert mi(t_type)
		if _rc {
		gen sanitation_std = ""
		replace t_type = lower(t_type)
		tempfile sanitation
		save `sanitation', replace

	// import the codebook with all possible combinations of labels
		insheet using "`keyloc'/label_key_sanitation_`keyversion'.csv", comma clear names
		foreach var of varlist pubsewer-unknownsan {
			preserve
				di "`var'"
				keep `var'
				rename `var' t_type
				replace t_type = lower(t_type)
				drop if t_type == ""
				duplicates drop
				merge 1:m t_type using `sanitation'
				replace sanitation_std = "`var'" if _merge == 3
				drop if _merge == 1
				drop _merge
				save `sanitation', replace
			restore
		}

	// designate each category as improved, unimproved, etc.
			use `sanitation', clear
			gen improved_san = .
			local imp_vars "pubsewer septic pourflush simplepit vip composting improvedothersan"
			foreach var of local imp_vars {
				di in red "`var'"
				count if sanitation_std == "`var'"
				if `r(N)' > 0 {
					replace improved_san = 1 if sanitation_std == "`var'"
				} 
			}
		//loop through each unimproved sanitation category
			local unimp_vars "bucket openlatrine hanging opendef othersan unimprovedothersan unknownsan"
			foreach var of local unimp_vars {
				di in red "`var'"
				count if sanitation_std == "`var'"
				if `r(N)' > 0 {
					replace improved_san = 0 if sanitation_std == "`var'"
				} 
			}
		replace improved_san = 0.5 if sanitation_std == "halfimprovedsan"
		cap confirm string variable shared_san
		if !_rc {
			drop shared_san
			gen shared_san = .
		}
		replace improved_san = 0 if shared_san == 1 // any shared sanitation is considered unimproved

		// generate sewer indicator
			gen sewer = .
			replace sewer = 1 if sanitation_std == "pubsewer" | 	sanitation_std == "septic" | sanitation_std == "pourflush"
			replace sewer = 0 if sanitation_std != "" & sewer == .
			replace sewer = 0 if shared_san == 1  | improved_san == 0 // any shared sanitation is considered unimproved

		
	// make sure that all entries are assigned a category
		preserve
			drop if regexm(t_type, "other") | regexm(t_type, "unspec")
			count if sanitation_std == "" & t_type != ""
			if `r(N)' > 0 {
				di in red "WARNING: `r(N)' sanitation entries haven't been assigned to categories!"
				keep if sanitation_std == ""
				keep t_type
				duplicates drop
				outsheet using "`keyloc'/sanitation_files/categorize_`file'.csv", comma replace
			}
		restore
	}
}
// Create a single handwashing indicator
cap confirm numeric variable hw_soap
if !_rc {
	cap confirm numeric variable hw_station
	if !_rc {
		gen handwashing = .
		replace handwashing = 1 if hw_water == 1 & hw_station == 1 & hw_soap == 1
		replace handwashing = 0 if handwashing != 1
		drop hw_soap hw_station hw_water
	}
}
else {
	gen handwashing = .
	cap drop hw_soap hw_station hw_water
}

// Map cooking fuel to an hap_exposed indicator ************* Need to add the other values used in MICS and others
	cap rename fuel_cooking cooking_fuel
	// will break if cooking_fuel is not a string
	cap confirm variable cooking_fuel 
	if !_rc {
		replace cooking_fuel=lower(cooking_fuel)
		gen hap_expose=.
			// DHS	
			//hap_expose=0
			replace hap_expose=0 if regexm(cooking_fuel,"electri")|regexm(cooking_fuel,"lpg")|regexm(cooking_fuel,"petro")|regexm(cooking_fuel,"solar")|regexm(cooking_fuel,"gas")|regexm(cooking_fuel,"kerosene")| regexm(cooking_fuel,"butane")| regexm(cooking_fuel,"paraffin")| regexm(cooking_fuel,"no cooking") | regexm(cooking_fuel,"not cook")|regexm(cooking_fuel,"no food")| regexm(cooking_fuel,"don't cook") ///
			|regexm(cooking_fuel,"queroseno") /// 
			|regexm(cooking_fuel,"pétrole")|regexm(cooking_fuel,"gaz")|regexm(cooking_fuel,"kérosène")| regexm(cooking_fuel,"pas de repas préparé")|regexm(cooking_fuel,"pas de repas prepare")|regexm(cooking_fuel,"eléct") ///
			|regexm(cooking_fuel,"gás")| regexm(cooking_fuel,"kerose")|regexm(cooking_fuel,"petróleo") |	regexm(cooking_fuel,"smokeless") | regexm(cooking_fuel,"jelly")
			
			//hap_expose=1
			replace hap_expose=1 if regexm(cooking_fuel,"coal")|regexm(cooking_fuel,"lignite")|regexm(cooking_fuel,"charcoal")|regexm(cooking_fuel,"wood") |regexm(cooking_fuel,"straw") |regexm(cooking_fuel,"shrub")|regexm(cooking_fuel,"grass")|regexm(cooking_fuel,"crop")| regexm(cooking_fuel,"dung")|regexm(cooking_fuel,"saw")|regexm(cooking_fuel,"briquette")|regexm(cooking_fuel,"waste")|regexm(cooking_fuel,"agriculture") /// 
			|regexm(cooking_fuel,"carvao")|regexm(cooking_fuel,"lenha")|regexm(cooking_fuel,"palha") |regexm(cooking_fuel,"carbón de leña")|regexm(cooking_fuel," leña")|regexm(cooking_fuel,"paja")|regexm(cooking_fuel,"lena") /// 
			|regexm(cooking_fuel,"fageot")|regexm(cooking_fuel,"fagot")|regexm(cooking_fuel,"charbon")|regexm(cooking_fuel,"bois") | regexm(cooking_fuel,"paille")|regexm(cooking_fuel,"banchages")|regexm(cooking_fuel,"herb")|regexm(cooking_fuel,"bouse")| regexm(cooking_fuel,"agricoles")|regexm(cooking_fuel,"scuire")|regexm(cooking_fuel,"copeaux")| regexm(cooking_fuel,"fumier") ///
			|regexm(cooking_fuel,"fezes") |regexm(cooking_fuel,"carvão") | regexm(cooking_fuel,"tezek") | regexm(cooking_fuel,"none")
			
			// MICS Version 2
			//expose=0
			replace cooking_fuel="coals" if cooking_fuel=="goals"
			replace hap_expose=0 if regexm(cooking_fuel,"electri")|regexm(cooking_fuel,"lpg")|regexm(cooking_fuel,"petro")|regexm(cooking_fuel,"gas")|regexm(cooking_fuel,"kerosene")| regexm(cooking_fuel,"butane")| regexm(cooking_fuel,"no cooking") | regexm(cooking_fuel,"not cook")|regexm(cooking_fuel,"no food")|regexm(cooking_fuel,"paraffin") ///
			|regexm(cooking_fuel,"queroseno") /// 
			|regexm(cooking_fuel,"pétrole")|regexm(cooking_fuel,"gaz")|regexm(cooking_fuel,"kérosène")| regexm(cooking_fuel,"pas de repas préparé")|regexm(cooking_fuel,"pas de repas prepare")|regexm(cooking_fuel,"eléct") ///
			|regexm(cooking_fuel,"gás")| regexm(cooking_fuel,"kerose")|regexm(cooking_fuel,"petróleo")
			
			//expose=1
			replace hap_expose=1 if regexm(cooking_fuel,"coal")|regexm(cooking_fuel,"lignite")|regexm(cooking_fuel,"charcoal")|regexm(cooking_fuel,"wood") |regexm(cooking_fuel,"straw") |regexm(cooking_fuel,"shrub")|regexm(cooking_fuel,"grass")|regexm(cooking_fuel,"agricultural crop")| regexm(cooking_fuel,"dung")|regexm(cooking_fuel,"saw")|regexm(cooking_fuel,"briquette")|regexm(cooking_fuel,"waste") /// 
			|regexm(cooking_fuel,"carvao")|regexm(cooking_fuel,"lenha")|regexm(cooking_fuel,"palha") |regexm(cooking_fuel,"carbón de leña")|regexm(cooking_fuel," leña")|regexm(cooking_fuel,"paja")|regexm(cooking_fuel,"lena") /// 
			|regexm(cooking_fuel,"fageot")|regexm(cooking_fuel,"fagot")|regexm(cooking_fuel,"charbon")|regexm(cooking_fuel,"bois") | regexm(cooking_fuel,"paille")|regexm(cooking_fuel,"banchages")|regexm(cooking_fuel,"herb")|regexm(cooking_fuel,"bouse")|regexm(cooking_fuel,"agricoles")|regexm(cooking_fuel,"scuire")|regexm(cooking_fuel,"copeaux")| regexm(cooking_fuel,"fumier") ///
			|regexm(cooking_fuel,"fezes") |regexm(cooking_fuel,"carvão") |regexm(cooking_fuel,"argal")

			// MICS Version 3
			//expose=0
			replace hap_expose=0 if regexm(cooking_fuel,"electri")|regexm(cooking_fuel,"lpg")|regexm(cooking_fuel,"petro")|regexm(cooking_fuel,"gas")|regexm(cooking_fuel,"kerosene")| regexm(cooking_fuel,"butane")| regexm(cooking_fuel,"no cooking") | regexm(cooking_fuel,"not cook")|regexm(cooking_fuel,"no food")|regexm(cooking_fuel,"paraffin") ///
			|regexm(cooking_fuel,"queroseno") /// 
			|regexm(cooking_fuel,"pétrole")|regexm(cooking_fuel,"gaz")|regexm(cooking_fuel,"kérosène")| regexm(cooking_fuel,"pas de repas préparé")|regexm(cooking_fuel,"pas de repas prepare")|regexm(cooking_fuel,"eléct") ///
			|regexm(cooking_fuel,"gás")| regexm(cooking_fuel,"kerose")|regexm(cooking_fuel,"petróleo")
			
			//expose=1
			replace hap_expose=1 if regexm(cooking_fuel,"coal")|regexm(cooking_fuel,"lignite")|regexm(cooking_fuel,"charcoal")|regexm(cooking_fuel,"wood") |regexm(cooking_fuel,"straw") |regexm(cooking_fuel,"shrub")|regexm(cooking_fuel,"grass")|regexm(cooking_fuel,"agricultural crop")| regexm(cooking_fuel,"dung")|regexm(cooking_fuel,"saw")|regexm(cooking_fuel,"briquette")|regexm(cooking_fuel,"waste") /// 
			|regexm(cooking_fuel,"carvao")|regexm(cooking_fuel,"lenha")|regexm(cooking_fuel,"palha") |regexm(cooking_fuel,"carbón de leña")|regexm(cooking_fuel," leña")|regexm(cooking_fuel,"paja")|regexm(cooking_fuel,"lena") /// 
			|regexm(cooking_fuel,"fageot")|regexm(cooking_fuel,"fagot")|regexm(cooking_fuel,"charbon")|regexm(cooking_fuel,"bois") | regexm(cooking_fuel,"paille")|regexm(cooking_fuel,"banchages")|regexm(cooking_fuel,"herb")|regexm(cooking_fuel,"bouse")|regexm(cooking_fuel,"agricoles")|regexm(cooking_fuel,"scuire")|regexm(cooking_fuel,"copeaux")| regexm(cooking_fuel,"fumier") ///
			|regexm(cooking_fuel,"fezes") |regexm(cooking_fuel,"carvão")

			// MICS Version 4
			//expose=0
			replace hap_expose=0 if regexm(cooking_fuel,"electri")|regexm(cooking_fuel,"lpg")|regexm(cooking_fuel,"petro")|regexm(cooking_fuel,"gas")|regexm(cooking_fuel,"kerosene")| regexm(cooking_fuel,"butane")| regexm(cooking_fuel,"no cooking") | regexm(cooking_fuel,"not cook")|regexm(cooking_fuel,"no food")|regexm(cooking_fuel,"paraffin") ///
			|regexm(cooking_fuel,"queroseno") /// 
			|regexm(cooking_fuel,"pétrole")|regexm(cooking_fuel,"gaz")|regexm(cooking_fuel,"kérosène")| regexm(cooking_fuel,"pas de repas préparé")|regexm(cooking_fuel,"pas de repas prepare")|regexm(cooking_fuel,"eléct") ///
			|regexm(cooking_fuel,"gás")| regexm(cooking_fuel,"kerose")|regexm(cooking_fuel,"petróleo")
			
			//expose=1
			replace hap_expose=1 if regexm(cooking_fuel,"coal")|regexm(cooking_fuel,"lignite")|regexm(cooking_fuel,"charcoal")|regexm(cooking_fuel,"wood") |regexm(cooking_fuel,"straw") |regexm(cooking_fuel,"shrub")|regexm(cooking_fuel,"grass")|regexm(cooking_fuel,"agricultural crop")| regexm(cooking_fuel,"dung")|regexm(cooking_fuel,"saw")|regexm(cooking_fuel,"briquette")|regexm(cooking_fuel,"waste") /// 
			|regexm(cooking_fuel,"carvao")|regexm(cooking_fuel,"lenha")|regexm(cooking_fuel,"palha") |regexm(cooking_fuel,"carbón de leña")|regexm(cooking_fuel," leña")|regexm(cooking_fuel,"paja")|regexm(cooking_fuel,"lena") /// 
			|regexm(cooking_fuel,"fageot")|regexm(cooking_fuel,"fagot")|regexm(cooking_fuel,"charbon")|regexm(cooking_fuel,"bois") | regexm(cooking_fuel,"paille")|regexm(cooking_fuel,"banchages")|regexm(cooking_fuel,"herb")|regexm(cooking_fuel,"bouse")|regexm(cooking_fuel,"agricoles")|regexm(cooking_fuel,"scuire")|regexm(cooking_fuel,"copeaux")| regexm(cooking_fuel,"fumier") ///
			|regexm(cooking_fuel,"fezes") |regexm(cooking_fuel,"carvão")
			
			// MICS Version 5
			//expose=0
			replace hap_expose=0 if regexm(cooking_fuel,"electri")|regexm(cooking_fuel,"lpg")|regexm(cooking_fuel,"petro")|regexm(cooking_fuel,"gas")|regexm(cooking_fuel,"kerosene")| regexm(cooking_fuel,"butane")| regexm(cooking_fuel,"no cooking") | regexm(cooking_fuel,"not cook")|regexm(cooking_fuel,"no food")|regexm(cooking_fuel,"paraffin") ///
			|regexm(cooking_fuel,"queroseno") /// 
			|regexm(cooking_fuel,"pétrole")|regexm(cooking_fuel,"gaz")|regexm(cooking_fuel,"kérosène")| regexm(cooking_fuel,"pas de repas préparé")|regexm(cooking_fuel,"pas de repas prepare")|regexm(cooking_fuel,"eléct") ///
			|regexm(cooking_fuel,"gás")| regexm(cooking_fuel,"kerose")|regexm(cooking_fuel,"petróleo")
			
			//expose=1
			replace hap_expose=1 if regexm(cooking_fuel,"coal")|regexm(cooking_fuel,"lignite")|regexm(cooking_fuel,"charcoal")|regexm(cooking_fuel,"wood") |regexm(cooking_fuel,"straw") |regexm(cooking_fuel,"shrub")|regexm(cooking_fuel,"grass")|regexm(cooking_fuel,"agricultural crop")| regexm(cooking_fuel,"dung")|regexm(cooking_fuel,"saw")|regexm(cooking_fuel,"briquette")|regexm(cooking_fuel,"waste") /// 
			|regexm(cooking_fuel,"carvao")|regexm(cooking_fuel,"lenha")|regexm(cooking_fuel,"palha") |regexm(cooking_fuel,"carbón de leña")|regexm(cooking_fuel," leña")|regexm(cooking_fuel,"paja")|regexm(cooking_fuel,"lena") /// 
			|regexm(cooking_fuel,"fageot")|regexm(cooking_fuel,"fagot")|regexm(cooking_fuel,"charbon")|regexm(cooking_fuel,"bois") | regexm(cooking_fuel,"paille")|regexm(cooking_fuel,"banchages")|regexm(cooking_fuel,"herb")|regexm(cooking_fuel,"bouse")|regexm(cooking_fuel,"agricoles")|regexm(cooking_fuel,"scuire")|regexm(cooking_fuel,"copeaux")| regexm(cooking_fuel,"fumier") ///
			|regexm(cooking_fuel,"fezes") |regexm(cooking_fuel,"carvão")
	
	// Check that all relevant cooking fuel options have been identified
	preserve
		drop if regexm(cooking_fuel, "other") | regexm(cooking_fuel,"unspec") | regexm(cooking_fuel,"no") | regexm(cooking_fuel,"yes") | regexm(cooking_fuel,"manquant") | regexm(cooking_fuel,"autres") | regexm(cooking_fuel,"candles")
		count if cooking_fuel != "" & hap_expose == .
		if `r(N)' > 0 {
			keep if cooking_fuel != "" & hap_expose == .
			keep cooking_fuel
			duplicates drop
			outsheet using "`keyloc'/hap_files/categorize_`file'.csv", comma replace
		}
	restore
	}

// Replace all variables that contain "missing" to actual missing variables
/* local vars "w_treat w_filter w_boil w_bleach w_solar w_cloth w_settle shared_san mins_ws shared_san_num w_source_drink w_source_other t_type cooking_fuel"
foreach var of local vars {
	cap confirm variable `var'
	if !_rc {
		cap confirm string variable `var'
		if !_rc {
			if `var' == "missing" {
				drop `var'
				gen `var' = .
			}
		}
	}
}*/

// Create treatment indicator for boil/filter and solar/chlorine
cap confirm variable w_boil
if !_rc {
	cap confirm variable w_filter
	if !_rc {
		gen boil_filter = .
		replace boil_filter = 1 if w_boil == 1 | w_filter == 1
		replace boil_filter = 0 if w_treat != . & boil_filter != 1
	}
}

cap confirm variable w_solar
if !_rc {
	cap confirm variable w_bleach
	if !_rc {
		gen solar_chlorine = . 
		replace solar_chlorine = 1 if w_solar == 1 | w_bleach == 1
		replace solar_chlorine = 0 if w_treat != . & solar_chlorine != 1
	}
}

// Generate vars with no observations for missing vars so Zane's collapse won't break
local vars improved_water piped improved_san sewer handwashing hap_expose boil_filter solar_chlorine
foreach var of local vars {
	cap confirm variable `var'
	if _rc {
		gen `var' = .
	}
}

// Clean and save
	local vars "cooking_fuel t_type w_source_drink water_std sanitation_std mins_ws mins_ws_zero shared_san shared_san_num_greater_ten shared_san_num w_source_other w_settle w_cloth w_bleach w_boil w_filter w_treat w_solar"
	foreach var of local vars {
		cap confirm variable `var'
		if !_rc {
			drop `var'
		}
	}

	//For Zane's tabulation-change back
	gen 
	cap mkdir "`out_dir'/`iso3'"
	local file = subinstr("`file'", ".dta", "", .)
	export delimited "`out_dir'/`iso3'/`file'.csv", replace
