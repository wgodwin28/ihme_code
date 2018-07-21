// File Name: run_calculate_prev.do

// File Purpose: Call all prevalence calculation scripts
// Author: Leslie Mallinger
// Date: 7/7/2011
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 1200m
set maxvar 10000
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local code_folder "${code_folder}/07.Calculate Prevalence"
local dat_folder_reports "${data_folder}/Reports"
local dat_folder_key "${data_folder}/Label Keys"
local key_version_rough "validated_08082011"
local key_version_final "assigned_08082011"
	

** run for report data
	di in red "reports"
	do "`code_folder'/calculate_prev_reports.ado"
	calculate_prev_reports, dataloc(`dat_folder_reports') keyloc(`dat_folder_key') keyversion(`key_version_rough') prevtype("rough")
	calculate_prev_reports, dataloc(`dat_folder_reports') keyloc(`dat_folder_key') keyversion(`key_version_final') prevtype("final")
	

** run for survey data
	// NOTE: this calculates two types of prevalence:
		** 1) "rough" prevalence, using the validated key that still has categories in "halfimproved"
		** 2) final prevalence, using the assigned label key that no longer has categories in "halfimproved"
	di in red "surveys"
	do "`code_folder'/calculate_prev_surveys.do"
	

** compile prevalence estimates and assign plotting designations
	di in red "compiling prevalence estimates"
	do "`code_folder'/compile_prev_results.do"
	