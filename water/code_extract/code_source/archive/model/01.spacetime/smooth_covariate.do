// File Name: smooth_covariate.do

// File Purpose: Run smoothing code on water and sanitation data using the full dataset for CODEm and DisMod covariate
// Author: Leslie Mallinger
// Date: 7/19/2011
// Edited on: 6/15/2012

// Additional Comments: 


clear all
set mem 500m
set more off
capture log close


** create locals for relevant files and folders
** local input_folder "J:/Project/COMIND/Water and Sanitation/Smoothing/Spacetime Input"
** local output_folder "J:/Project/COMIND/Water and Sanitation/Smoothing/Spacetime Results"
** local graph_folder "J:/Project/COMIND/Water and Sanitation/Graphs/Smoothed"
local smoothing_code_folder "J:/Usable/Tools/Smoothing"


** load in smoothing code
do "`smoothing_code_folder'/Smoothing_Program.ado"
	

** run smoothing step for water
#delimit ;
smoothing, 
	dv(iwater_mean_logit) 
	ivs(percenturban_logit ln_LDI_pc education_yrs_pc) 
	sub_ivs(percenturban_logit ln_LDI_pc education_yrs_pc) 
	reverse_transform_dv(invlogit) 
	unique(iso3 year svy plot filename)
	sub_unique(iso3 year svy plot filename iwater_sem)
	smooth_age(0) 
	start_year(1980)
	end_year(2012)
	zeta(0.9)
	lambda(0.5)
	input_data("$input_folder/input_data_for_covariate.dta") 
	store_data("$output_folder") 
	make_graphs(0)
	model_name(w_covar)
	outcome_type(prev) 
	reg_type("reg")
	sex("B")
	smooth_super_regional(1)
	pv(0)
	subnational_data(1)
	national_var(national)
	sn_weight(0.2);
#delimit cr

** run smoothing step for sanitation
#delimit ;
smoothing, 
	dv(isanitation_mean_logit) 
	ivs(percenturban_logit ln_LDI_pc education_yrs_pc) 
	sub_ivs(percenturban_logit ln_LDI_pc education_yrs_pc) 
	reverse_transform_dv(invlogit) 
	unique(iso3 year svy plot filename) 
	sub_unique(iso3 year svy plot filename isanitation_sem)
	smooth_age(0) 
	start_year(1980)
	end_year(2012)
	zeta(0.9)
	lambda(0.5)
	input_data("$input_folder/input_data_for_covariate.dta") 
	store_data("$output_folder") 
	make_graphs(0)
	model_name(s_covar) 
	outcome_type(prev) 
	reg_type("reg")
	sex("B")
	smooth_super_regional(1)
	pv(0)
	subnational_data(1)
	national_var(national)
	sn_weight(0.2);
#delimit cr

capture log close 