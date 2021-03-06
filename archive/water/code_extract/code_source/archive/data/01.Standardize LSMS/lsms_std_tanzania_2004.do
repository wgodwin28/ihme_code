// File Name: lsms_std_tanzania_2004.do

// File Purpose: Create standardized dataset with desired variables from LSMS TZA 2004 survey
// Author: Leslie Mallinger
// Date: 5/27/2010
// Edited on: 

// Additional Comments: NOT NATIONALLY REPRESENTATIVE, SO NOT USED AT THIS TIME.


** clear all
** // macro drop _all
** set mem 500m
** set more off
** if "`c(os)'" == "Windows" {
	** global j "J:"
** }
** else {
	** global j "/home/j"
	** set odbcmgr unixodbc
** }


** ** create locals for relevant files and folders
** local dat_folder_lsms "${j}/Crude/Survey - Interview/LSMS"
** local dat_folder_lsms_merged "${data_folder}/LSMS/Merged Original Files"
** local codes_folder "${j}/Usable/Common Indicators/Country Codes"
** local dat_folder_country "CRUDE_INT_LSMS_TZA_2004_vdownloaded/Anthropometric, Mortality, Tracking, and Household"


** ** household weights dataset
	** // no household weights for this survey


** ** household location information
	** use "`dat_folder_lsms'/`dat_folder_country'/indtrackingform.dta", clear
	** tempfile hhloc
	** save `hhloc', replace
		** ** hh
	
** ** household services: water AND sanitation
	** use "`dat_folder_lsms'/`dat_folder_country'/hh.dta", clear
	** tempfile hhserv
	** save `hhserv', replace
		** ** hhid
	
	** // sanitation
	** use "`dat_folder_lsms'/`dat_folder_country'/F2B2.DTA", clear
	** tempfile hhsanitation
	** save `hhsanitation', replace
		** ** hhid


** ** merge
** use `hhloc', clear
** merge 1:1 hhid using `hhwater'
** drop _merge
** merge m:1 hhid using `hhsanitation'
** drop _merge


** ** save
** cd "`dat_folder_lsms_merged'"
** save "peru_1985", replace

