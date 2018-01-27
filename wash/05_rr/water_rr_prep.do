**Purpose: Generate correlated draws of relative Risks for new WASH categories
**Author: Astha KC
**Date: July 9 2015
**Edited: Will Godwin
**Date: 5/1/2017

**The relative risks used to estimate burden for WASH were extracted from two papers. 
**RRs for water faciltities & household water treatments were extracted from a meta-regression conducted by Wolf et al (2014)
**We combine these relative risks to generate RRs for our exposure categories that combine exposure to water facility with household water treatment practices. 
**We use relative risks that havent been adjusted for non-blinding in order to be consistent with other relative risks in the GBD CRA analysis. 
**The calculation below generate the combined relative risks and their uncertainty intervals

**STEPS TO GENERATE CORRELATED WATER RR DRAWS**

**1. Generate 1000 draws of water source interventions
**2. Sort each set of draws and merge sorted draws
**3. Randomly shuffle the matched draws by generating and sorting a random number
**4. Generate 1000 draws of POU water treatment interventions
**5. Sort each set of draws and merge sorted draws
**6. Merge POU water trx draws with water source draws
**7. Generate draws of final 9 categories of water
**8. Generate mean and uncertainty intervals
**9. Generate a scatter plot to ensure the correlation is intact

***SCRIPT TO CALL ON DO FILE FROM THE CLUSTER

clear all
set more off
set obs 1
set seed 587415 

// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 
	
// Set relevant locals
	local out_dir			"/share/epi/risk/temp/wash_water/rr"
	local rf_new			"wash_water"
	local output_version	9
	adopath + "$j/temp/central_comp/libraries/current/stata"
	
******************************************************	
***1. Generate a 1000 draws of water source interventions****
******************************************************

	**effect of improving water source types
	**improved community source
	clear all
	set more off
	set obs 1
	//local rr_improved = 0.89
	//local upper_improved = 0.78
	//local lower_improved = 1.01
	local rr_improved = 0.86
	local upper_improved = 0.73
	local lower_improved = 1.01
	local sd_improved = ((ln(`lower_improved')) - (ln(`upper_improved'))) / (2*invnormal(.975))
	forvalues draw = 0/999 {
		gen rr_improved_`draw' = exp(rnormal(ln(`rr_improved'), `sd_improved'))  
	}
	keep rr_improved_*
	gen cat = "rr_improved"
	reshape long rr_improved_, i(cat) j(draw)
	drop cat draw
	sort rr_improved_
	gen draw = _n
	tempfile improved
	save `improved', replace

	**piped water supply in low/middle income countries; defined as "basic piped supply" by Wolf et al 2014. 
	clear all 
	set more off
	set obs 1
	//local rr_piped_lmi  = 0.77
	//local upper_piped_lmi = 0.64 
	//local lower_piped_lmi = 0.92
	local rr_piped_lmi  = 0.77
	local upper_piped_lmi = 0.65 
	local lower_piped_lmi = 0.93
	local sd_piped_lmi = ((ln(`lower_piped_lmi')) - (ln(`upper_piped_lmi'))) / (2*invnormal(.975))
	forvalues draw = 0/999 {
		gen rr_piped_lmi_`draw' = exp(rnormal(ln(`rr_piped_lmi'), `sd_piped_lmi'))  
	}
	keep rr_piped_lmi_*
	gen cat = "rr_piped_lmi"
	reshape long rr_piped_lmi_, i(cat) j(draw)
	drop cat draw
	sort rr_piped_lmi_
	gen draw = _n
	tempfile piped_lmi
	save `piped_lmi', replace

	**piped water supply in high income countries (for our analysis - this applies to central/eastern europe and high income latin america); defined as "piped water, higher quality*" by Wolf et al 2014.
	clear all
	set more off
	set obs 1
	//local rr_piped_hi = 0.19
	//local upper_piped_hi = 0.07
	//local lower_piped_hi = 0.50
	local rr_piped_hi = 0.25
	local upper_piped_hi = 0.06
	local lower_piped_hi = 0.75
	local sd_piped_hi = ((ln(`lower_piped_hi')) - (ln(`upper_piped_hi'))) / (2*invnormal(.975))
	forvalues draw = 0/999 {
		gen rr_piped_hi_`draw' = exp(rnormal(ln(`rr_piped_hi'), `sd_piped_hi'))  
	}
	keep rr_piped_hi_*
	gen cat = "rr_piped_hi"
	reshape long rr_piped_hi_, i(cat) j(draw)
	drop cat draw
	sort rr_piped_hi_
	gen draw = _n
	
********************************************************************
*****2. Merge sorted draws for water sources****************************
********************************************************************

	merge 1:1 draw using `improved', keep(1 3) nogen
	merge 1:1 draw using `piped_lmi', keep(1 3) nogen
	tempfile sources
	save `sources', replace
	
********************************************************************************************************************
*****3. Randomly shuffle water source draws such that they are not correlated with point-of-use draws****************************
********************************************************************************************************************
	
	**Generate random #s and sort
	clear all 
	set obs 1000 
	gen double random = (5-1)*runiform() + 1
	gen draw = _n 
	merge 1:1 draw using `sources', keep(1 3) nogen
	sort random
	drop draw random
	gen draw = _n
	
	tempfile random_shuffle 
	save `random_shuffle', replace 
	
****************************************************************************************
******4. Generate a 1000 draws of POU water treatment***************************************
****************************************************************************************
	
	**Effect of household water treatment practices extracted from the paper
	**filter/boil - most effective treatment
	clear all 
	set more off 
	set obs 1
	
	//local rr_filter = 0.53
	//local upper_filter = 0.41
	//local lower_filter = 0.67
	local rr_filter = 0.42
	local upper_filter = 0.36
	local lower_filter = 0.49
	local sd_filter = ((ln(`lower_filter')) - (ln(`upper_filter'))) / (2*invnormal(.975))
	forvalues draw = 0/999 {
		gen rr_filter_`draw' = exp(rnormal(ln(`rr_filter'), `sd_filter'))  
	}
	keep rr_filter_*
	gen cat = "rr_filter"
	**set obs 1000
	reshape long rr_filter_, i(cat) j(draw)
	drop cat draw
	sort rr_filter_
	gen draw = _n
	tempfile filter
	save `filter', replace

	**chlorine/solar - less effective
	clear all 
	set more off
	set obs 1 
	//local rr_chlorine = 0.82
	//local upper_chlorine = 0.69
	//local lower_chlorine = 0.96
	local rr_chlorine = 0.69
	local upper_chlorine = 0.62
	local lower_chlorine = 0.76
	local sd_chlorine = ((ln(`lower_chlorine')) - (ln(`upper_chlorine'))) / (2*invnormal(.975))
	forvalues draw = 0/999 {
		gen rr_chlorine_`draw' = exp(rnormal(ln(`rr_chlorine'), `sd_chlorine'))
	}
	keep rr_chlorine_*
	gen cat = "rr_chlorine"
	reshape long rr_chlorine_, i(cat) j(draw)
	drop cat draw
	sort rr_chlorine_
	gen draw = _n
	merge 1:1 draw using `filter', keepusing(rr_filter_) keep(1 3) nogen
	tempfile pou
	save `pou', replace
	
***********************************************************************************************
******5. Merge point-of-use and water source draws into a single dataset to generate combined draws*******
***********************************************************************************************

/**define cat variable to match exposure
	replace cat = "cat1" if cat=="unimproved - hwt"
	replace cat = "cat2" if cat=="unimproved + chlorine/solar"
	replace cat = "cat3" if cat=="unimproved + filter/boil"
	replace cat = "cat4" if cat=="improved (no piped) - hwt"
	replace cat = "cat5" if cat=="improved (no piped) + chlorine/solar"
	replace cat = "cat6" if cat=="improved (no piped) + filter/boil" 
	replace cat = "cat7" if cat=="piped - hwt"
	replace cat = "cat8" if cat=="piped + chlorine/solar"
	replace cat = "cat9" if cat=="piped + filter/boil" **/

*********************************************************************************
***6. Merge draws of point of use intervention draws with water source draws**************
*********************************************************************************

	use `pou', clear
	merge 1:1 draw using `random_shuffle', keep(1 3) nogen
	
*************************************************************************************************
****7. Combine point of use and source RRs to generate new RRs for combined 9 categories of unsafe water*****
*************************************************************************************************

	**unimproved - hwt**
	gen rr_cat1 = 1/(rr_piped_hi_*rr_filter_)
	
	**unimproved + chlorine/solar**
	gen rr_cat2 = (rr_chlorine_)/(rr_piped_hi_*rr_filter_)
	
	**unimproved + filter/boil**
	gen rr_cat3 = (rr_filter_)/(rr_piped_hi_*rr_filter_)
	
	**improved(no piped) - hwt**
	gen rr_cat4 = (rr_improved_)/(rr_piped_hi_*rr_filter_)
	
	**improved(no piped) + chlorine/solar**
	gen rr_cat5 = (rr_improved_*rr_chlorine_)/(rr_piped_hi_*rr_filter_)
	
	**improved(no piped) + boil/filter**
	gen rr_cat6 = (rr_improved_*rr_filter_)/(rr_piped_hi_*rr_filter_)
	
	**piped - hwt**
	gen rr_cat7 = (rr_piped_lmi_)/(rr_piped_hi_*rr_filter_)
	
	**piped  + chlorine/solar**
	gen rr_cat8 = (rr_piped_lmi_*rr_chlorine_)/(rr_piped_hi_*rr_filter_)
	
	**piped + boil/filter
	gen rr_cat9 = (rr_piped_lmi_*rr_filter_)/(rr_piped_hi_*rr_filter_)
	**replace rr_cat9 = 1
	
	**high quality piped - hwt**
	gen rr_cat10 = (rr_piped_hi_)/(rr_piped_hi_*rr_filter_)

	**high quality piped + chlorine**
	gen rr_cat11 = (rr_piped_hi_*rr_chlorine_)/(rr_piped_hi_*rr_filter_)

	**high quality piped + chlorine**
	gen rr_cat12 = (rr_piped_hi_*rr_filter_)/(rr_piped_hi_*rr_filter_)
	
	keep draw rr_cat*

	
		**********************************************************************************************************************
		******Generate scatter plots to validate that the draws have been generated such that the correlation structure is kept intact********
		**********************************************************************************************************************
		//local m = `n' + 1
		//if `n' < 9 {
		//twoway scatter rr_cat`n' rr_cat`m'
		**graph export "$j/WORK/01_covariates/02_inputs/water_sanitation/graphs/rr/`region'_corr_`n'.png", replace
		//}
		forvalues n = 1/12 {
			preserve
				keep draw rr_cat`n'
				rename rr_cat`n' rr_
				gen cat = "cat`n'"
				reshape wide rr_, i(cat) j(draw)
				tempfile cat_`n'
				save `cat_`n'', replace
			restore
		}
			
		**Format data to save draws for RF template by GBD analytical region
		use `cat_1', clear
		forvalues n = 2/12 {
			append using `cat_`n''
			//tempfile all
			//save `all', replace
		}
		
		**********************************************************************************************************
		*****8. Generate summary measures i.e. mean and 95% uncertainty intervals for RRs for all 9 unsafe water categories*****
		**********************************************************************************************************
		fastrowmean rr_*, mean_var_name(mean)
		fastpctile rr_*, pct(2.5 97.5) names(lower upper)
	
	// Work around to duplicate out for each age_group_id
	local ages "2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 30 31 32 235"
	local age_app "3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 30 31 32 235"

	**Generate variables as needed in the final RF input template
	rename rr_1000 rr_0
	rename cat parameter
	gen risk = "`rf_new'"
	gen mortality = 1
	gen morbidity = 1
	gen cause_id = 302 // just diarrheal diseases
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
	**Save draws on clustertmp**
	***************************
	gen sex_id = .
	foreach sex in 1 2 {
		replace sex_id = `sex'
		export delimited "`out_dir'/rr_1_1990_`sex'.csv", replace
	}

	*************************************
	**Run save_results**
	*************************************
	local dat_dir "/share/epi/risk/temp/wash_water/rr"
	quietly run "/home/j/temp/central_comp/libraries/current/save_results.do"
	save_results, modelable_entity_id(9017) description(RR update-new network meta-in house) in_dir(`dat_dir') mark_best(yes) risk_type("rr")

*******************************
**********end of code***********
*******************************
