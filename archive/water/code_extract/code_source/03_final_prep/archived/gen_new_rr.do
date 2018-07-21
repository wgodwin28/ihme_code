**Purpose: Generate Relative Risks for new WASH categories
**Author: Astha KC
**Date: September 30 2014

**The relative risks used to estimate burden for WASH were extracted from two papers. 
**RRs for water & sanitation faciltities & household water treatments were extracted from a meta-regression conducted by Wolf et al (2014)
**RRs for handwashing were extracted from a systematic review conducted by Freeman et al (2014)
**We combine these relative risks to generate RRs for our exposure categories that combine exposure to water facility with household water treatment & sanitation facility with handwashing. 
**The calculation below generate the combined relative risks and their uncertainty intervals

clear all

**handwashing
local rr_handwashing 0.60
local upper_handwashing 0.68
local lower_handwashing 0.53

**for GBD we use measure of excess risk as a result we need to use the inverse of the extracted RRs
local hw_mean = `rr_handwashing'
local hw_upper = `upper_handwashing'
local hw_lower = `lower_handwashing'

**sanitation
local rr_improved = 0.84
local upper_improved = 0.91
local lower_improved = 0.77

local rr_sewer  = 0.31
local upper_sewer = 0.36
local lower_sewer = 0.27

**combine categories
set obs 3
gen id = _n

gen rr_mean = `rr_sewer'	if id==1
gen rr_lower = `lower_sewer' if id==1
gen rr_upper = `upper_sewer'	if id==1
gen cat = "sewer" if id==1

replace rr_mean = `rr_improved' if id==2
replace rr_upper = `upper_improved' if id==2
replace rr_lower = `lower_improved' if id==2
replace cat = "improved" if id==2

replace rr_mean = 1 if id==3
replace rr_lower= 1 if id==3
replace rr_upper = 1 if id==3
replace cat = "unimproved" if id==3
drop id

**calculate the variance in log space 
gen log_var_hw = ((ln(`hw_upper')-ln(`hw_lower'))/(2*1.96))^2
gen log_var_rr = ((ln(rr_upper)-ln(rr_lower))/(2*1.96))^2

**label all new exposure categories after combining handwashing
expand 2, gen(id)
replace cat = cat + " - handwashing" if id == 0
replace cat = cat + " + handwashing" if id == 1 

**calculate the combined RRs 
replace rr_mean = rr_mean * `hw_mean' if id == 1 /*combine excess risk of the absence of handwashing practice*/
replace rr_upper = . if id==1
replace rr_lower = . if id==1

**estimate uncertainty intervals for new combined categories
gen log_var = log_var_hw + log_var_rr if id == 1
gen log_se = sqrt(log_var)

replace rr_upper = rr_mean * exp(1.96*log_se) if id == 1
replace rr_lower = rr_mean / exp(1.96*log_se) if id == 1

sort rr_mean
keep cat *mean *lower *upper
order *mean *lower *upper, first

**generate inverse of RRs because we model excess risk 

**first define reference category - i.e. exp category at lowest risk
preserve 
keep if cat=="sewer + handwashing"
local rr_ref = rr_mean 
local upper_ref = rr_upper
local lower_ref = rr_lower
restore 

replace rr_mean = rr_mean/`rr_ref'
gen new_lower = rr_upper/`upper_ref'
gen new_upper = rr_lower/`lower_ref'
drop rr_lower rr_upper 
rename (new_lower new_upper) (rr_lower rr_upper)

**define cat variable to match exposure
replace cat = "cat1" if cat=="unimproved - handwashing"
replace cat = "cat2" if cat=="improved - handwashing"
replace cat = "cat3" if cat=="unimproved + handwashing"
replace cat = "cat4" if cat=="improved + handwashing"
replace cat = "cat5" if cat=="sewer - handwashing"
replace cat = "cat6" if cat=="sewer + handwashing" 

forvalues n = 1/6 {
	preserve
	keep if cat == "cat`n'"
	global cat`n'_mean = rr_mean
	global cat`n'_upper = rr_upper
	global  cat`n'_lower = rr_lower
	restore
	}

******************
****end of code****
******************