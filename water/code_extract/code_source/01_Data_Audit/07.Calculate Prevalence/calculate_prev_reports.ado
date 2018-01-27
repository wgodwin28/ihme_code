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
local dataloc "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Reports"
local keyloc "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Label Keys"
local keyversion "assigned_04082014"
local prevtype "final"
** *************************************************************************************************


** create locals for relevant files and folders
local codes_loc "J:/Usable/Common Indicators/Country Codes/countrycodes_official"
local urban_loc "J:/Data/UN_WORLD_POPULATION_PROSPECTS/2008"

** open report data
	// erase any old .dta files 
	//capture erase "`dataloc'/report_data.dta"
	
	/* **call StatTransfer from the command line to convert the .xlsx file to .dta
	capture confirm file "`dataloc'/report_data.xlsx"
	if ! _rc {
		! "C:/Apps/StatTransfer11-64/st.exe" "`dataloc'/report_data.xlsx" "`dataloc'/report_data.dta"
		sleep 300
	}
	else {
		display in red "WARNING: data transfer didn't work"
	}
	
	// open file
	use "`dataloc'/report_data.dta", clear*/
	
	//open file 
	import excel using "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/Reports/report_data.xlsx", firstrow clear
	
// Run program that allows the antiquated command "carryforward"

** get data into proper format
	// make sure all variables are filled in
	// carryforward countryname, replace
	replace countryname = "" if iso3 != ""
	// carryforward startyear, replace
	replace endyear = startyear if endyear == .
	// carryforward svy, replace
	// carryforward svytype, replace
	replace svy = trim(svy)
	
	// fill in iso3
	replace countryname = "Turks and Caicos Islands" if countryname == "Turks and Caicos"
	replace iso3 = "BWA" if iso3 == "BTW"
	replace iso3 = "GRD" if iso3 == "GRD "

	
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
	
	**drop percenturban percentrural A___Notes ihme_indic_country
	drop percenturban percentrural Notes ihme_indic_country
	
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
	
	//fix aggregated categories
	replace improved = 1 if iso3=="DOM" & (water_type=="Well" | water_type=="well")
	replace improved = 0.518 if iso3=="HTI" & (water_type=="Well in the yard" | water_type=="Wellsin the vicinity")
	replace improved = 0.761 if iso3 =="KGZ" & (water_type=="no piped water") 
	replace improved = 0.551 if iso3=="GTM" & (water_type=="well") 
	replace improved = 0.413 if iso3=="CAF" & water_type=="well"
	replace improved = 0.825 if iso3=="GNQ" & water_type=="well"
	replace improved = 0.715 if iso3=="KEN" & water_type=="Spring/well/borehole"
	replace improved = 0.342 if iso3=="MOZ" & water_type=="well"
	replace improved = 0.413 if iso3=="ZMB" & water_type=="Well/borehole"
	**replace improved = if iso3=="OMN" & (water_type=="well-outside house" | water_type=="well-inside house")
	replace improved = 0.125 if iso3=="KHM" & water_type=="dug well"
	replace improved = 0.821 if iso3=="MDV" & water_type=="Well"
	replace improved = 0.595 if iso3=="LSO" & water_type=="Spring"
	replace improved = 1 if iso3=="CPV" & water_type=="well"
	replace improved = 0.379 if iso3=="MRT" & water_type=="well"
	replace improved = 0.433 if iso3=="NGA" & water_type=="well"
	replace improved = 0.490 if iso3=="SLE" & water_type=="Well"
	
	
	
	//piped water
	gen piped = . 
	replace piped = 1 if water_std == "hhconnection"
	replace piped = 0 if ( water_std == "pubtapstandpipe" | ///
		water_std == "tubewellborehole" | water_std == "prowell" | water_std == "prospring" | ///
		water_std == "rainwater" | water_std == "improvedotherwater" | water_std == "unprowell" | water_std == "unprospring" | ///
		water_std == "carttruck" | water_std == "surface" | water_std == "unimprovedotherwater" | ///
		water_std == "otherwater" )
	
	replace piped = 1 if iso3=="GMB" & water_type=="Standpipe"
	replace piped = 0 if iso3=="DOM" & (water_type=="The aqueduct,public key" | water_type=="The aqueduct, public key")
	replace piped = 1 if iso3=="BWA" & startyear==1993 & water_type=="Standpipe outside plot/lolwapa"
	replace piped = 1 if iso3=="BWA" & startyear==2001 & water_type=="Stand pipe within plot"
	replace piped = 1 if iso3=="BWA" & startyear==2004 & (water_type=="Stand pipe within plot" | water_type=="neighbors stand pipe")
	replace piped = 1 if iso3=="BWA" & startyear==2008 & (water_type=="neighbors stand pipe" | water_type=="Stand pipe")
	replace piped = 0.539 if iso3=="BWA" & startyear==1981 & water_std=="hhconnection"
	replace piped = 0.319 if iso3=="GNQ" & water_type=="agua tuberia red publica fuera vivienda"
	replace piped = 0.885 if iso3=="TUN" & water_type=="piped"
	replace piped = 0 if iso3=="LSO" & water_type=="Piped Water Community"
	replace piped = 0.526 if iso3=="NAM" & water_type=="Piped water"
	replace piped = 0.385 if iso3=="SWZ" & water_type=="Tap"


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
	
	/*fix MWI*/
	replace improved = 0 if water_std=="unprotected, rain water" & iso3=="MWI" & svy=="CWIQ" 
	
	// calculate mean values for improvement for each survey
		** normalize non-missing categories to 1
		bysort group: egen water_totnormprev = total(water_prev) if improved != .
		
		** calculate prevalence
		gen iwater_mean = (water_prev/water_totnormprev * 100) * improved
		gen ipiped_mean = (water_prev/water_totnormprev*100) * piped
	
		collapse (sum) iwater_mean ipiped_mean (mean) water_totprev, by(countryname iso3 startyear endyear svy svytype)
		
		**fix odd reports**
		replace iwater_mean = water_totprev if svy=="National Risk and Vulnerability Assessment"
		replace ipiped_mean = . if svy=="National Risk and Vulnerability Assessment"
		replace iwater_mean = water_totprev if (iso3=="VNM" & startyear==2009)
		replace ipiped_mean = . if (iso3=="VNM" & startyear==2009)
		replace ipiped_mean = . if iso3=="MDV" & startyear==1985
		replace ipiped_mean = . if iso3=="CPV" & startyear==1990
		replace ipiped_mean = . if iso3=="BGD" & startyear==2009

	
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
	
		//fix aggregated categories - such as pit latrine that includes both covered and uncovered
		replace improved = 0.914 if iso3=="BLZ" & (sanitation_type=="Pit" | sanitation_type=="Pit latrine") 
		replace improved = 0.824 if iso3=="GUY" & (sanitation_type=="Pit latrine" | sanitation_type=="pit latrine") 
		replace improved = 0.396 if iso3=="HTI" & (sanitation_type=="Latrine forresidents andneighborhood" | sanitation_type=="Latrine forresidents only") 
		replace improved = 0.501 if iso3=="HTI" & (sanitation_type=="Holein the yard")
		replace improved = 0.946 if iso3=="TTO" & (sanitation_type=="Pit" | sanitation_type=="pit/latrine")
		replace improved = 0.960 if iso3=="HND" & (sanitation_type=="Simple pit latrine for use by a family" | sanitation_type=="Simple pit latrine for use by several families")
		replace improved = 0.937 if iso3=="PAN" & (sanitation_type=="In private-hole or latrine" | sanitation_type=="In shared-hole or latrine")
		replace improved = 0.331 if iso3=="CAF" & sanitation_type=="outdoor latrine"
		replace improved = 0.324 if iso3=="ETH" & (sanitation_type=="Pit latrine, private" | sanitation_type=="Pit latrine, shared" | sanitation_type=="private pit/latrine" | ///
				sanitation_type == "shared pit toilet latrine")
		replace improved = 0.358 if iso3=="KEN" & sanitation_type=="pit latrine"
		replace improved = 0.259 if iso3=="ZMB" & sanitation_type=="pit"
		replace improved = 0.549 if iso3=="LKA" & sanitation_type=="pit" /*MDV*/
		replace improved = 1 if iso3=="MDV" & sanitation_type=="Gifili"
		replace improved = 0.881 if iso3=="SWZ" & sanitation_type=="Pit"
		replace improved = 0.860 if iso3=="ZAF" & sanitation_type=="pit latrine"
		replace improved = 0.876 if iso3=="GMB" & (sanitation_type=="private pit toilet latrine" | sanitation_type=="public latrine" | sanitation_type=="public pit/latrine")
		replace improved = 0.723 if iso3=="NGA" & startyear==2006 & sanitation_type == "pit latrine"
		replace improved = 0.398 if iso3=="SLE" & sanitation_type=="Pit"
		replace improved = 0.719 if iso3=="TGO" & sanitation_type=="pit latrine"
		replace improved = 0.081 if iso3=="MWI" & (sanitation_type=="Covered Pit latrine" | sanitation_type=="Uncovered pit latrine" | sanitation_type=="Covered pit latrine")

		replace improved = 0.914 if iso3=="ATG" & (sanitation_type=="Pit Latrine" | sanitation_type=="Pit latrine") 
		replace improved = 0.914 if iso3=="BHS" & (sanitation_type=="Pit latrine" | sanitation_type=="pit latrine") 
		replace improved = 0.914 if iso3=="BRB" & (sanitation_type=="Pit" | sanitation_type=="pit")
		replace improved = 0.914 if iso3=="DMA" & (sanitation_type=="Pit" | sanitation_type=="Pit latrine") 
		replace improved = 0.914 if iso3=="GRD" & (sanitation_type=="Pit latrine" | sanitation_type=="Pit" | ///
			sanitation_type=="Pit latrine/VIP" | sanitation_type=="pit latrine") 	
		replace improved = 0.914 if iso3=="VCT" & (sanitation_type=="Pit" | sanitation_type=="Pit-latrine/VIP" | ///
			sanitation_type=="Pit latrine") 
			
		replace improved = 0.914 if iso3=="SLB" & (sanitation_type=="household pit" | sanitation_type=="communal pit toilet") 
		replace improved = 0.914 if iso3=="WSM" & (sanitation_type=="household pit" | sanitation_type=="communal pit toilet" | sanitation_type=="pit") 
		replace improved = 0.914 if iso3=="SYC" & (sanitation_type=="Pit toilet") 
		**replace improved = if iso3=="LSO" & (sanitation_type=="Pit latrine") 
		**replace improved = if iso3=="NER" & (sanitation_type=="latrine") 

		**using improved/unimproved pit ratio from zambia**
		replace improved = 0.343 if iso3=="BWA" & (sanitation_type=="Pit latrine" | sanitation_type=="Own pit latrine" | sanitation_type=="communal pit" | ///
			sanitation_type=="communal pit latrine" | sanitation_type=="neighbour's pit latrine" | sanitation_type=="own pit latrine" | sanitation_type=="pit latrine") 
			
		//define sewer
		gen sewer = . 
		replace sewer = 1 if sanitation_std == "pubsewer" | sanitation_std == "septic" | sanitation_std == "pourflush"
		replace sewer = 0 if sanitation_std == "simplepit" | sanitation_std == "vip" | ///
			sanitation_std == "composting" | sanitation_std == "improvedothersan" | sanitation_std == "bucket" | sanitation_std == "openlatrine" | ///
			sanitation_std == "hanging" | sanitation_std == "opendef" | sanitation_std == "othersan" | ///
			sanitation_std == "unimprovedothersan"
		
		//replace odd ball survey responses - for sewer 
		replace sewer = 1 if sanitation_type=="Water closet" & iso3=="ATG" & startyear==2001
		replace sewer = 1 if sanitation_type=="Sanitary" & iso3=="BGD" & startyear==2009
		replace sewer = 1 if sanitation_type=="WC not linked to sewer" & iso3=="BRB" & startyear==1990
		replace sewer = 1 if sanitation_type=="water closet" & iso3=="BRB" & startyear==1990
		replace sewer = 1 if sanitation_type=="water closet" & iso3=="BRB" & startyear==1990
		replace sewer = 1 if sanitation_type=="modern" & iso3=="CAF" & startyear==1988
		replace sewer = 1 if sanitation_type=="w.c" & iso3=="GMB" & startyear==1983
		replace sewer = 1 if sanitation_type=="WC" & iso3=="HTI" & startyear==2001
		replace sewer = 1 if (sanitation_type=="sewerage system" | sanitation_type=="septic tank") & iso3=="IND" & startyear==1998
		replace sewer = 1 if sanitation_type == "Water closet" & iso3=="IND" & startyear==2011
		replace sewer = 1 if sanitation_type=="water closet" & iso3=="JAM" & startyear==1991
		replace sewer = 1 if (sanitation_type=="WC Linked to Sewer" | sanitation_type=="WC not linked to sewer") & iso3=="JAM" & startyear==1991
		replace sewer = 1 if sanitation_type=="water closet" & iso3=="JAM" & startyear==2001
		replace sewer = 1 if sanitation_type=="water closet (WC)" & iso3=="NGA" & startyear==2006
		replace sewer = 1 if sanitation_type=="water closet" & iso3=="SUR" & startyear==2004
		replace sewer = 0 if (sanitation_type=="Latrine orcesspool" | sanitation_type=="washabletoilet") & iso3=="GTM" & startyear==2006
		replace sewer = 0 if (sanitation_type=="Washable toilet" | sanitation_type=="cesspool or latrine") & iso3=="GTM" & startyear==1981
		replace sewer = 0 if sanitation_type=="pour flush latrine (water seal type)" & iso3=="MUS" & startyear==1990


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
		gen isewer_mean = (sanitation_prev/sanitation_totnormprev*100) * sewer
		
		collapse (sum) isanitation_mean isewer_mean (mean) sanitation_totprev, by(countryname iso3 startyear endyear svy svytype)
		
		replace isewer_mean = . if isewer_mean == 0 
		replace isanitation_mean = . if isanitation_mean == 0 
		
		**drop duplicates
		drop if iso3=="PER" & svy=="DHS" & startyear==2009
	
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
replace ipiped_mean = ipiped_mean/100
replace isanitation_mean = isanitation_mean/100
replace isewer_mean = isewer_mean/100

drop *totprev
	
// Append on reports from 2013
preserve
import excel "`dataloc'/report_data_GBD2013.xlsx", firstrow clear
drop hwws_mean ss
local vars iwater ipiped isanitation isewer
foreach var of local vars {
	replace `var'_mean = `var'_mean/100
}
tempfile new_data
save `new_data', replace
restore
append using `new_data', force


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
