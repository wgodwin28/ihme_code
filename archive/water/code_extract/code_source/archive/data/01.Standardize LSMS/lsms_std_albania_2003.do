// File Name: lsms_std_albania_2003.do

// File Purpose: Create standardized dataset with desired variables from LSMS Albania 2003 survey
// Author: Leslie Mallinger
// Date: 7/7/2010
// Edited on: 

// Additional Comments: 



clear all
// macro drop _all
set mem 500m
set more off
if "`c(os)'" == "Windows" {
	global j "J:"
}
else {
	global j "/home/j"
	set odbcmgr unixodbc
}


** create locals for relevant files and folders
local dat_folder_lsms "${j}/DATA/WB_LSMS"
local dat_folder_lsms_merged "${data_folder}/LSMS/Merged Original Files"
local codes_folder "${j}/Usable/Common Indicators/Country Codes"
local dat_folder_country "ALB/2003"



** water, sanitation dataset
	use "`dat_folder_lsms'/`dat_folder_country'/ALB_LSMS_2003_HH_ALL_W2", clear
	tempfile hhserv
	save `hhserv', replace
		** BHID
	
** apply labels
** B2B_Q01: main source of water for household
           ** 1 running water inside the dwelling
           ** 2 running water outside the dwelling
           ** 3 public tap
           ** 4 water truck
           ** 5 spring or well
           ** 6 river, lake, pond or similar
           ** 7 other

** B2B_Q06: drinking water source, only asked if main source for household is not suitable for drinking
           ** 1 running water inside the dwelling
           ** 2 running water outside the dwelling
           ** 3 public tab
           ** 4 water truck
           ** 5 spring or well
           ** 6 river, lake, pond  or similar
           ** 7 bottled water
           ** 8 other

gen wsource = B2B_Q01 if B2B_Q06 == .
replace wsource = 1 if B2B_Q06 == 1	// running water inside the dwelling
replace wsource = 2 if B2B_Q06 == 2	// running water outside the dwelling
replace wsource = 3 if B2B_Q06 == 3	// public tap
replace wsource = 4 if B2B_Q06 == 4	// water truck
replace wsource = 5 if B2B_Q06 == 5	// spring or well
replace wsource = 6 if B2B_Q06 == 6	// river, lake, pond, or similar
replace wsource = 7 if B2B_Q06 == 8	// other
replace wsource = 8 if B2B_Q06 == 7	// bottled water
label define wsource 1 "running water inside the dwelling" 2 "running water outside the dwelling" ///
	3 "water truck" 4 "public tap" 5 "spring or well" 6 "river, lake, pond or similar" 7 "other" ///
	8 "bottled water"
label values wsource wsource
label variable wsource "source of drinking water - complete"


** save
cd "`dat_folder_lsms_merged'"
save "albania_2003", replace
