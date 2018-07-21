// File Name: smooth_san_prop.do

// File Purpose: Run smoothing code on handwashing/san joint distribution data
// Author: Astha KC 
// Date: 09/29/2014

// Additional Comments: modified from smoothing code used for water and sanitation

**housekeeping
clear all
set more off

** create locals for relevant files and folders
local input_folder 	 "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/smoothing/spacetime input"
local output_folder  "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/smoothing/spacetime_results_san"

**Using new smoothing_code to accomodate new locations **
local smoothing_code_folder "J:/WORK/01_covariates/common/lib/spacetime"

foreach ftype in "unimp" "imp" "sewer"	{

	if "`ftype'"=="unimp" {
		local facility "unimproved"
		}
	if "`ftype'"=="imp" {
		local facility "improved"
		}
	if "`ftype'"=="sewer"{
		local facility "sewer"
		}

	** load in smoothing code
	do "`smoothing_code_folder'/smoothing.ado"

	** run smoothing step for handwashing/hygiene
	#delimit ;
	smoothing, 
		dv(logit_hw_`ftype') 
		ivs(ln_ldi_pc) 
		sub_ivs(ln_ldi_pc) 
		reverse_transform_dv(invlogit) 
		unique(iso3 year source ihwws_`facility'_sem)
		sub_unique(iso3 year source ihwws_`facility'_sem)
		smooth_age(0) 
		start_year(1980)
		end_year(2013)
		zeta(0.9)
		lambda(0.9)
		input_data("`input_folder'/san_prop_smoothing.dta") 
		store_data("`output_folder'") 
		make_graphs(0)
		model_name(hw_`ftype')
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
	}