// File Name: calculate_prev_reports.do

// File Purpose: Categorize and calculate prevalence for report data
// Author: Leslie Mallinger
// Date: 2/3/2011
// Edited on: 

// Additional Comments: 


** define program name and syntax
capture program drop calculate_prev_reports
program define calculate_prev_reports

syntax, dataloc(string) keyloc(string) keyversion(string) prevtype(string)


** *************************************** NEW SECTION *********************************************
** // FOR DEBUGGING ONLY!
** local dataloc "J:/Project/COMIND/Water and Sanitation/Data Audit/Data/Reports"
** local keyloc "J:/Project/COMIND/Water and Sanitation/Data Audit/Data/Label Keys"
** local keyversion "assigned_08082011"
** local prevtype "final"
** *************************************************************************************************


** create locals for relevant files and folders
** local codes_loc "C:/Users/lmalling.IHME/Documents/Water and Sanitation/Useful Things/countrycodes_official"
** local urban_loc "C:/Users/lmalling.IHME/Documents/Water and Sanitation/Useful Things"
local codes_loc "J:/Usable/Common Indicators/Country Codes/countrycodes_official"
local urban_loc "J:/Data/UN_WORLD_POPULATION_PROSPECTS/2008"


** open report data
	// erase any old .dta files 
	capture erase "`dataloc'/report_data.dta"
	
	// call StatTransfer from the command line to convert the .xlsx file to .dta
	capture confirm file "`dataloc'/report_data.xlsx"
	if ! _rc {
		! "C:/Apps/StatTransfer11-64/st.exe" "`dataloc'/report_data.xlsx" "`dataloc'/report_data.dta"
		sleep 300
	}
	else {
		display in red "WARNING: data transfer didn't work"
	}
	
	// open file
	use "`dataloc'/report_data.dta", clear
	
	
** get data into proper format
	// make sure all variables are filled in
	carryforward countryname, replace
	replace countryname = "" if iso3 != ""
	carryforward startyear, replace
	replace endyear = startyear if endyear == .
	carryforward svy, replace
	carryforward svytype, replace
	replace svy = trim(svy)
	
	// fill in iso3
	replace countryname = "Turks and Caicos Islands" if countryname == "Turks and Caicos"
	replace iso3 = "BWA" if iso3 == "BTW"
	
	tempfile orig_data
	save `orig_data', replace
	
	preserve
		use "`codes_loc'", clear
		drop if countryname == "Burma" & countryname_ihme == "Burma"
		tempfile codes
		save `codes', replace
	restore
	
	merge m:1 countryname using `codes', keepusing(countryname_ihme iso3 ihme_indic_country) update
	drop if _merge == 2
	drop if ihme_indic_country == 0
	replace countryname = countryname_ihme if countryname_ihme != ""
	drop _merge ihme_indic_country countryname_ihme
	
	preserve
		use `codes', clear
		keep if countryname == countryname_ihme
		drop if iso3 == ""
		tempfile codes
		save `codes', replace
	restore
	merge m:1 iso3 using `codes', keepusing(countryname_ihme ihme_indic_country)
	drop if _merge == 2
	drop _merge
	replace countryname = countryname_ihme if countryname_ihme != ""
	drop if ihme_indic_country == 0
	drop countryname_ihme
	
	// cleanup and save
	drop if iso3 == "PAN" & startyear == 1970
	tempfile all_data
	save `all_data', replace
	
	
** prepare urban/rural data
	insheet using "`urban_loc'/UN_WPP_1950_2050_ANNUAL_POPULATION_INDICATORS.csv", clear

	// reduce to relevant variables and observations; calculate desired quantities
	keep if variant == "Medium"
	drop if location == "Micronesia"
	keep location time poptotal popurban
	rename location countryname
	rename time year
	drop if year < 1970 | year > 2015
	gen percenturban = popurban/poptotal
	drop poptotal popurban
	replace countryname = "Iran, Islamic Republic of" if regexm(countryname, "Iran")

	// add iso3 to urban/rural data for merging
	merge m:1 countryname using `codes', keepusing(countryname countryname_ihme ihme_indic_country iso3)
	drop if _merge == 1	// mostly regions rather than countries (but not all)
	drop if _merge == 2
	drop if ihme_indic_country != 1
	drop _merge countryname ihme_indic_country
	rename countryname_ihme countryname	
	rename year startyear
	
	// save
	tempfile urbrur
	save `urbrur', replace
	
	
** combine urban/rural estimates to make country-level estimates
	// combine all data and urban/rural breakdowns
	use `all_data', clear
	merge m:1 countryname startyear using `urbrur', keep(1 3) nogen
	
	// calculate percent rural
	gen percentrural = 1 - percenturban
	
	// calculate prevalence of each water and sanitation type based on proportions
	destring water_prev, replace force
	destring water_prev_urban, replace force
	gen water_prev_temp = (water_prev_urban * percenturban) + (water_prev_rural * percentrural)
	replace water_prev = water_prev_temp if water_prev == . & water_prev_temp != .
	drop water_prev_urban water_prev_rural water_prev_temp
	
	destring sanitation_prev, replace force
	destring sanitation_prev_rural, replace force
	gen sanitation_prev_temp = (sanitation_prev_urban * percenturban) + (sanitation_prev_rural * percentrural)
	replace sanitation_prev = sanitation_prev_temp if sanitation_prev == . & sanitation_prev_temp != .
	drop sanitation_prev_urban sanitation_prev_rural sanitation_prev_temp
	
	drop percenturban percentrural A___Notes ihme_indic_country
	
	tempfile all_data_urbrur
	save `all_data_urbrur', replace
	
	
** match water types with official categories
	use `all_data_urbrur', clear

	// reduce to just water information for now
	keep if water_type != ""
	replace water_type = trim(water_type)
	replace water_type = subinstr(water_type, " ", "", .)
	drop sanitation*
	gen water_std = ""
	replace water_type = trim(water_type)
	drop if water_prev == .
	drop if water_type == "Proportion with Access to Improved Water Source"
	
	// check that the proportions add up to 1 for each country-year
	sort iso3 startyear svy svytype
	egen group = group(iso3 startyear svy svytype)
	bysort group: egen water_totprev = total(water_prev)
	
	// save
	tempfile water
	save `water', replace
	
	// import standardized names for each water source type
	insheet using "`keyloc'/label_key_water_`keyversion'.csv", comma clear names
	foreach var of varlist hhconnection-unknownwater {
		preserve
			di "`var'"
			keep `var'
			rename `var' water_type
			drop if water_type == ""
			duplicates drop
			merge 1:m water_type using `water'
			replace water_std = "`var'" if _merge == 3
			drop if _merge == 1
			drop _merge
			tempfile water
			save `water', replace
		restore
	}
	use `water', clear
	
	// designate each category as improved, unimproved, etc.
	gen improved = .
	replace improved = 1 if water_std == "hhconnection" | water_std == "pubtapstandpipe" | ///
		water_std == "tubewellborehole" | water_std == "prowell" | water_std == "prospring" | ///
		water_std == "rainwater" | water_std == "improvedotherwater"
	replace improved = 0 if water_std == "unprowell" | water_std == "unprospring" | ///
		water_std == "carttruck" | water_std == "surface" | water_std == "unimprovedotherwater" | ///
		water_std == "otherwater"
	replace improved = 0.5 if water_std == "halfimprovedwater"
	if "`prevtype'" == "rough" {
		replace improved = 0.49 if water_std == "bottled"
	}
	else if "`prevtype'" == "final" {
		replace improved = 1 if water_std == "bottled"
	}
	else {
		di in red "WARNING: prevtype doesn't fall into one of the expected categories!"
	}
	
	// make sure that all entries are assigned a category
	count if water_std == ""
	if `r(N)' > 0 {
		di in red "WARNING: `r(N)' water entries haven't been assigned to categories!"
		preserve
			keep if water_std == ""
			keep water_type
			duplicates drop
			outsheet using "`keyloc'/water_to_categorize.csv", comma replace
		restore
	}
	
	// calculate mean values for improvement for each survey
		** normalize non-missing categories to 1
		bysort group: egen water_totnormprev = total(water_prev) if improved != .
		
		** calculate prevalence
		gen iwater_mean = (water_prev/water_totnormprev * 100) * improved
		collapse (sum) iwater_mean (mean) water_totprev, by(countryname iso3 startyear endyear svy svytype)
	
	// save water results
	tempfile water_results
	save `water_results', replace
	
	
** match toilet types with official categories
	use `all_data_urbrur', clear

	// reduce to just sanitation information for now
	keep if sanitation_type != ""
	replace sanitation_type = trim(sanitation_type)
	replace sanitation_type = subinstr(sanitation_type, " ", "", .)
	drop water*
	gen sanitation_std = ""
	replace sanitation_type = trim(sanitation_type)
	destring sanitation_prev, replace force
	drop if sanitation_prev == .
	
	// check that the proportions add up to 1 for each country-year
	sort iso3 startyear svy svytype
	egen group = group(iso3 startyear svy svytype)
	bysort group: egen sanitation_totprev = total(sanitation_prev)
	
	// save
	tempfile sanitation
	save `sanitation', replace
	
	// import standardized names for each water source type
	insheet using "`keyloc'/label_key_sanitation_`keyversion'.csv", comma clear names
	foreach var of varlist pubsewer-unknownsan {
		preserve
			di "`var'"
			keep `var'
			rename `var' sanitation_type
			drop if sanitation_type == ""
			duplicates drop
			merge 1:m sanitation_type using `sanitation'
			replace sanitation_std = "`var'" if _merge == 3
			drop if _merge == 1
			drop _merge
			tempfile sanitation
			save `sanitation', replace
		restore
	}
	use `sanitation', clear
	drop if countryname == "Western Samoa" & startyear == 1981
	drop if iso3 == "CPV" & startyear == 1990
	
	// designate each category as improved, unimproved, etc.
	gen improved = .
	replace improved = 1 if sanitation_std == "pubsewer" | 	sanitation_std == "septic" | ///
		sanitation_std == "pourflush" | sanitation_std == "simplepit" | sanitation_std == "vip" | ///
		sanitation_std == "composting" | sanitation_std == "improvedothersan"
	replace improved = 0 if sanitation_std == "bucket" | sanitation_std == "openlatrine" | ///
		sanitation_std == "hanging" | sanitation_std == "opendef" | sanitation_std == "othersan" | ///
		sanitation_std == "unimprovedothersan"
	replace improved = 0.5 if sanitation_std == "halfimprovedsan"
	
	// make sure that all entries are assigned a category
	count if sanitation_std == ""
	if `r(N)' > 0 {
		di in red "WARNING: `r(N)' sanitation entries haven't been assigned to categories!"
		preserve
			keep if sanitation_std == ""
			keep sanitation_type
			duplicates drop
			outsheet using "`keyloc'/sanitation_to_categorize.csv", comma replace
		restore
	}
		
	// calculate mean values for improvement for each survey
		** normalize non-missing categories to 1
		bysort group: egen sanitation_totnormprev = total(sanitation_prev) if improved != .
		
		** calculate prevalence
		gen isanitation_mean = (sanitation_prev/sanitation_totnormprev * 100) * improved
		collapse (sum) isanitation_mean (mean) sanitation_totprev, by(countryname iso3 startyear endyear svy svytype)
	
	// save water results
	tempfile sanitation_results
	save `sanitation_results', replace
	
	
** combine water and sanitation results
use `water_results', clear
merge 1:1 iso3 startyear svy using `sanitation_results', nogen
gen plot = "Census" if svytype == "Census"
replace plot = "Report" if plot == ""
tostring endyear, replace

** normalize to 0-1 scale
replace iwater_mean = iwater_mean/100
replace isanitation_mean = isanitation_mean/100

drop *totprev
	
** save
compress
save "`dataloc'/prev_reports_`prevtype'.dta", replace


** determine which country-years were dropped in this code
destring endyear, replace
merge 1:m iso3 startyear svy using `orig_data'
keep if _merge == 2
drop _merge
tab iso3
merge m:1 iso3 using `codes', keep(1 3) nogen
drop if ihme_indic_country != 1
levelsof iso3, local(isos) sep(", ")
use `orig_data', clear
bro if inlist(iso3, `isos')

end
