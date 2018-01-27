// File Name: extract_labels_all.do

// File Purpose: Extract labels from W&S variables for relevant surveys
// Author: Leslie Mallinger
// Date: 3/26/10
// Edited on: 

// Additional Comments: 
clear all
// macro drop _all
// set mem 3G
set maxvar 10000
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
global data_folder "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/data"
global code_folder "J:/WORK/01_covariates/02_inputs/water_sanitation/new_categories/01_Data_Audit/code"

local log_folder "${code_folder}/Extract and Stdize Labels"
local survey_list "${data_folder}/surveys_to_analyze.csv"
local dat_folder_key "${data_folder}/Label Keys"

**local key_version_rough "validated_08082011"
**local key_version_final "assigned_08082011"
local key_version_rough "validated_08082011"
local key_version_final "assigned_03112014"

** load in applicable programs
do "`log_folder'/extract_labels.ado"	// label extraction script
do "`log_folder'/stdize_label.ado"		// label replacement script
do "`log_folder'/improved_label.ado"	// improved/unimproved label script


** *************************************** NOTES ***************************************************
** // DEBUGGING ONLY
** extract_labels, survey(dhs3) dataloc("${data_folder}/DHS") ///
	** keyloc(`dat_folder_key') keyversion(`key_version_rough') prevtype("rough")
** *************************************************************************************************

** quietly {
** run label extraction list for each survey in the spreadsheet
insheet using "`survey_list'", comma clear names
local num_obs = _N

local prevtype "final"
forvalues i = 1/`num_obs' {
	preserve
		local svy = survey in `i'
		local data_folder = dataloc in `i'
		di in red "final labels: `svy'"
		extract_labels, survey(`svy') dataloc(`data_folder') keyloc(`dat_folder_key') keyversion(`key_version_`prevtype'') prevtype(`prevtype')
	restore
}

local prevtype "rough"
forvalues i = 1/`num_obs' {
	preserve
		local svy = survey in `i'
		local data_folder = dataloc in `i'
		di in red "rough labels: `svy'"
		extract_labels, survey(`svy') dataloc(`data_folder') keyloc(`dat_folder_key') keyversion(`key_version_`prevtype'') prevtype(`prevtype')
	restore
}

** }