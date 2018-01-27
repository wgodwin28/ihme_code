// File Name: count_sources.do

// File Purpose: Count number of usable sources per country per decade
// Author: Leslie Mallinger
// Date: 5/19/10
// Edited on: 

// Additional Comments: 


clear all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local dat_folder "J:/Project/COMIND/Water and Sanitation/Smoothing/Spacetime Input"
local output_folder "J:/Project/COMIND/Water and Sanitation/Mapping"
local codes_folder "J:/Usable/Common Indicators/Country Codes"
local pop_folder "J:/Data/UN_WORLD_POPULATION_PROSPECTS/2008"


** open countrycodes file, reduce to country name and iso3 for IHME countries
use "`codes_folder'/countrycodes_official.dta", clear
keep if countryname == countryname_ihme
drop if iso3 == ""
keep if ihme_indic_country == 1
keep countryname countryname_ihme iso3 gbd_region gbd_developing

tempfile num_sources_shell
save `num_sources_shell'


** ** open and prepare population data
** insheet using "`pop_folder'/UN_WPP_1950_2050_POPULATION_BY_AGE_ANNUAL.csv", comma clear

** keep if time == 2010 & sex == "Both" & variant == "Medium"
** egen population = rowtotal(pop_0_4-pop_80_100)
** rename location countryname
** keep countryname population

** tempfile pop
** save `pop'


** ** merge countrynames and population data
** use `num_sources_shell', clear
** merge 1:1 countryname using `pop'
** drop if _merge == 2
** drop _merge
** save `num_sources_shell', replace


** open prevalence file, drop non-usable entries or double-counted entries
use "`dat_folder'/watsan_data_full.dta", clear


** categorize by decade
rename startyear year
tostring year, replace
gen decade = regexs(0) + "0" if regexm(year, "[0-9][0-9][0-9]")
destring year decade, replace

**drop data points before 1980
drop if year<1980

** reduce to counts of datapoints 
**Water and Sanitation**
collapse (count) iwater_mean isanitation_mean, by(location_name iso3 decade)
rename iwater_mean wsources
rename isanitation_mean ssources
rename icombined_mean csources

**Breastfeeding**
collapse (count) ABFrate0to5 EBFrate0to5 predBFrate0to5 partBFrate0to5 ABFrate12to15 ABFrate6to23, by(location_name iso3 decade)
reshape wide ABFrate0to5 EBFrate0to5 predBFrate0to5 partBFrate0to5 ABFrate12to15 ABFrate6to23, i(location_name iso3) j(decade)
collapse(rawsum) ABFrate0to51980 EBFrate0to51980 predBFrate0to51980 partBFrate0to51980 ABFrate12to151980 ABFrate6to231980 ABFrate0to51990 EBFrate0to51990 ///
	predBFrate0to51990 partBFrate0to51990 ABFrate12to151990 ABFrate6to231990 ABFrate0to52000 EBFrate0to52000 predBFrate0to52000 partBFrate0to52000 ///
	ABFrate12to152000 ABFrate6to232000 ABFrate0to52010 EBFrate0to52010 predBFrate0to52010 partBFrate0to52010 ABFrate12to152010 ABFrate6to232010
	
**Underweight**
collapse (count) weightforage_2sdneg, by(location_name iso3 decade)
rename weightforage_2sdneg wfa2_sources
reshape wide wfa2_sources, i(location_name iso3) j(decade)
collapse(rawsum) wfa2_sources1980 wfa2_sources1990 wfa2_sources2000 wfa2_sources2010

collapse (count) weightforheight_2sdneg, by(location_name iso3 decade)
rename weightforheight_2sdneg wfh2_sources
reshape wide wfh2_sources, i(location_name iso3) j(decade)
collapse(rawsum) wfh2_sources1980 wfh2_sources1990 wfh2_sources2000 wfh2_sources2010

** move decades to wide from long
reshape wide wsources ssources, i(location_name iso3) j(decade)


/** save count file, then merge with file with all IHME countries
tempfile counts
save `counts', replace
use `num_sources_shell', clear
merge 1:1 iso3 using `counts'
drop _merge */


** create total count for each country
egen wsources_tot = rowtotal(wsources*)
egen ssources_tot = rowtotal(ssources*)
egen csources_tot = rowtotal(csources*)

**count # of sources for each decade
collapse (rawsum) wsources1980 ssources1980 wsources1990 ssources1990 wsources2000 ssources2000 wsources2010 ssources2010

** organize and clean up
** gsort -gbd_developing -population
foreach var of varlist wsources1970-csources2000 {
	replace `var' = . if `var' == 0
}

** reduce to counts of datapoints
collapse (count) wsources1970 ssources1970 wsources1980 ssources1980 wsources1990 ssources1990 wsources2000 ssources2000 wsources2010 ssources2010

** save
save "`output_folder'/num_sources.dta", replace


** ** export spreadsheet with source information for 10 most populous countries
** use "`dat_folder'/prev_all.dta", clear
** keep if iso3 == "BGD" | iso3 == "BRA" | iso3 == "CHN" | iso3 == "IDN" | iso3 == "IND" | iso3 == "MEX" ///
	** | iso3 == "NGA" | iso3 == "PAK" | iso3 == "PHL" | iso3 == "VNM"
** outsheet using "sources_biggest_countries.csv", comma replace

