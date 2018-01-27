// File Name: tabulate_prop_uncertain.do

// File Purpose: Create a table with the proportion of households with facilities that are of uncertain improvement status
// Author: Leslie Mallinger
// Date: 8/5/2011
// Edited on: 

// Additional Comments: 
clear all
// macro drop _all
set mem 500m
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local compiled_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation/data/Compiled"


** open data, reduce to relevant entries
use "`compiled_folder'/prev_all_rough.dta", clear
keep if iwater_uncertain != . | isanitation_uncertain != .
drop if startyear < 1980
keep countryname iso3 startyear svy iwater_uncertain isanitation_uncertain gbd_region gbd_super_region_name
compress


** make year wide
rename iwater_uncertain water
rename isanitation_uncertain sanitation
reshape wide water sanitation, i(iso3 svy) j(startyear)
order gbd_super_region_name gbd_region countryname iso3 svy water* sanitation*, first
sort gbd_super_region_name gbd_region countryname


** save
save "`compiled_folder'/prop_uncertain_year_wide.dta", replace
outsheet using "`compiled_folder'/prop_uncertain_year_wide.csv", comma replace