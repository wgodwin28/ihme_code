// File Name: smooth_covariate.do

// File Purpose: Run smoothing code on hygiene/handwashing dataset
// Author: Astha KC 
// Date: 05/15/2014

// Additional Comments: modified from smoothing code used for water and sanitation

**housekeeping
clear all
set more off

** create locals for relevant files and folders
local input_folder 	"J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/smoothing/spacetime input"
local output_folder "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/smoothing/spacetime results"

**Using new smoothing_code to accomodate new locations **
local smoothing_code_folder "J:/WORK/01_covariates/common/lib/spacetime"

** load in smoothing code
do "`smoothing_code_folder'/smoothing.ado"

** run smoothing step for handwashing/hygiene
#delimit ;
smoothing, 
	dv(hwws_pred_logit) 
	ivs(ln_ldi_pc) 
	sub_ivs(ln_ldi_pc) 
	reverse_transform_dv(invlogit) 
	unique(iso3 year reference reference_data hwws_se)
	sub_unique(iso3 year reference reference_data hwws_se)
	smooth_age(0) 
	start_year(1980)
	end_year(2013)
	zeta(0.9)
	lambda(0.9)
	input_data("`input_folder'/hygiene_smoothing_dataset.dta") 
	store_data("`output_folder'") 
	make_graphs(0)
	model_name(hwws)
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