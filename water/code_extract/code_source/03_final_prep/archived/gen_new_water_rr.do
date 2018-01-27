**Purpose: Generate Relative Risks for new WASH categories
**Author: Astha KC
**Date: September 30 2014

**The relative risks used to estimate burden for WASH were extracted from two papers. 
**RRs for water faciltities & household water treatments were extracted from a meta-regression conducted by Wolf et al (2014)
**We combine these relative risks to generate RRs for our exposure categories that combine exposure to water facility with household water treatment practices. 
**We assume that high income settings like central/eastern europe and high income latin america; So we need to save region-specific RRs for water categories
**We use relative risks that havent been adjusted for non-blinding in order to be consistent with other relative risks in the GBD CRA analysis. 
**The calculation below generate the combined relative risks and their uncertainty intervals

clear all
set more off

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
	local country_codes "$j/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"
	
// Prep regional codes 
	use "`country_codes'", clear
	keep gbd_analytical_region_local gbd_analytical_region_name
	duplicates drop 
	sort gbd_analytical_region_local
	tempfile region_codes
	save `region_codes', replace 
	levelsof(gbd_analytical_region_local), local(regions)
	
	**Effect of household water treatment practices extracted from the paper
	**filter/boil - most effective treatment
	local rr_filter = 0.53
	local upper_filter = 0.41
	local lower_filter = 0.67

	**chlorine/solar - less effective
	local rr_chlorine = 0.82
	local upper_chlorine = 0.69
	local lower_chlorine = 0.96

	**effect of improving water source types
	**improved community source
	local rr_improved = 0.89
	local upper_improved = 0.78
	local lower_improved = 1.01

	**piped water supply in low/middle income countries; defined as "basic piped supply" by Wolf et al 2014. 
	local rr_piped_lmi  = 0.77
	local upper_piped_lmi = 0.64 
	local lower_piped_lmi = 0.92

	**piped water supply in high income countries (for our analysis - this applies to central/eastern europe and high income latin america); defined as "piped water, higher quality*" by Wolf et al 2014.
	**for now use the same for all regions instead of the reported 0.19 (0.07-0.50) 
	local rr_piped_hi = 0.19
	local upper_piped_hi = 0.07
	local lower_piped_hi = 0.50

	**Calculate new RRs for new categories that comibe effect of water source with water treatment practices
	clear
	set obs 3
	gen id = _n

	gen rr_mean = `rr_piped_lmi'	if id==1
	gen rr_lower = `lower_piped_lmi' if id==1
	gen rr_upper = `upper_piped_lmi'	if id==1
	gen cat = "piped" if id==1

	replace rr_mean = `rr_improved' if id==2
	replace rr_upper = `upper_improved' if id==2
	replace rr_lower = `lower_improved' if id==2
	replace cat = "improved (no piped)" if id==2

	replace rr_mean = 1 if id==3
	replace rr_lower= 1 if id==3
	replace rr_upper = 1 if id==3
	replace cat = "unimproved" if id==3
	drop id

//Generate region-specific relative risks 
	foreach region of local regions {
		preserve
		gen region = "`region'"
		
		if "`region'"=="R1" {
			tempfile r_specific
			save `r_specific', replace
			}
		else {
			append using `r_specific'
			save `r_specific', replace
			}
		restore
	}

	**replace piped water rrs  by region
	/*Southern Latin America = R13; Eastern Europe = R9; Central Europe = R8*/
	use `r_specific', replace 
	replace rr_mean = `rr_piped_hi' if (region=="R13" | region=="R8" | region=="R9") & cat=="piped"
	replace rr_upper = `upper_piped_hi' if (region=="R13" | region=="R8" | region=="R9") & cat=="piped"
	replace rr_lower = `lower_piped_hi' if (region=="R13" | region=="R8" | region=="R9") & cat=="piped"

	**calculate the variance in log space 
	gen log_var_filter = ((ln(`upper_filter')-ln(`lower_filter'))/(2*1.96))^2
	gen log_var_chlorine = ((ln(`upper_chlorine')-ln(`lower_chlorine'))/(2*1.96))^2
	gen log_var_rr = ((ln(rr_upper)-ln(rr_lower))/(2*1.96))^2

	**label all new exposure categories after combining handwashing
	expand 3
	bysort region cat: gen id = _n
	replace cat = cat + " - hwt" if id == 1
	replace cat = cat + " + chlorine/solar" if id == 2
	replace cat = cat + " + filter/boil" if id == 3

	**calculate the combined RRs 
	replace rr_mean = rr_mean * `rr_chlorine' if id == 2 /*combine excess risk of the absence of hwt practice*/
	replace rr_mean = rr_mean * `rr_filter' if id == 3
	replace rr_upper = . if (id==2 | id==3)
	replace rr_lower = . if (id==2 | id==3)

	**estimate uncertainty intervals for new combined categories
	gen log_var = log_var_chlorine + log_var_rr if id == 2
	replace log_var = log_var_filter + log_var_rr if id==3
	gen log_se = sqrt(log_var)

	replace rr_upper = rr_mean * exp(1.96*log_se) if (id == 2 | id==3)
	replace rr_lower = rr_mean / exp(1.96*log_se) if (id == 2 | id==3)

	sort rr_mean
	keep cat *mean *lower *upper region
	order *mean *lower *upper region, first 

	**define reference rr
	preserve
	keep if cat=="piped + filter/boil" & region == "R9"
		local rr_ref = rr_mean 
		local upper_ref = rr_upper
		local lower_ref = rr_lower
	restore

	**generate inverse of RRs because we model excess risk 
	gen rr = rr_mean / `rr_ref'
	gen new_lower = rr_upper/`upper_ref'
	gen new_upper = rr_lower/`lower_ref'
	drop rr_upper rr_lower rr_mean
	rename (rr new_lower new_upper) (rr_mean rr_lower rr_upper)
	order rr_mean rr_lower rr_upper, last
	
	replace rr_mean = 1 if cat=="piped + filter/boil"
	replace rr_upper = 1 if cat=="piped + filter/boil"
	replace rr_lower = 1 if cat=="piped + filter/boil"
	sort region cat
	
	**define cat variable to match exposure
	replace cat = "cat1" if cat=="unimproved - hwt"
	replace cat = "cat2" if cat=="unimproved + chlorine/solar"
	replace cat = "cat3" if cat=="unimproved + filter/boil"
	replace cat = "cat4" if cat=="improved (no piped) - hwt"
	replace cat = "cat5" if cat=="improved (no piped) + chlorine/solar"
	replace cat = "cat6" if cat=="improved (no piped) + filter/boil" 
	replace cat = "cat7" if cat=="piped - hwt"
	replace cat = "cat8" if cat=="piped + chlorine/solar"
	replace cat = "cat9" if cat=="piped + filter/boil"
	rename cat parameter

******************
****end of code****
******************
