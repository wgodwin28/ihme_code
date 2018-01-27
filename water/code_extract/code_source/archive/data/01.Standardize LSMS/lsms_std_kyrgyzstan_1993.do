** // File Name: lsms_std_kyrgyzstan_1993.do

** // File Purpose: Create standardized dataset with desired variables from LSMS Kyrgyzstan 1993 survey
** // Author: Leslie Mallinger
** // Date: 6/2/2010
** // Edited on: 

** // Additional Comments: 


** ** CURRENTLY BREAKS STATA -- UNCOMMENT WHEN IT WORKS AGAIN **


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
** local dat_folder_lsms "${j}/DATA/WB_LSMS"
** local dat_folder_lsms_merged "${data_folder}/LSMS/Merged Original Files"
** local codes_folder "${j}/Usable/Common Indicators/Country Codes"
** local dat_folder_country "KGZ/1993"



** ** water, sanitation dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/KGZ_LSMS_1993_HOUSEHOLD_QUEST.DTA", clear
	** tempfile hhserv
	** save `hhserv', replace
		** ** hid
	
** ** ** household weights dataset
	** ** use "`dat_folder_lsms'/`dat_folder_country'/POV_GH.DTA", clear
	** ** tempfile hhweight
	** ** save `hhweight', replace
		** ** ** nh and clust
		
** ** psu, urban/rural dataset
	** use "`dat_folder_lsms'/`dat_folder_country'/KGZ_LSMS_1993_HOUSEHOLD_CHARACTERISTICS.DTA", clear
	** tempfile hhpsu
	** save `hhpsu', replace
		** ** hid
	

** ** merge
** use `hhserv', clear
** merge 1:1 hid using `hhpsu'
** drop _merge
** ** merge 1:1 nh clust using `hhpsu'
** ** drop _merge


** ** create unified variables and apply labels
** gen wsource = .
** replace wsource = 1 if ac16_1 == 1	// indoor plumbing
** replace wsource = 2 if ac16_2 == 1 & wsource == .	// outdoor plumbing by your house
** replace wsource = 4 if ac16_4 == 1 & wsource == .	// communal water pump
** replace wsource = 5 if ac16_5 == 1 & wsource == .	// communal water well
** replace wsource = 3 if ac16_3 == 1 & wsource == .	// water well by your house
** replace wsource = 6 if ac16_6 == 1 & wsource == .	// natural spring
** replace wsource = 7 if ac16_7 == 1 & wsource == .	// river, lake, pond
** replace wsource = 8 if ac16_8 == 1 & wsource == .	// delivered by water distributor
** replace wsource = 9 if ac16_9 == 1 & wsource == .	// other sources
** label define wsource 1 "indoor plumbing" 2 "outdoor plumbing by your house" 3 "water well by your house" ///
	** 4 "communal water pump" 5 "communal water well" 6 "natural spring" 7 "river, lake, pond" ///
	** 8 "delivered by water distributor" 9 "other sources"
** label values wsource wsource


** ** save
** cd "`dat_folder_lsms_merged'"
** save "kyrgyzstan_1993", replace

