// File Name: lookfor_vars_dhs.do
// File Purpose: Look for appropriate HAP variables in DHS surveys 
// Author: Leslie Mallinger
// Date: 3/2/10 - 3/13/10
// Edited on: 11/23/2015 for GBD 2015 updates by Yi Zhao

// set up
clear all
set maxvar 10000
set more off
capture log close

** create locals for relevant files and folders
local dat_folder_new_dhs "J:/WORK/05_risk/risks/air_hap/01_exposure/01_data audit/02_data/01_DHS_prep" 
local curr_date = subinstr(c(current_date), " ", "", .)

** open dataset and store data in a mata matrix
use "`dat_folder_new_dhs'/datfiles_dhs_`curr_date'", clear
mata: dhs_files=st_sdata(.,("iso3", "filedir", "filename"))
local maxobs = _N

** create a vector for each of the variables of interest
local vars fuels
foreach var of local vars {
	mata: `var' = J(`maxobs', 1, "")
}
***************************************************************************************************	
  **STEP1- loop through each survey file, look for and save relevant varnames 
***************************************************************************************************
forvalues filenum = 1(1)`maxobs' {
	// save countryname and filename as locals, then print to keep track of position in the loop
	mata: st_local("iso3", dhs_files[`filenum', 1])
	mata: st_local("filedir", dhs_files[`filenum', 2])
	mata: st_local("filename", dhs_files[`filenum', 3])
	display in red _newline _newline "(`filenum')" _newline "iso3: `iso3'" _newline "filename: `filename'"
	
	// open file (only first 30 observations for speed), then lookfor variables of interest and save in appropriate vector
	use "`filedir'/`filename'" if _n < 30, clear
	
	
		// cooking fuel
		lookfor "hv226"
		gen temp="`r(varlist)'"
		if temp!="" {
			split temp, parse(" ")
			local temp=temp1
		}
		drop temp*
		mata: fuels[`filenum', 1] = "`temp'"
		if "`r(varlist)'" == "" {
			lookfor "fuel" "combustible" 
			gen temp="`r(varlist)'"
			if temp!="" {
				split temp, parse(" ")
				local temp=temp1
			}
			if temp=="" {
				local temp = "missing"
			}
			drop temp*
			mata: fuels[`filenum', 1] = "`temp'"
		}			
		}
** move variables from Mata into Stata datset
	use "`dat_folder_new_dhs'/datfiles_dhs_`curr_date'", clear
	capture getmata `vars'

******************************************************************************************************************************
**STEP2-Correct wrong varname extraction and drop surveys do not have variables of interest 
******************************************************************************************************************************
sort iso3 startyear module
gen dropme=0
// Fuel
* ZAF 1998 fuel variables are sh30a sh30b....and use yes or no to indicate, drop it for now and deal with it in odd-ball
drop if iso3=="ZAF" & startyear == 1998
* YEM 1991, sh23 is the fuel variable, but the values are weird, drop it for now and deal in odd-ball
drop if iso3=="YEM" & startyear==1991 & module=="HH"
* LBR 2006, thr fuel variable is sh112 instead of hv226
replace fuels="sh112" if iso3=="LBR" & startyear== 2006

replace dropme=1 if fuels=="missing" 
drop if dropme==1
drop dropme

*AFG 2010 does not have caseid, drop it for now and do it in odd ball
drop if iso3=="AFG" & startyear==2010
*UZB 2002 does not have caseid, drop it for now and do it in odd ball
drop if iso3=="UZB" & startyear==2002

// make startyear back to string for the convenience of calculation
tostring startyear, replace
// save the temporary reduced list of surveys
save "`dat_folder_new_dhs'/varlist_prep_dhs_`curr_date'", replace 

*******************************************************************************************
**STEP3: check whether the variables have values by summerizing each continuous vairable
*******************************************************************************************
// new mata matrix: for dropping surveys
mata: dhs_files_drop=st_sdata(.,("iso3", "filedir", "filename", "cluster_num", "sample_weight", "fuels"))
local maxobs = _N

** loop through survey files, looking for and saving relevant variables in each one
forvalues filenum = 1(1)`maxobs' {
	// save location name and filename as locals, then print to keep track of position in the loop
	mata: st_local("iso3", dhs_files_drop[`filenum', 1])
	mata: st_local("filedir", dhs_files_drop[`filenum', 2])
	mata: st_local("filename", dhs_files_drop[`filenum', 3])
	mata: st_local("cluster_num", dhs_files_drop[`filenum', 4])
	mata: st_local("sample_weight", dhs_files_drop[`filenum', 5])
	mata: st_local("fuels", dhs_files_drop[`filenum', 6])
	
	display in red _newline _newline "(`filenum')" _newline "iso3: `iso3'" _newline "filename: `filename'"

	use "`filedir'/`filename'", clear
	// cluster num
	summarize `cluster_num'
	if `r(N)'==0 {
		mata: dhs_files_drop[`filenum', 4]="empty"
	}
	// sample weight
	summarize `sample_weight'
	if `r(N)'==0 {
		mata: dhs_files_drop[`filenum', 5]="empty"
	}
	// fuels
	summarize `fuels'
	if `r(N)'==0 {
		mata: dhs_files_drop[`filenum', 6]="empty"
	}	
		}

clear
getmata (iso3 filedir filename cluster_num sample_weight fuels)=dhs_files_drop
gen emptyvar = 0
foreach var of varlist cluster_num-fuels{
	replace emptyvar = 1 if `var'=="empty"
}

// merge full file back on
merge 1:1 iso3 filedir filename using "`dat_folder_new_dhs'/varlist_prep_dhs_`curr_date'"
drop _merge
order  iso3 iso3 filedir filename filepath_full startyear endyear svytype_sp svy svyver_real region module version svyver
order emptyvar, after(caseid)

drop if emptyvar==1
isid iso3 startyear filepath_full

compress
drop emptyvar

// Save
save "`dat_folder_new_dhs'/varlist_final_dhs_`curr_date'", replace

***END OF CODE***