// File Name: compile_prev_results.do

// File Purpose: Compile all prevalence results into one file
// Author: Leslie Mallinger
// Date: 7/13/2011
// Edited on: 

// Additional Comments: 

clear all
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local root_folder "$root_folder"
local code_folder "`root_folder'/code/01_Data_Audit/07.Calculate Prevalence"
local dat_folder "`root_folder'/data/01_Data_Audit"
local survey_list "`dat_folder'/surveys_to_analyze.csv"
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


local prevtypes /* rough */ final
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
	**append using "`dat_folder'/WHO/prev_whosis.dta"
	**append using "`dat_folder'/UN Stats/prev_unstats.dta"
	**append using "C:/Users/asthak/Documents/Covariates/Water and Sanitation/data/JMP2013/prev_jmp_2013.dta"
	// append using "C:/Users/asthak/Documents/Covariates/Water and Sanitation/data/JMP2013/prev_jmp_IND_2013.dta"   
	append using "`dat_folder'/Other/prev_iran.dta"
	
	compress
	
	// remove observations without data
	drop if iwater_mean == . & isanitation_mean == . & ipiped_mean==. & isewer_mean==.
	
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
	
		** tag svy duplicates by startyear
		duplicates tag iso3 startyear svy, generate(tag)
		bysort iso3 startyear svy: egen num = seq()
		egen group = group(iso3 startyear svy)
		levelsof group if num > 1, local(grps) separate(",")
		edit if inlist(group, `grps')
		drop if inlist(filename, "census_indonesia_1980.dta", "census_indonesia_1990.dta", "census_mexico_2010.dta", "supas_indonesia_1995.dta", "supas_indonesia_1985.dta")
		drop if iso3=="IDN" & svytype=="Unknown" & startyear==1990
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
		
		**drop report duplicates**
		drop if iso3=="ARG" & startyear==2010 & svy=="Population and Housing Census"
		drop if iso3=="BHS" & startyear==2000 & svy=="CARICOM Population and Housing Census"
		drop if iso3=="BLZ" & startyear==2000 & svy=="CARICOM Population and Housing Census"
		drop if iso3=="JAM" & startyear==1991 & svytype=="Census"
		drop if iso3=="JAM" & startyear==1991 & svy=="Census"
		drop if iso3=="MWI" & startyear==1987 & svy=="Population and Housing Census"
		drop if iso3=="MLI" & startyear==1987 & svytype=="Census"
		drop if iso3=="IDN" & startyear==2010 & svy=="Population and Housing Census"
		drop if iso3=="URY" & startyear==1985 & svy=="Censo General de Poblacion y de Viviendas"
		drop if iso3=="GUY" & startyear==1991 & svy=="CARICOM Population and Housing Census"
		drop if iso3=="JAM" & startyear==2001 & svy=="CARICOM Population and Housing Census"
		drop if iso3=="LCA" & startyear==1980 & plot=="Report"
		drop if iso3=="LCA" & startyear==1991 & plot=="Report"
		drop if iso3=="TJK" & startyear==2007 & svy=="Living Standards Survey"
		drop if iso3=="NIC" & startyear==1995 & plot=="Report"
		drop if iso3=="NIC" & startyear==2005 & plot=="Report"
		drop if iso3=="SLV" & startyear==2007 & (svytype=="INT" | svytype=="Census")
		drop if iso3=="EGY" & startyear==2006 & svytype=="INT"
		drop if iso3=="KHM" & startyear==1996 & svy=="Socio-Economic Survey"
		drop if iso3=="KHM" & startyear==1997 & svy=="Socio-Economic Survey"
		drop if iso3=="ZWE" & startyear==2009 & svy=="Multiple Indicator Monitoring Survey"
		drop if iso3=="NGA" & startyear==2007 & svy=="General Household Survey"
		drop if iso3=="PER" & startyear==2009 & svytype=="INT"
		drop if iso3=="IDN" & filename=="IDN_DHS6_2012_HH_Y2013M09D25.DTA" /*there are two files for HH module*/


		**drop this for now and go back and fix when fixing report data extractions
		drop if iso3=="ETH" & startyear==1984

	// mark remaining subnational surveys
	replace subnational = 1 if region != ""
		
	// create plotting designations
	**gen plot=""
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

	
	//drop tabulated data from high income countries
	drop if inlist(plot, "WHOS Report", "UNSTATS", "WHOSIS")
	replace nopsu = "0" if plot == "IPUMS"
	
	// add countrycodes information
	drop ihme_country ihme_indic_country countryname
	merge m:1 iso3 using "`codes'", keep(1 3) nogen ///
		keepusing(indic_cod location_name location_id gbd_region_name gbd_superregion_name)
	
	//cause of death locations
	keep if indic_cod == 1 
	
	// save!
	save "`output_folder'/prev_all_`prevtype'.dta", replace
}

	
