// File Name: move_ipums.do

// File Purpose: Move IPUMS data from Project folder to J:/DATA
// Author: Leslie Mallinger
// Date: 7/8/2011
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 1500m
set maxvar 10000
set more off
capture log close
capture restore, not


** set relevant files and folders
local input_folder "${data_folder}/IPUMS"
local output_folder "J:/DATA/IPUMS_CENSUS"
local codes_folder "J:/Usable/Common Indicators/Country Codes"


** extract list of countries for which we have IPUMS data in the Project folder
local countries: dir "`input_folder'" dirs "*", respectcase
local numcountries: list sizeof countries
set obs `numcountries'
local obsnum = 1
gen countryname = ""
foreach country of local countries {
	replace countryname = "`country'" if _n == `obsnum'
	local obsnum = `obsnum' + 1
}
sort countryname
merge 1:1 countryname using "`codes_folder'/countrycodes_official.dta", nogen keep(3) keepusing(iso3)


mata: countries=st_sdata(.,("countryname", "iso3"))
forvalues i = 1/`numcountries' {
	mata: st_local("countryname", countries[`i', 1])
	mata: st_local("iso3", countries[`i', 2])
	
	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'"
	di "**********************************************************************************"
	
	capture confirm file "`input_folder'/`countryname'/`countryname'_wsh.dta"
	if ! _rc {
		use "`input_folder'/`countryname'/`countryname'_wsh.dta", clear
		levelsof year, local(years)
		foreach y of local years {
			preserve
				keep if year == `y'
				capture mkdir "`output_folder'/`iso3'/`y'"
				capture save "`output_folder'/`iso3'/`y'/`iso3'_IPUMS_`y'_WATER_SANITATION.DTA", replace
			restore
		}
		erase "`input_folder'/`countryname'/`countryname'_wsh.dta"
	}
}


