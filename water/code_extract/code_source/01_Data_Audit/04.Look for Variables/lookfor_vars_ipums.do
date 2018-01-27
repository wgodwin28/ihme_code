// File Name: lookfor_vars_ipums.do

// File Purpose: Look for appropriate variables in IPUMS censuses
// Author: Leslie Mallinger
// Date: 7/11/2011
// Edited on: 

// Additional Comments: 


clear all
set mem 1000m
set maxvar 10000
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local dat_folder_new_ipums "${data_folder}/IPUMS"


** open dataset and store data in a mata matrix
use "`dat_folder_new_ipums'/datfiles_ipums", clear
mata: files=st_sdata(.,("countryname", "filedir", "filename", "startyear"))
local maxobs = _N


** create a vector for each of the variables of interest
local vars psu weight urban w_srcedrnk t_type
foreach var of local vars {
	mata: `var' = J(`maxobs', 1, "")
}


** loop through survey files, looking for and saving relevant variables in each one
forvalues filenum = 1(1)`maxobs' {
	// save countryname and filename as locals, then print to keep track of position in the loop
	mata: st_local("countryname", files[`filenum', 1])
	mata: st_local("filedir", files[`filenum', 2])
	mata: st_local("filename", files[`filenum', 3])
	mata: st_local("startyear", files[`filenum', 4])
	di _newline _newline "**********************************************************************************"
	di "countryname: `countryname'" _newline "year: `startyear'" _newline "filename: `filename'"
	di "**********************************************************************************"
	
	// open file (only first 50 observations for speed)
	use "`filedir'/`filename'" if _n < 50, clear
	
	** look for variables of interest and save in appropriate vector
		// primary sampling unit
		lookfor "primary sampling unit" "psu" "segment" "grappe"
		mata: psu[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "cluster number" "upm"
			mata: psu[`filenum', 1] = "`r(varlist)'"
		}
		
		// sample weight
		lookfor "sample weight" "ponder" "poids" "household weight"
		mata: weight[`filenum', 1] = "`r(varlist)'"
		
		// urban/rural
		lookfor "type of place of residence" "urban"
		mata: urban[`filenum', 1] = "`r(varlist)'"
		if "`r(varlist)'" == "" {
			lookfor "area"
			mata: urban[`filenum', 1] = "`r(varlist)'"
		}
		
		// source of drinking water
		lookfor "watsrc" "watsup"
		mata: w_srcedrnk[`filenum', 1] = "`r(varlist)'"
		
		// type of toilet facility
		lookfor "sewage" "toilet"
		mata: t_type[`filenum', 1] = "`r(varlist)'"
}


** move variables from Mata into Stata datset
use "`dat_folder_new_ipums'/datfiles_ipums", clear
capture getmata `vars'
if _rc != 0 {
	di "mata vector(s) too long"
	pause
}
save "`dat_folder_new_ipums'/varlist_temp_ipums", replace


use "`dat_folder_new_ipums'/varlist_temp_ipums", clear	// FIXME remove this line eventually	
** replace variables to mark surveys that are lacking both water and toilet information

** gen noinfo = 0
** replace noinfo = 1 if (iso3 == "GHA" & startyear == 2007) | (iso3 == "COL" & startyear == 2009)
	** // variables but not labels for COL 2009
** gen noinfo = (w_srcedrnk == "")

** foreach var of local vars {
	** replace `var' = "NOINFO" if noinfo == 1
** }
	
	
** clean up entries with more than one variable listed
	
	gen new_file = 0
	replace new_file = 1 if regexm(filename, "_WATER_SAN_")
	
	// psu
	bro psu if regexm(psu, " ")
		** no psu variable
		
	// weight
	bro weight if regexm(weight, " ")
	
	// urban
	replace urban = "urban" if regexm(urban, "urban")
	bro urban if regexm(urban, " ")
		** lacking urban for 21/136 entries
	
	// w_srcedrnk
	replace w_srcedrnk = "ar80a_watsup" if iso3=="ARG" & startyear=="1980"
	replace w_srcedrnk = "ar91a_watsrc" if iso3=="ARG" & startyear=="1991"
	replace w_srcedrnk = "ar01a_watcook" if iso3=="ARG" & startyear=="2001"
	replace w_srcedrnk = "ar10a_watsrc" if iso3=="ARG" & startyear=="2010"
	replace w_srcedrnk = "am01a_watsrc" if iso3=="ARM" & startyear=="2001"
	replace w_srcedrnk = "watsup" if iso3=="AUT" & startyear=="1981"
	replace w_srcedrnk = "at91a_watsup" if iso3=="AUT" & startyear=="1991"
	replace w_srcedrnk = "at01a_watsup" if iso3=="AUT" & startyear=="2001"
	replace w_srcedrnk = "bo76a_watsrc" if iso3=="BOL" & startyear=="1976"
	replace w_srcedrnk = "bo92a_watsrc" if iso3=="BOL" & startyear=="1992"
	replace w_srcedrnk = "bo01a_watsrc" if iso3=="BOL" & startyear=="2001"
	
	replace w_srcedrnk = "watsrc" if iso3=="BRA" & startyear=="1980"
	replace w_srcedrnk = "br91a_water" if iso3=="BRA" & startyear=="1991"
	replace w_srcedrnk = "br00a_water" if iso3=="BRA" & startyear=="2000"
	replace w_srcedrnk = "kh98a_water" if iso3=="KHM" & startyear=="1998"
	replace w_srcedrnk = "kh08a_watsrc" if iso3=="KHM" & startyear=="2008"
	replace w_srcedrnk = "cl82a_watsup" if iso3=="CHL" & startyear=="1982"
	replace w_srcedrnk = "cl92a_watsrc" if iso3=="CHL" & startyear=="1992"
	replace w_srcedrnk = "cl02a_watsrc" if iso3=="CHL" & startyear=="2002"
	replace w_srcedrnk = "co85a_watsrc" if iso3=="COL" & startyear=="1985"
	replace w_srcedrnk = "co93a_watsrc" if iso3=="COL" & startyear=="1993"
	replace w_srcedrnk = "co05a_watsrc" if iso3=="COL" & startyear=="2005"
	replace w_srcedrnk = "cr84a_watsrc" if iso3=="CRI" & startyear=="1984"
	replace w_srcedrnk = "cr00a_watsrc" if iso3=="CRI" & startyear=="2000"
	replace w_srcedrnk = "ec82a_watersrc" if iso3=="ECU" & startyear=="1982"
	replace w_srcedrnk = "ec90a_watersrc" if iso3=="ECU" & startyear=="1990"
	replace w_srcedrnk = "ec01a_watersrc" if iso3=="ECU" & startyear=="2001"
	replace w_srcedrnk = "ec10a_watsrc" if iso3=="ECU" & startyear=="2010"
	replace w_srcedrnk = "eg96a_watsrc" if iso3=="EGY" & startyear=="1996"
	replace w_srcedrnk = "eg06a_watsrc" if iso3=="EGY" & startyear=="2006"
	replace w_srcedrnk = "sv92a_watsup" if iso3=="SLV" & startyear=="1992"
	replace w_srcedrnk = "sv07a_watersrc" if iso3=="SLV" & startyear=="2007" & new_file == 1
	replace w_srcedrnk = "" if iso3=="FRA" & startyear=="1999"
	replace w_srcedrnk = "fr82a_watsup" if iso3=="FRA" & startyear=="1982"
	replace w_srcedrnk = "" if iso3=="FRA" & startyear=="1990"
	replace w_srcedrnk = "gh00a_water" if iso3=="GHA" & startyear=="2000"
	replace w_srcedrnk = "gr81a_water" if iso3=="GRC" & startyear=="1981"
	replace w_srcedrnk = "gr91a_water" if iso3=="GRC" & startyear=="1991"
	replace w_srcedrnk = "gr01a_water" if iso3=="GRC" & startyear=="2001"
	replace w_srcedrnk = "gn83a_watsup" if iso3=="GIN" & startyear=="1983"
	replace w_srcedrnk = "gn96a_watsup" if iso3=="GIN" & startyear=="1996"
	replace w_srcedrnk = "hu80a_watsup" if iso3=="HUN" & startyear=="1980" 
	replace w_srcedrnk = "hu90a_watsup" if iso3=="HUN" & startyear=="1990"
	replace w_srcedrnk = "hu01a_watsup" if iso3=="HUN" & startyear=="2001"
	replace w_srcedrnk = "id80a_wtrdrink" if iso3=="IDN" & startyear=="1980" & new_file==1
	replace w_srcedrnk = "id85a_wtrdrink" if iso3=="IDN" & startyear=="1985" & new_file==1
	replace w_srcedrnk = "id90a_wtrdrink" if iso3=="IDN" & startyear=="1990" & new_file==1
	replace w_srcedrnk = "id95a_wtrdrink" if iso3=="IDN" & startyear=="1995" & new_file==1
	replace w_srcedrnk = "id05a_watsrc" if iso3=="IDN" & startyear=="2005" & new_file==1
	replace w_srcedrnk = "id10a_watdrink" if iso3=="IDN" & startyear=="2010" & new_file==1
	replace w_srcedrnk = "ir06a_watdrink" if iso3=="IRN" & startyear=="2006" & new_file==0
	replace w_srcedrnk = "watsup" if iso3=="ITA" & startyear=="2001"
	replace w_srcedrnk = "" if iso3=="ISR" & startyear=="1983"
	replace w_srcedrnk = "iq97a_watsrc" if iso3=="IRQ" & startyear=="1997"
	replace w_srcedrnk = "jm82a_watsup" if iso3=="JAM" & startyear=="1982"
	replace w_srcedrnk = "jm91a_watsup" if iso3=="JAM" & startyear=="1991"
	replace w_srcedrnk = "jm01a_watsup" if iso3=="JAM" & startyear=="2001"
	replace w_srcedrnk = "jo04a_watsrc" if iso3=="JOR" & startyear=="2004"
	replace w_srcedrnk = "ke89a_watsrc" if iso3=="KEN" & startyear=="1989"
	replace w_srcedrnk = "ke99a_water" if iso3=="KEN" & startyear=="1999"
	replace w_srcedrnk = "watsup" if iso3=="KGZ" & startyear=="1999"
	replace w_srcedrnk = "mw87a_waterwet1" if iso3=="MWI" & startyear=="1987"
	replace w_srcedrnk = "mw98a_watsrcw1" if iso3=="MWI" & startyear=="1998"
	replace w_srcedrnk = "mw08a_watrwet" if iso3=="MWI" & startyear=="2008"
	replace w_srcedrnk = "my91a_watsup" if iso3=="MYS" & startyear=="1991"
	replace w_srcedrnk = "my00a_watsrc" if iso3=="MYS" & startyear=="2000"
	replace w_srcedrnk = "ml87a_watsrc" if iso3=="MLI" & startyear=="1987"
	replace w_srcedrnk = "ml98a_watsrc" if iso3=="MLI" & startyear=="1998"
	replace w_srcedrnk = "mx90a_watsrc" if iso3=="MEX" & startyear=="1990"
	replace w_srcedrnk = "mx95a_watpipe" if iso3=="MEX" & startyear=="1995"
	replace w_srcedrnk = "mx00a_watsrc" if iso3=="MEX" & startyear=="2000"
	replace w_srcedrnk = "mx05a_watsrc1" if iso3=="MEX" & startyear=="2005"
	replace w_srcedrnk = "mx10a_pipedwtr" if iso3=="MEX" & startyear=="2010" & new_file==1
	replace w_srcedrnk = "mn89a_watsup" if iso3=="MNG" & startyear=="1989"
	replace w_srcedrnk = "mn00a_watsup" if iso3=="MNG" & startyear=="2000"
	replace w_srcedrnk = "watsup" if iso3=="MAR" & startyear=="1982" & new_file==0
	replace w_srcedrnk = "watsup" if iso3=="MAR" & startyear=="1994" & new_file==0
	replace w_srcedrnk = "watsup" if iso3=="MAR" & startyear=="2004" & new_file==0
	replace w_srcedrnk = "np01a_watsrc" if iso3=="NPL" & startyear=="2001"
	replace w_srcedrnk = "watsup" if iso3=="NIC"
	replace w_srcedrnk = "ps07a_watsrc" if iso3=="PSE" & startyear=="2007"
	replace w_srcedrnk = "pa80a_watsup" if iso3=="PAN" & startyear=="1980"
	replace w_srcedrnk = "pa90a_watsrc" if iso3=="PAN" & startyear=="1990"
	replace w_srcedrnk = "pa00a_watsup" if iso3=="PAN" & startyear=="2000"
	replace w_srcedrnk = "pe93a_watsup" if iso3=="PER" & startyear=="1993"
	replace w_srcedrnk = "pe07a_watsrc" if iso3=="PER" & startyear=="2007" & new_file==0
	replace w_srcedrnk = "ph90a_water" if iso3=="PHL" & startyear=="1990"
	replace w_srcedrnk = "ph00a_watdrink" if iso3=="PHL" & startyear=="2000"
	replace w_srcedrnk = "pt81a_watsup" if iso3=="PRT" & startyear=="1981"
	replace w_srcedrnk = "pt91a_watsup" if iso3=="PRT" & startyear=="1991"
	replace w_srcedrnk = "pt01a_water" if iso3=="PRT" & startyear=="2001"
	replace w_srcedrnk = "pr80a_watersrc" if iso3=="PRI" & startyear=="1980" & new_file==0
	replace w_srcedrnk = "pr90a_watersrc" if iso3=="PRI" & startyear=="1990" & new_file==0
	replace w_srcedrnk = "rw91a_watsrc" if iso3=="RWA" & startyear=="1991"
	replace w_srcedrnk = "rw02a_watsrc" if iso3=="RWA" & startyear=="2002"
	replace w_srcedrnk = "lc80a_watsup" if iso3=="LCA" & startyear=="1980"
	replace w_srcedrnk = "lc91a_watsup" if iso3=="LCA" & startyear=="1991"
	replace w_srcedrnk = "sn88a_watsrc" if iso3=="SEN" & startyear=="1988"
	replace w_srcedrnk = "sn02a_watsrc" if iso3=="SEN" & startyear=="2002"
	replace w_srcedrnk = "sl04a_watsrc" if iso3=="SLE" & startyear=="2004"
	replace w_srcedrnk = "si02a_water" if iso3=="SVN" & startyear=="2002"
	replace w_srcedrnk = "za96a_water" if iso3=="ZAF" & startyear=="1996"
	replace w_srcedrnk = "za01a_watsrc" if iso3=="ZAF" & startyear=="2001"
	replace w_srcedrnk = "za07a_watsrc" if iso3=="ZAF" & startyear=="2007"
	replace w_srcedrnk = "watsup" if iso3=="ESP" & startyear=="1990"
	replace w_srcedrnk = "watsup" if iso3=="ESP" & startyear=="2001"
	replace w_srcedrnk = "ss08a_watsrc" if iso3=="SDN" & startyear=="2008"
	replace w_srcedrnk = "tz88a_watsrc" if iso3=="TZA" & startyear=="1988"
	replace w_srcedrnk = "tz02a_watsrc" if iso3=="TZA" & startyear=="2002"
	replace w_srcedrnk = "th80a_watsup" if iso3=="THA" & startyear=="1990"
	replace w_srcedrnk = "th90a_water" if iso3=="THA" & startyear=="1990"
	replace w_srcedrnk = "th00a_water" if iso3=="THA" & startyear=="2000"
	replace w_srcedrnk = "watsup" if iso3=="TUR" & startyear=="2000"
	replace w_srcedrnk = "us80a_watersrc" if iso3=="USA" & startyear=="1980"
	replace w_srcedrnk = "us90a_watersrc" if iso3=="USA" & startyear=="1990"
	replace w_srcedrnk = "us00a_plumbing" if iso3=="USA" & startyear=="2000"
	replace w_srcedrnk = "us05a_plumbing" if iso3=="USA" & startyear=="2005"
	replace w_srcedrnk = "ug91a_water" if iso3=="UGA" & startyear=="1991"
	replace w_srcedrnk = "ug02a_watsrc" if iso3=="UGA" & startyear=="2002"
	replace w_srcedrnk = "uy85a_watsrc" if iso3=="URY" & startyear=="1985"
	replace w_srcedrnk = "uy96a_watsrc" if iso3=="URY" & startyear=="1996"
	replace w_srcedrnk = "uy06a_watsrc" if iso3=="URY" & startyear=="2006"
	replace w_srcedrnk = "ve81a_watersrc" if iso3=="VEN" & startyear=="1981"
	replace w_srcedrnk = "ve90a_watersrc" if iso3=="VEN" & startyear=="1990"
	replace w_srcedrnk = "ve01a_watsup" if iso3=="VEN" & startyear=="2001"
	replace w_srcedrnk = "vn89a_watersrc" if iso3=="VNM" & startyear=="1989"
	replace w_srcedrnk = "vn99a_water" if iso3=="VNM" & startyear=="1999"
	replace w_srcedrnk = "ro02a_water" if iso3=="ROU" & startyear=="2002"
	replace w_srcedrnk = "ro92a_water" if iso3=="ROU" & startyear=="1992"
	
	// t_type
	replace t_type = "ar80a_bathrm" if iso3=="ARG" & startyear=="1980"
	replace t_type = "ar91a_toilet" if iso3=="ARG" & startyear=="1991"
	replace t_type = "toilet" if iso3=="ARG" & startyear=="2001"
	replace t_type = "ar10a_sewage" if iso3=="ARG" & startyear=="2010"
	replace t_type = "am01a_toilet" if iso3=="ARM" & startyear=="2001"
	replace t_type = "toilet" if iso3=="AUT" & startyear=="1981"
	replace t_type = "toilet" if iso3=="AUT" & startyear=="1991"
	replace t_type = "at01a_toilet" if iso3=="AUT" & startyear=="2001"
	replace t_type = "toilet" if iso3=="BLR" & startyear=="1999"
	replace t_type = "bo76a_sewage" if iso3=="BOL" & startyear=="1976"
	replace t_type = "bo92a_toilet" if  iso3=="BOL" & startyear=="1992"
	replace t_type = "toilet sewage" if iso3=="BOL" & startyear=="2001"
	
	replace t_type = "sewage" if iso3=="BRA" & startyear=="1980"
	replace t_type = "sewage" if iso3=="BRA" & startyear=="1991"
	replace t_type = "sewage" if iso3=="BRA" & startyear=="2000"
	replace t_type = "toilet" if iso3=="KHM" & startyear=="1998"
	replace t_type = "kh08a_toilet" if iso3=="KHM" & startyear=="2008"
	replace t_type = "toilet" if iso3=="CHL" & startyear=="1982"
	replace t_type = "toilet" if iso3=="CHL" & startyear=="1992"
	replace t_type = "cl02a_toilet" if iso3=="CHL" & startyear=="2002"
	replace t_type = "co85a_toilet" if iso3=="COL" & startyear=="1985"
	replace t_type = "co93a_toilet" if iso3=="COL" & startyear=="1993"
	replace t_type = "co05a_toilet" if iso3=="COL" & startyear=="2005"
	replace t_type = "cr84a_toilet" if iso3=="CRI" & startyear=="1984"
	replace t_type = "toilet" if iso3=="CRI" & startyear=="2000"
	replace t_type = "ec82a_toilet" if iso3=="ECU" & startyear=="1982"
	replace t_type = "ec90a_toilet" if iso3=="ECU" & startyear=="1990"
	replace t_type = "toilet" if iso3=="ECU" & startyear=="2001"
	replace t_type = "ec10a_toilet" if iso3=="ECU" & startyear=="2010"
	replace t_type = "toilet" if iso3=="EGY" & startyear=="1996"
	replace t_type = "toilet" if iso3=="EGY" & startyear=="2006"
	replace t_type = "toilet" if iso3=="SLV" & startyear=="1992"
	replace t_type = "toilet" if iso3=="SLV" & startyear=="2007" & new_file==1
	replace t_type = "fr82a_toilet" if iso3=="FRA" & startyear=="1982"
	replace t_type = "fr90a_toilet" if iso3=="FRA" & startyear=="1990"
	replace t_type = "fr99a_toilet" if iso3=="FRA" & startyear=="1999"
	replace t_type = "gh00a_toilet" if iso3=="GHA" & startyear=="2000"
	replace t_type = "gr81a_toilet" if iso3=="GRC" & startyear=="1981"
	replace t_type = "gr91a_toilet" if iso3=="GRC" & startyear=="1991"
	replace t_type = "gr01a_toilet" if iso3=="GRC" & startyear=="2001"
	replace t_type = "" if iso3=="GIN" & startyear=="1983"
	replace t_type = "gn96a_toilet" if iso3=="GIN" & startyear=="1996"
	replace t_type = "toilet" if iso3=="HUN" & startyear=="1980"
	replace t_type = "toilet" if iso3=="HUN" & startyear=="1990"
	replace t_type = "toilet" if iso3=="HUN" & startyear=="2001"
	replace t_type = "id05a_toilet" if iso3=="IDN" & startyear=="2005" & new_file == 1 
	replace t_type = "id80a_toilet" if iso3=="IDN" & startyear=="1980" & new_file == 1 
	replace t_type = "id85a_toilet" if iso3=="IDN" & startyear=="1985" & new_file == 1
	replace t_type = "id90a_toilet" if iso3=="IDN" & startyear=="1990" & new_file == 1
	replace t_type = "id95a_toilet" if iso3=="IDN" & startyear=="1995" & new_file == 1
	replace t_type = "id05a_toilet" if iso3=="IDN" & startyear=="2005" & new_file == 1
	replace t_type = "id10a_toilet" if iso3=="IDN" & startyear=="2010" & new_file == 1
	replace t_type = "toilet" if iso3=="IRN" & startyear=="2006" & new_file==0
	replace t_type = "toilet" if iso3=="ITA" & startyear=="2001"
	replace t_type = "toilet" if iso3=="ISR" & startyear=="1983"
	replace t_type = "iq97a_toilet" if iso3=="IRQ" & startyear=="1997"
	replace t_type = "jm82a_toilet" if iso3=="JAM" & startyear=="1982"
	replace t_type = "jm91a_toilet" if iso3=="JAM" & startyear=="1991"
	replace t_type = "jm01a_toilet" if iso3=="JAM" & startyear=="2001"
	replace t_type = "jo04a_sewer" if iso3=="JOR" & startyear=="2004"
	replace t_type = "ke89a_sewage" if iso3=="KEN" & startyear=="1989"
	replace t_type = "ke99a_sewage" if iso3=="KEN" & startyear=="1999"
	replace t_type = "sewage" if iso3=="KGZ" & startyear=="1999"
	replace t_type = "mw87a_toilet1" if iso3=="MWI" & startyear=="1987"
	replace t_type = "mw98a_toilet1" if iso3=="MWI" & startyear=="1998"
	replace t_type = "mw08a_toilet" if iso3=="MWI" & startyear=="2008"
	replace t_type = "my91a_toilet" if iso3=="MYS" & startyear=="1991"
	replace t_type = "my00a_toilet" if iso3=="MYS" & startyear=="2000"
	replace t_type = "ml87a_toilet" if iso3=="MLI" & startyear=="1987"
	replace t_type = "ml98a_toilet" if iso3=="MLI" & startyear=="1998"
	replace t_type = "toilet" if iso3=="MEX" & startyear=="1990"
	replace t_type = "mx95a_toilet" if iso3=="MEX" & startyear=="1995"
	replace t_type = "mx00a_flush" if iso3=="MEX" & startyear=="2000"
	replace t_type = "mx05a_sewer" if iso3=="MEX" & startyear=="2005"
	replace t_type = "toilet" if iso3=="MEX" & startyear=="2010" & new_file==1
	replace t_type = "" if iso3=="MNG" & startyear=="1989" /*fix this!!!**/
	replace t_type = "mn00a_toilet" if iso3=="MNG" & startyear=="2000" 
	replace t_type = "toilet" if iso3=="MAR" & startyear=="1982" & new_file==0
	replace t_type = "toilet" if iso3=="MAR" & startyear=="1994" & new_file==0
	replace t_type = "toilet" if iso3=="MAR" & startyear=="2004" & new_file==0
	replace t_type = "np01a_toilet" if iso3=="NPL" & startyear=="2001"
	replace t_type = "toilet" if iso3=="NIC" 
	replace t_type = "ps07a_toilet" if iso3=="PSE" & startyear=="2007"
	replace t_type = "pa80a_sewer" if iso3=="PAN" & startyear=="1980"
	replace t_type = "pa90a_sewer" if iso3=="PAN" & startyear=="1990"
	replace t_type = "toilet" if iso3=="PAN" & startyear=="2000"
	replace t_type = "toilet" if iso3=="PER" & startyear=="1993"
	replace t_type = "toilet" if iso3=="PER" & startyear=="2007" & new_file==0
	replace t_type = "ph90a_toilet" if iso3=="PHL" & startyear=="1990"
	replace t_type = "ph00a_toilet" if iso3=="PHL" & startyear=="2000"
	replace t_type = "pt81a_toilet" if iso3=="PRT" & startyear=="1981"
	replace t_type = "pt91a_toilet" if iso3=="PRT" & startyear=="1991"
	replace t_type = "pt01a_toilet" if iso3=="PRT" & startyear=="2001"
	replace t_type = "toilet" if iso3=="PRI" & startyear=="1980" & new_file==0
	replace t_type = "toilet" if iso3=="PRI" & startyear=="1990" & new_file==0
	replace t_type = "rw91a_toilet" if iso3=="RWA" & startyear=="1991"
	replace t_type = "rw02a_toilet" if iso3=="RWA" & startyear=="2002"
	replace t_type = "lc91a_toilet" if iso3=="LCA" & startyear=="1991"
	replace t_type = "lc80a_toilet" if iso3=="LCA" & startyear=="1980"
	replace t_type = "sn88a_toilet" if iso3=="SEN" & startyear=="1988"
	replace t_type = "sn02a_toilet" if iso3=="SEN" & startyear=="2002"
	replace t_type = "sl04a_toilet" if iso3=="SLE" & startyear=="2004"
	replace t_type = "si02a_toilet" if iso3=="SVN" & startyear=="2002"
	replace t_type = "za96a_toilet" if iso3=="ZAF" & startyear=="1996"
	replace t_type = "za01a_toilet" if iso3=="ZAF" & startyear=="2001"
	replace t_type = "za07a_toilet" if iso3=="ZAF" & startyear=="2007"
	replace t_type = "es01a_sewage" if iso3=="ESP" & startyear=="2001"
	replace t_type = "es91a_toilet" if iso3=="ESP" & startyear=="1990"
	replace t_type = "ss08a_toilet" if iso3=="SDN" & startyear=="2008"
	replace t_type = "tz88a_toilet" if iso3=="TZA" & startyear=="1988"
	replace t_type = "tz02a_toilet" if iso3=="TZA" & startyear=="2002"
	replace t_type = "th80a_toilet" if iso3=="THA" & startyear=="1980"
	replace t_type = "th90a_toilet" if iso3=="THA" & startyear=="1990"
	replace t_type = "th00a_toilet" if iso3=="THA" & startyear=="2000"
	replace t_type = "toilet" if iso3=="TUR" & startyear=="2000"
	replace t_type = "toilet" if iso3=="GBR" & startyear=="1991"
	replace t_type = "us80a_sewage" if iso3=="USA" & startyear=="1980"
	replace t_type = "us90a_sewage" if iso3=="USA" & startyear=="1990"
	replace t_type = "" if iso3=="USA" & startyear=="2000"
	replace t_type = "" if iso3=="USA" & startyear=="2005"
	replace t_type = "ug91a_toilet" if iso3=="UGA" & startyear=="1991"
	replace t_type = "ug02a_toilet" if iso3=="UGA" & startyear=="2002"
	replace t_type = "uy85a_toilet" if iso3=="URY" & startyear=="1985"
	replace t_type = "uy96a_toilet" if iso3=="URY" & startyear=="1996"
	replace t_type = "uy06a_sewer" if iso3=="URY" & startyear=="2006"
	replace t_type = "ve81a_toilet" if iso3=="VEN" & startyear=="1981"
	replace t_type = "ve90a_toilet" if iso3=="VEN" & startyear=="1990"
	replace t_type = "ve01a_sewer" if iso3=="VEN" & startyear=="2001"
	replace t_type = "vn89a_toilet" if iso3=="VNM" & startyear=="1989"
	replace t_type = "vn99a_toilet" if iso3=="VNM" & startyear=="1999" 
	replace t_type = "sewage" if iso3=="ROU" & startyear=="1992"
	replace t_type = "toilet" if iso3=="ROU" & startyear=="2002"
	 
	
	**Drop duplicate files**
	drop if iso3=="BRA" & startyear=="1991" & new_file==1
	drop if iso3=="SLV" & startyear=="2007" & new_file==0
	drop if iso3=="IRN" & new_file==1
	drop if iso3=="MEX" & startyear=="2010" & new_file==0
	drop if iso3=="MAR" & new_file==1
	drop if iso3=="PAN" & startyear=="2000" & new_file==1
	drop if iso3=="PER" & startyear=="2007" & new_file==1
	drop if iso3=="PRI" & startyear=="1980" & new_file==1
	drop if iso3=="PRI" & startyear=="1990" & new_file==1
	drop if iso3=="SDN" & filename=="SDN_CENSUS_2008_WATER_SANITATION.DTA"
	drop if iso3=="THA" & startyear=="1980" & new_file==1
	drop if iso3=="THA" & startyear=="1990" & new_file==1
	drop if iso3=="THA" & startyear=="2000" & new_file==1
	drop if iso3=="TUR" & startyear=="2000" & new_file==1
	drop if iso3=="URY" & startyear=="1985" & new_file==0
	drop if iso3=="URY" & startyear=="1996" & new_file==0
	drop if iso3=="URY" & startyear=="2006" & new_file==0
	drop if iso3=="VEN" & startyear=="2001" & new_file==1
	drop if iso3=="IDN" & new_file == 0 & startyear!="2000"  /*Drop duplicates of old IPUMS files*/
	destring(startyear), replace /*Drop files that are older than 1980*/
	drop if startyear<1980  | startyear==.
	tostring(startyear), replace
	
	/*/w_srcedrnk
	replace w_srcedrnk = subinstr(w_srcedrnk, "_watsrc", "wsrc", .)
	replace w_srcedrnk = subinstr(w_srcedrnk, "_watsup", "wsup", .)
	replace w_srcedrnk = "watsrc" if regexm(w_srcedrnk, "watsrc")
	replace w_srcedrnk = "watsup" if regexm(w_srcedrnk, "watsup")
	replace w_srcedrnk = "" if iso3 == "FRA"
	replace w_srcedrn = "" if ! regexm(w_srcedrnk, "watsrc") &! regexm(w_srcedrnk, "watsup")
	bro w_srcedrnk if regexm(w_srcedrnk, " ")
		** lacking entry for GBR 1991
	// t_type	
	replace t_type = subinstr(t_type, "_toilet", "_toi", .)
	replace t_type = subinstr(t_type, "_sewage", "_sew", .)
	replace t_type = "sewage toilet" if regexm(t_type, "sewage") & regexm(t_type, "toilet")
	replace t_type = "sewage" if regexm(t_type, "sewage") &! regexm(t_type, "toilet")
	replace t_type = "toilet" if regexm(t_type, "toilet") &! regexm(t_type, "sewage")
	bro t_type if regexm(t_type, " ")
		** not lacking any entries
	*/

** organize
compress

** save 
save "`dat_folder_new_ipums'/varlist_ipums", replace


capture log close