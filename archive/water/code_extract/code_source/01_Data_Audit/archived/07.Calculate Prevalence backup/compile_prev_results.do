// File Name: compile_prev_results.do

// File Purpose: Compile all prevalence results into one file
// Author: Leslie Mallinger
// Date: 7/13/2011
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
//set mem 500m
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local root_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation"
**local root_folder $root_folder
local code_folder "`root_folder'/code/data/07.Calculate Prevalence"
local dat_folder "`root_folder'/data"
**local survey_list "C:/Users/asthak/Documents/Covariates/Water and Sanitation/data/surveys_to_analyze.csv"
local survey_list "`dat_folder'/surveys_to_analyze.csv"
**local output_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation/data/Compiled"
local output_folder "`dat_folder'/Compiled"
local graph_folder "`root_folder'/graphs/prevalence"
local codes_folder "J:/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.DTA"

	
**prepping country codes
use "`codes_folder'", clear
drop if iso3==""
tempfile codes
save `codes', replace

** extract list of surveys to combine
insheet using "`survey_list'", comma clear names
mata: surveys=st_sdata(.,("survey", "dataloc"))
local num_obs = _N

local prevtypes rough final
foreach prevtype of local prevtypes {
	// combine surveys
	di in red "including `prevtype' prevalence:"
	forvalues i = 1/`num_obs' {
		mata: st_local("svy", surveys[`i', 1])
		mata: st_local("data_folder", surveys[`i', 2])
		di in red "     `svy'"
		if `i' == 1 {
			use "`data_folder'/prev_`svy'_`prevtype'", clear
		}
		else {
			append using "`data_folder'/prev_`svy'_`prevtype'", force
		}
	}
	
	append using "`dat_folder'/Reports/prev_reports_`prevtype'.dta" 
	append using "`dat_folder'/MICS/prev_mics1.dta"
	append using "`dat_folder'/WHO/prev_whosis.dta"
	append using "`dat_folder'/UN Stats/prev_unstats.dta"
	append using "C:/Users/asthak/Documents/Covariates/Water and Sanitation/data/JMP2013/prev_jmp_2013.dta"
	append using "C:/Users/asthak/Documents/Covariates/Water and Sanitation/data/JMP2013/prev_jmp_IND_2013.dta"   
	append using "`dat_folder'/Other/prev_iran.dta"
	
	compress
	
	// remove observations without data
	drop if iwater_mean == . & isanitation_mean == .
	
	// remove duplicated estimates
		**make sure new sudan files are properly named**
		replace iso3 = "SDN" if regexm(filename, "SUDAN_NORTH") 
		replace startyear = 1989 if regexm(filename, "SUDAN_NORTH") 
		replace endyear = "1990" if regexm(filename, "SUDAN_NORTH")
		replace svy = "DHS" if regexm(filename, "SUDAN_NORTH")
		replace svyver_real = 1 if regexm(filename, "SUDAN_NORTH")
		replace module = "HH" if regexm(filename, "SUDAN_NORTH")
		replace version = "Y2013M08D13" if regexm(filename, "SUDAN_NORTH")
		replace ihme_country = 1 if regexm(filename, "SUDAN_NORTH")
		
		replace iso3 = "SSD" if regexm(filename, "SUDAN_SOUTH")
		replace startyear = 1989 if regexm(filename, "SUDAN_SOUTH")
		replace endyear = "1990" if regexm(filename, "SUDAN_SOUTH")
		replace svy = "DHS" if regexm(filename, "SUDAN_SOUTH")
		replace svyver_real = 1 if regexm(filename, "SUDAN_SOUTH")
		replace module = "HH" if regexm(filename, "SUDAN_SOUTH")
		replace version = "Y2013M08D13" if regexm(filename, "SUDAN_SOUTH")
		replace ihme_country = 1 if regexm(filename, "SUDAN_SOUTH")
		
		drop if regexm(filename, "SUDAN_OTHER")
		
	**fix ZAF IPUMS 2007 with missing info
		replace iso3 = "ZAF" if regexm(filename, "ZAF_COMMUNITY_SURVEY")
		replace startyear = 2007 if regexm(filename, "ZAF_COMMUNITY_SURVEY")
		replace endyear = "2007" if regexm(filename, "ZAF_COMMUNITY_SURVEY")
		replace ihme_country = 1 if regexm(filename, "ZAF_COMMUNITY_SURVEY")
		
		** standardize svy variable
		replace svy = "CENSUS" if svy == "CEN"
		replace svytype = "INT" if svytype == "Survey-Household"
		
		** tag and number entries that are duplicates by startyear and country
		duplicates tag iso3 startyear svy, generate(tag)
		bysort iso3 startyear svy (svytype): egen num = seq()
		
		** remove duplicate JMP entries
		drop if num > 1 & svytype == "JMP"
		drop tag num
		
		** tag and number entries that are duplicates by endyear and country
		duplicates tag iso3 endyear svy, generate(tag)
		bysort iso3 endyear svy (svytype): egen num = seq()
		
		** remove duplicate JMP entries
		drop if num > 1 & svytype == "JMP"
		drop tag num

		** tag svy duplicates by startyear
		duplicates tag iso3 startyear svy, generate(tag)
		bysort iso3 startyear svy: egen num = seq()
		egen group = group(iso3 startyear svy)
		levelsof group if num > 1, local(grps) separate(",")
		edit if inlist(group, `grps')
		drop if inlist(filename, "census_indonesia_1980.dta", "census_indonesia_1990.dta", "census_mexico_2010.dta")
		drop tag num
		
		** tag svy duplicates by endyear
		duplicates tag iso3 endyear svy, generate(tag)
		tab tag
			// okay
		drop tag
		
		** tag IPUMS/JMP census duplicates
		replace svytype = "IPUMS" if regexm(filepath_full, "IPUMS")
		replace svy = "CENSUS" if svytype == "IPUMS"
		duplicates tag iso3 startyear svy, gen(tag)
		bysort iso3 startyear svy (svytype): egen num = seq()
		drop if num > 1 & svytype == "JMP"
		drop tag num
		replace svy = "IPUMS" if svytype == "IPUMS"
		
		**tag DHS/JMP duplicates
		
		
		**tag DHS/RHS duplicates
		

	// mark remaining subnational surveys
	replace subnational = 1 if region != ""
		
	// create plotting designations
	replace plot = "MICS" if svy == "MICS" & svytype != "JMP"
	replace plot = "DHS" if svy == "DHS" & svytype != "JMP"
	replace plot = "RHS" if svy == "RHS" & svytype != "JMP"
	replace plot = "WHS" if svy == "WHS" & svytype != "JMP"
	replace plot = "LSMS" if svy == "LSMS" & svytype != "JMP"
	replace plot = "IPUMS" if svy == "IPUMS"
	replace plot = "Census" if plot == "Census"
	replace plot = "JMP" if svytype == "JMP"
	replace plot = "WHO Report" if svy == "WHO" & svytype == "JMP"
	replace plot = "WHOSIS" if svy == "WHOSIS"
	replace plot = "UNSTATS" if svy == "UNSTATS"
	replace plot = "Other Survey" if plot == ""
	replace plot = "Subnational" if subnational == 1
	replace plot = "Report" if dattype == "REPORT" & plot == "Other Survey"	

	drop if inlist(plot, "WHS", "WHO Report", "UNSTATS", "WHOSIS")
	replace nopsu = "0" if plot == "IPUMS"
	
	// add countrycodes information
	drop ihme_country ihme_indic_country countryname 
	drop gbd* location*
	merge m:1 iso3 using "`codes'", keep(1 3) nogen ///
		keepusing(indic_cod location_name location_id gbd_region_name gbd_superregion_name)
		
	keep if indic_cod == 1
	
	// save!
	save "`output_folder'/prev_all_`prevtype'.dta", replace
}

	
