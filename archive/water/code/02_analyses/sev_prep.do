clear all
set more off

adopath + "J:\temp\central_comp\libraries\current\stata"

	get_demographics_template, gbd_team("cov") gbd_round_id(4) clear
	rename (location_ids age_group_ids sex_ids year_ids) (location_id age_group_id sex_id year_id)
	tempfile template
	save `template', replace

	get_location_metadata, location_set_id(22) clear
	keep location_id ihme_loc_id super_region_name region_name location_name level parent_id
	tempfile loc
	save `loc', replace

use "J:/temp/wgodwin/238.dta", clear
tempfile disc
save `disc', replace

use `template', clear
merge 1:1 age_group_id location_id sex_id year_id using `disc'
drop if _m == 2
drop _m
merge m:1 location_id using `loc', keep(1 3) nogen
save `disc', replace

use `disc', clear
replace mean_sev = logit(mean_sev)
replace lower_sev = logit(lower_sev)
replace upper_sev = logit(upper_sev)

bysort location_id: ipolate mean_sev year_id, gen(mean_2) epolate
replace mean_sev = mean_2 if year_id == 2016 | year_id < 1990
replace mean_sev = invlogit(mean_sev)

bysort location_id: ipolate lower_sev year_id, gen(lower_2) epolate
replace lower_sev = lower_2 if year_id == 2016 | year_id < 1990
replace lower_sev = invlogit(lower_sev)

bysort location_id: ipolate upper_sev  year_id, gen(upper_2) epolate
replace upper_sev = upper_2 if year_id == 2016 | year_id < 1990
replace upper_sev = invlogit(upper_sev)

tempfile interpolated
save `interpolated', replace

// For IDN KEN CHN ******BREASTFEEDING*****
local loc "KEN"
keep if regexm(ihme_loc_id, "`loc'")
forvalues x = 1980/2016 {
	foreach age in 3 4 {
		preserve
		keep if year_id == `x' & age_group_id == `age' & ihme_loc_id == "`loc'"
		local mean_`x'_`age' = mean_sev
		local lower_`x'_`age' = lower_sev
		local upper_`x'_`age' = upper_sev
		restore
	}
}

forvalues x = 1980/2016 {
	foreach age in 3 4 {
		replace mean_sev = `mean_`x'_`age'' if mean_sev == . & year_id == `x' & age_group_id == `age'
		replace lower_sev = `lower_`x'_`age'' if lower_sev == . & year_id == `x' & age_group_id == `age'
		replace upper_sev = `upper_`x'_`age'' if upper_sev == . & year_id == `x' & age_group_id == `age'
	}
}
tempfile `loc'
save ``loc'', replace

use `update', clear
drop if regexm(ihme_loc_id, "`loc'")
append using ``loc''
save `update', replace

replace tag = 1 if age_group_id == 3 | age_group_id == 4
replace mean_sev = 0 if tag != 1
replace upper_sev = 0 if tag != 1
replace lower_sev = 0 if tag != 1
replace mean_sev = 0 if mean_sev == .
replace upper_sev = 0 if upper_sev == .
replace lower_sev = 0 if lower_sev == .

**************Sanitation**************
// IDN CHN KEN GBR SAU USA BRA
// USA IDN KEN MEX SAU GBR ZAF JPN IND
keep if regexm(ihme_loc_id, "USA") |  regexm(ihme_loc_id, "IDN") |  regexm(ihme_loc_id, "KEN") |  regexm(ihme_loc_id, "MEX") |  regexm(ihme_loc_id, "SAU") |  regexm(ihme_loc_id, "GBR") |  regexm(ihme_loc_id, "ZAF") |  regexm(ihme_loc_id, "JPN") |  regexm(ihme_loc_id, "IND")
local loc "IND"
keep if regexm(ihme_loc_id, "`loc'")
sort location_id year_id age_group_id
forvalues x = 1980/2016 {
	preserve
	keep if year_id == `x' & ihme_loc_id == "`loc'"
	local mean_`x' = mean_sev
	local lower_`x' = lower_sev
	local upper_`x' = upper_sev
	restore
}

forvalues x = 1980/2016 {
	replace mean_sev = `mean_`x'' if mean_sev == . & year_id == `x'
	replace lower_sev = `lower_`x'' if lower_sev == . & year_id == `x'
	replace upper_sev = `upper_`x'' if upper_sev == . & year_id == `x'
}

tempfile `loc'
save ``loc'', replace

use `update', clear
drop if regexm(ihme_loc_id, "`loc'")
append using ``loc''
save `update', replace


levelsof location_id, local(loc_ids)
foreach local of local loc_ids {
	di in red `local'
	forvalues x = 1980/2016 {
		preserve
		keep if year_id == `x' & location_id == `local'
		sort location_id year_id age_group_id
		local mean_`x'_`loc' = mean_sev
		local lower_`x'_`loc' = lower_sev
		local upper_`x'_`loc' = upper_sev
		restore
	}
}

foreach local of local loc_ids {
di in red `local'
	forvalues x = 1990/2016 {
		replace mean_sev = `mean_`x'_`loc'' if mean_sev == . & year_id == `x' & location_id == `local'
		replace lower_sev = `lower_`x'_`loc'' if lower_sev == . & year_id == `x' & location_id == `local'
		replace upper_sev = `upper_`x'_`loc'' if upper_sev == . & year_id == `x' & location_id == `local'
	}
}
