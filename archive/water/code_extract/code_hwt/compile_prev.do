//// File Name: compile_prev.do
// File Purpose: Compile prevalence for new categories that were estimated using DHS and MICS 
// Author: Astha KC 
// Date: 2/6/2014

** // Additional Comments: 

//Housekeeping
clear all 
set more off

//Set relevant locals
local DHS_prev "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/data/DHS/prev_newcats_DHS_08062014.dta"
local MICS_prev "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/data/MICS/prev_newcats_MICS_08062014.dta"
local compile_folder "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/data/compile"

//Append the two datasets
use "`DHS_prev'", clear
append using "`MICS_prev'"


//save 
save "`compile_folder'/prev_newcats_all_08062014.dta", replace
