// File Name: extract_labels_all.do

// File Purpose: Extract labels from W&S variables for relevant surveys
// Author: Leslie Mallinger
// Date: 3/26/10
// Edited on: 

// Additional Comments: 


clear all
// macro drop _all
set mem 3G
set maxvar 10000
set more off
capture log close
capture restore, not


** create locals for relevant files and folders
local log_folder "${code_folder}/05.Extract and Stdize Labels"
local survey_list "${data_folder}/surveys_to_analyze.csv"
local dat_folder_key "${data_folder}/Label Keys"
local key_version_rough "validated_08082011"
local key_version_final "assigned_04082014"


** load in applicable programs
do "`log_folder'/extract_labels.ado"	// label extraction script
do "`log_folder'/stdize_label.ado"		// label replacement script
do "`log_folder'/improved_label.ado"	// improved/unimproved label script


** *************************************** NOTES ***************************************************
** // DEBUGGING ONLY
extract_labels, survey(ipums) dataloc("${data_folder}/IPUMS") ///
keyloc(`dat_folder_key') keyversion(`key_version_final') prevtype("final")
** *************************************************************************************************

** quietly {
** run label extraction list for each survey in the spreadsheet
insheet using "`survey_list'", comma clear names
local num_obs = _N

local prevtype "rough"
forvalues i = 1/`num_obs' {
	preserve
		local svy = survey in `i'
		local data_folder = dataloc in `i'
		di in red "rough labels: `svy'"
		extract_labels, survey(`svy') dataloc(`data_folder') keyloc(`dat_folder_key') keyversion(`key_version_`prevtype'') prevtype(`prevtype')
	restore
}

local prevtype "final"
forvalues i = 1/`num_obs' {
	preserve
		local svy = survey in `i'
		local data_folder = dataloc in `i'
		di in red "final labels: `svy'"
		extract_labels, survey(`svy') dataloc(`data_folder') keyloc(`dat_folder_key') keyversion(`key_version_`prevtype'') prevtype(`prevtype')
	restore
}
** }