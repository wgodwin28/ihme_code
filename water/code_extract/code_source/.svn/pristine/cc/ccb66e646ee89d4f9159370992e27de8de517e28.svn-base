// File Name: extract_labels_all.do

// File Purpose: Extract labels from W&S variables for relevant surveys
// Author: Leslie Mallinger
// Date: 3/26/10
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 1500m
set maxvar 10000
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local log_folder "${code_folder}/07.Calculate Prevalence"
local survey_list "${data_folder}/surveys_to_analyze.csv"
local graph_folder "C:/Users/tomflem/Documents/Covariates/Updates/water_sanitation/model/graphs"


** load in applicable programs
do "`log_folder'/calculate_prev.ado"


** extract list of surveys to analyze
insheet using "`survey_list'", comma clear names
local num_obs = _N


** loop through surveys and calculate "rough" and "final" prevalence estimates
local prevtype "rough"
forvalues i = 1/`num_obs' {
	preserve
		local svy = survey in `i'
		local data_folder = dataloc in `i'
		di in red "rough prevalence: `svy'"
		calculate_prev, survey(`svy') dataloc(`data_folder') prevtype(`prevtype') makehist(1) graphloc(`graph_folder')
	restore
}

local prevtype "final"
forvalues i = 1/`num_obs' {
	preserve
		local svy = survey in `i'
		local data_folder = dataloc in `i'
		di in red "final prevalence: `svy'"
		calculate_prev, survey(`svy') dataloc(`data_folder') prevtype(`prevtype') makehist(0) graphloc(`graph_folder')
	restore
}

