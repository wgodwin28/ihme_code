//Filename: sanitation_rr_prep.do
//July 1, 2014
//Purpose: Prepare and save draws and mean estimates for sanitation Relative Risks 
//updated 07/01/2014 to save draws for new WSH categories
//updated 12/03/2014 to save draws for sanitation without hygiene for diarrhea ONLY. Removing typhoid and paratyphoid as outcomes
//updated 03/10/2015 added typhoid and paratyphoid fevers as outcomes
//updated 5/1/2017 Surprise! Eliminated typhoid and paratyphoid again!

//Script to run things on the cluster


clear
set more off
set maxvar 30000

// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 
	
//set relevant locals
	local out_dir_draws		"/share/epi/risk/temp/wash_sanitation/rr"
	local rf_new			"wash_sanitation"
	local output_version	6
	
** Create RR template
	** Make up a few causes
	clear
	set obs 3
	
	** Risk
	gen risk = "`rf_new'"
	gen mortality = 1 
	gen morbidity = 1 
	
	**gen parameter
	gen id = _n
	tostring(id), replace
	gen parameter = "cat" + id
	drop id 
	
**Prep data
	gen cause_id = 302 // diarrhea
	gen location_id = 1
	gen year_id = 1990

	//Sanitation Categories//
	**sewer 
	gen rr_mean = 1 if parameter == "cat3"
	gen rr_lower = 1 if parameter == "cat3"
	gen rr_upper = 1 if parameter == "cat3"
	
	**improved (other than sewer)
	//replace rr_mean = 2.709677419 if parameter == "cat2"
	//replace rr_lower = 2.527777778 if parameter == "cat2"
	//replace rr_upper = 2.851851852 if parameter == "cat2"
	
	replace rr_mean = 2.5815 if parameter == "cat2"
	replace rr_lower = 2.0206 if parameter == "cat2"
	replace rr_upper = 3.2983 if parameter == "cat2"

	**unimproved 
	//replace rr_mean = 3.225806452 if parameter == "cat1"
	//replace rr_lower = 2.777777778 if parameter == "cat1"
	//replace rr_upper = 3.703703704 if parameter == "cat1"
	
	replace rr_mean = 3.2238 if parameter == "cat1"
	replace rr_lower = 2.5560 if parameter == "cat1"
	replace rr_upper = 4.0660 if parameter == "cat1"

	** Create two categories and 1000 draws
	gen sd = ((ln(rr_upper)) - (ln(rr_lower))) / (2*invnormal(.975))
	forvalues draw = 0/999 {
		gen rr_`draw' = exp(rnormal(ln(rr_mean), sd))
	}	

	// Work around to duplicate out for each age_group_id
	local ages "2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 30 31 32 235"
	local age_app "3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 30 31 32 235"

	gen age_group_id = .
	foreach x of local ages {
		replace age_group_id = `x'
		tempfile temp_`x'
		save `temp_`x'', replace
	}

	use `temp_2', clear
	foreach x of local age_app {
		append using `temp_`x''
	}

	***************************
	** Save draws on clustertmp**
	***************************
	gen sex_id = .
	foreach sex in 1 2 {
		replace sex_id = `sex'
		export delimited "`out_dir'/rr_1_1990_`sex'.csv", replace
	}
	// Run save_results
	local dat_dir "/share/epi/risk/temp/wash_sanitation/rr"
	quietly run "/home/j/temp/central_comp/libraries/current/save_results.do"
	save_results, modelable_entity_id(9018) description(RR update-new network meta-in house) in_dir(`dat_dir') mark_best(yes) risk_type("rr")

*******************************
**********end of code***********
*******************************
