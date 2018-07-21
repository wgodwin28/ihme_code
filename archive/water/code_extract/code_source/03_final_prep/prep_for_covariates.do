use "J:\DATA\IHME_COUNTRY_CODES\IHME_COUNTRY_CODES_Y2013M07D26.DTA", clear 
drop if iso3==""
tempfile country_codes
save `country_codes', replace

**WATER**
use "J:\WORK\01_covariates\02_inputs\water_sanitation\data\02_Analyses\gpr\gpr_output\gpr_results_w_covar_with_orig_data.dta", clear
keep iso3 year  gpr_mean
rename gpr_mean mean_value
duplicates drop
drop if mean_value==. 

merge m:1 iso3 using `country_codes', keepusing(location_name location_id) keep(1 3) nogen
tempfile water
save `water', replace 

**chn - water**
use "J:\WORK\01_covariates\02_inputs\water_sanitation\model\subnational\chn\water_chn_cov.dta", clear
merge m:1 location_id using `country_codes', keepusing(location_name) keep(1 3) nogen
tempfile chn_water
save `chn_water', replace

**mex-water**
use "J:\WORK\01_covariates\02_inputs\water_sanitation\data\subnational\MEX\water_MEX_covar.dta", clear 
merge m:1 location_id using `country_codes', keepusing(location_name) keep(1 3) nogen
tempfile mex_water
save `mex_water', replace 

use "C:\Users\asthak\Documents\Covariates\Water and Sanitation\model\gpr_output\gpr_results_w_covar_with_orig_data.dta", clear
keep if iso3=="XIR" | iso3=="XIU"
keep iso3 year gpr_mean 
rename gpr_mean mean_value
merge m:1 iso3 using `country_codes', keepusing(location_name location_id) keep(1 3) nogen
tostring(location_id), replace
replace iso3 = "IND" + "_" + location_id
destring(location_id), replace 

duplicates drop
append using `water' `chn_water' `mex_water'

tempfile all_water
save `all_water', replace 

**expand 13 for GBR**
keep if iso3=="GBR"
expand 13 if iso3=="GBR", gen(exp)
keep if exp==1
forvalues y = 1980(1)2013 {
preserve
keep if year == `y' 
	replace location_id = 433 if _n == 1 
	replace location_id = 434 if _n == 2   
	replace location_id = 4618 if _n == 3 	
	replace location_id = 4619 if _n == 4 
	replace location_id = 4620 if _n == 5 
	replace location_id = 4621 if _n == 6 
	replace location_id = 4622 if _n == 7 
	replace location_id = 4623 if _n == 8 
	replace location_id = 4624 if _n == 9 
	replace location_id = 4625 if _n == 10 
	replace location_id = 4626 if _n == 11 
	replace location_id = 4636 if _n == 12 
	tempfile `y'
	save ``y'', replace 
restore
}

use `1980', clear
append using `1981' `1982' `1983' `1984' `1985' `1986' `1987' `1988' `1989' `1990' `1991' `1992' `1993' `1994' `1995' `1996' `1997' ///
	`1998' `1999' `2000' `2001' `2002' `2003' `2004' `2005' `2006' `2007' `2008' `2009' `2010' `2011' `2012' `2013'
drop location_name exp
merge m:1 location_id using `country_codes', keepusing(location_name) keep(1 3) nogen
tostring(location_id), replace
replace iso3 = "GBR" + "_" + location_id
destring(location_id), replace 

append using `all_water'


**SAVE**
save "J:\WORK\01_covariates\02_inputs\water_sanitation\model\covariates\water_05052014.dta", replace


**SANITATION**
use "J:\WORK\01_covariates\02_inputs\water_sanitation\data\02_Analyses\gpr\gpr_output\gpr_results_s_covar_with_orig_data.dta", clear
keep iso3 location_name year gpr_mean 
rename gpr_mean mean_value
duplicates drop

merge m:1 location_name iso3 using `country_codes', keepusing(location_id) keep(1 3) nogen
tempfile san
save `san', replace 

**chn-san**
use "J:\WORK\01_covariates\02_inputs\water_sanitation\model\subnational\chn\sanitation_chn_cov.dta", clear
merge m:1 location_id using `country_codes', keepusing(location_name) keep(1 3) nogen
tempfile chn_san
save `chn_san', replace

**mex-san**
use "J:\WORK\01_covariates\02_inputs\water_sanitation\data\subnational\MEX\sanitation_MEX_covar.dta", clear
merge m:1 location_id using `country_codes', keepusing(location_name) keep(1 3) nogen
tempfile mex_san
save `mex_san', replace

use "C:\Users\asthak\Documents\Covariates\Water and Sanitation\model\gpr_output\gpr_results_s_covar_with_orig_data.dta", clear
keep if iso3=="XIR" | iso3=="XIU"
keep iso3 year gpr_mean 
rename gpr_mean mean_value
duplicates drop

replace iso3 = "IND_4637" if iso3=="XIR" 
replace iso3 = "IND_4638" if iso3=="XIU"

append using `san'
append using `chn_san'
append using `mex_san'

drop if mean_value==. 

tempfile all_san
save `all_san', replace

**expand 13 for GBR**
keep if iso3=="GBR"
expand 13 if iso3=="GBR", gen(exp)
keep if exp==1
forvalues y = 1980(1)2013 {
preserve
keep if year == `y' 
	replace location_id = 433 if _n == 1 
	replace location_id = 434 if _n == 2   
	replace location_id = 4618 if _n == 3 	
	replace location_id = 4619 if _n == 4 
	replace location_id = 4620 if _n == 5 
	replace location_id = 4621 if _n == 6 
	replace location_id = 4622 if _n == 7 
	replace location_id = 4623 if _n == 8 
	replace location_id = 4624 if _n == 9 
	replace location_id = 4625 if _n == 10 
	replace location_id = 4626 if _n == 11 
	replace location_id = 4636 if _n == 12 
	tempfile `y'
	save ``y'', replace 
restore
}

use `1980', clear
append using `1981' `1982' `1983' `1984' `1985' `1986' `1987' `1988' `1989' `1990' `1991' `1992' `1993' `1994' `1995' `1996' `1997' ///
	`1998' `1999' `2000' `2001' `2002' `2003' `2004' `2005' `2006' `2007' `2008' `2009' `2010' `2011' `2012' `2013'
drop location_name exp
merge m:1 location_id using `country_codes', keepusing(location_name) keep(1 3) nogen
tostring(location_id), replace
replace iso3 = "GBR" + "_" + location_id
destring(location_id), replace 

append using `all_san'
	
**Save file**
save "J:\WORK\01_covariates\02_inputs\water_sanitation\model\covariates\sanitation_05052014.dta", replace