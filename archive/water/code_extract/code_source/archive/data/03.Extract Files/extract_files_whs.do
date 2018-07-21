// File Name: extract_files_whs.do

// File Purpose: Extract appropriate survey datasets from WHS surveys
// Author: Leslie Mallinger
// Date: 5/24/10
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
local log_folder "${code_folder}"
local dat_folder_whs "J:/DATA/WHO_WHS"
local dat_folder_whs_merged "${data_folder}/WHS/Merged Original Files"
local dat_folder_new_whs "${data_folder}/WHS"
local codes_folder "J:/Usable/Common Indicators/Country Codes"

capture mkdir "`dat_folder_new_whs'"
capture mkdir "`dat_folder_whs_merged'"


** extract survey file paths into mata, then put them into Stata
local types INDIV ID
foreach x of local types {
	clear
	clear mata
	// initialize mata vector
	local maxobs 1000
	mata: filepath_full = J(`maxobs', 1, "")
	mata: filedir = J(`maxobs', 1, "")
	mata: filename = J(`maxobs', 1, "")
	local obsnum = 1

	// loop through directories and extract files and file paths
	local iso_list: dir "`dat_folder_whs'" dirs "*", respectcase
	foreach i of local iso_list {
		// extract `x' surveys with upper-case DTA
		local filenames: dir "`dat_folder_whs'/`i'" files "*`x'*DTA", respectcase
		foreach f of local filenames {
			mata: filepath_full[`obsnum', 1] = "`dat_folder_whs'/`i'/`f'"
			mata: filedir[`obsnum', 1] = "`dat_folder_whs'/`i'"
			mata: filename[`obsnum', 1] = "`f'"
			local obsnum = `obsnum' + 1
		}
		
		// extract `x' surveys with lower-case DTA
		local filenames: dir "`dat_folder_whs'/`i'" files "*`x'*dta", respectcase
		foreach f of local filenames {
			mata: filepath_full[`obsnum', 1] = "`dat_folder_whs'/`i'/`f'"
			mata: filedir[`obsnum', 1] = "`dat_folder_whs'/`i'"
			mata: filename[`obsnum', 1] = "`f'"
			local obsnum = `obsnum' + 1
		}
	}
	
	getmata filepath_full filedir filename
	drop if filepath_full == ""
	
	
** parse each part of the filename into informative variables
	local fileregex "^([a-zA-Z]+)[_]+([a-zA-Z]+)[_]+([0-9]+)[_]*([0-9]*)[_]+([a-zA-Z]+)"
	
	// iso3
	gen iso3 = regexs(1) if regexm(filename, "`fileregex'")
	
	// survey
	gen svy = regexs(2) if regexm(filename, "`fileregex'")
	
	// years
	gen startyear = regexs(3) if regexm(filename, "`fileregex'")
	gen endyear = regexs(4) if regexm(filename, "`fileregex'")
	replace endyear = startyear if endyear == ""
	
	// region
	gen region = regexs(5) if regexm(filename, "`fileregex'")
	replace region = "HH_WEALTH" if region == "HH"
	replace region = "" if region == "`x'"

	// survey type
	gen svytype = "INT"
	
	// module
	gen module = "`x'"
	
	drop if region != ""
	

	** link with country information
	preserve
		use "`codes_folder'/countrycodes_official.dta", clear
		keep if countryname == countryname_ihme
		drop if iso3 == ""
		tempfile codes
		save `codes', replace
	restore
	merge m:1 iso3 using `codes', keepusing(countryname ihme_country)
	drop if _merge == 2
	drop if ihme_country != 1
	drop _merge


	** organize
	order countryname iso3 ihme_country, first
	sort countryname
	
	if "`x'" == "ID" {
		rename filename filename2
	}

	tempfile whs_files_`x'
	save `whs_files_`x'', replace
}	
	

** combine tempfiles to get one dataset with filenames for both INDIV and ID files
use `whs_files_INDIV', clear
merge 1:1 iso3 startyear using `whs_files_ID', keep(3) nogen
tempfile whs_files
save `whs_files', replace

	
** extract survey year from dataset and merge relevant files
	mata: whs_files=st_sdata(.,("countryname", "iso3", "filedir", "filename", "filename2"))
	local maxobs = _N
	
	// loop through files
	forvalues filenum = 1(1)`maxobs' {
		** create locals with file-specific information, then display it
		mata: st_local("countryname", whs_files[`filenum', 1])
		mata: st_local("iso3", whs_files[`filenum', 2])
		mata: st_local("filedir", whs_files[`filenum', 3])
		mata: st_local("filename", whs_files[`filenum', 4])
		mata: st_local("filename2", whs_files[`filenum', 5])

		display "countryname: `countryname'" _newline "filenum: `filenum'"
		
		** open file with water and sanitation information
		use "`filedir'/`filename'", clear
		
		** merge weights and strata information
		merge 1:1 id using "`filedir'/`filename2'", keep(3) nogen
		mata: filename[`filenum', 1] = "`iso3'.dta"
		
		** apply labels for water and sanitation variables
		capture confirm variable q4042
		if _rc == 0 {
			label define wsource 1 "Piped water through house connection or yard" 2 "Public standpipe" ///
				3 "Protected tube well or bore hole" 4 "Protected dug well or protected spring" ///
				5 "Unprotected dug well or spring" 6 "Rainwater (into tank or cistern)" ///
				7 "Water taken directly from pond-water or stream" 8 "Tanker-truck, vendor"
			label values q4042 wsource
		}

		capture confirm variable q4043
		if _rc == 0 {
			label define wtime 1 "Less than 5 minutes" 2 "Between 5 to 30 minutes" 3 "Between 30 to 60 minutes" ///
				4 "Between 60 to 90 minutes" 5 "More than 90 minutes"
			label values q4043 wtime
		}
		
		capture confirm variable q4045
		if _rc == 0 {
			label define ttype 1 "Flush to piped sewage system" 2 "Flush to septic tank" 3 "Pour flush latrine" ///
				4 "Covered dry latrine (with privacy)" 5 "Uncovered dry latrine (without privacy)" ///
				6 "Bucket latrine (where fresh excreta are manually removed)" 7 "No facilities (open defecation)" ///
				8 "Other"
			label values q4045 ttype
		}
		
		save "`dat_folder_whs_merged'/`iso3'.dta", replace
	}
	

** open dataset with files, cleanup
use `whs_files', clear

replace filedir = "`dat_folder_whs_merged'"
replace filename = iso3 + ".dta"
replace filepath_full = filedir + "/" + filename
replace module = ""
drop filename2

	
** organize and save
order countryname iso3 ihme_country startyear endyear, first
sort countryname startyear

cd "`dat_folder_new_whs'"
save "datfiles_whs", replace


capture log close