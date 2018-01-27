//Append together gpr output for processing. Parallelized by exposure type.
clear all
set more off
cap restore, not

// prep stata
if c(os) == "Unix" {
	local j "/home/j"
	set odbcmgr unixodbc
	local code_folder "/home/j/WORK/05_risk/risks/wash_water/code/03_final_prep"
	local stata_shell "/home/j/temp/wgodwin/save_results/stata_shell.sh"
}
else if c(os) == "Windows" {
	local j "J:"
}
set more off


// Set relevant locals	
local exposures 	piped imp
// imp itreat_imp itreat_piped itreat_unimp tr_imp tr_piped tr_unimp
// local output_dir		"/home/j/WORK/05_risk/risks/wash_water/data/exp/me_id/uploaded/draws"
local output_dir		"/home/j/temp/wgodwin/save_results/wash_water/draws"

// Loop through each exposure and submit script to append csv's together
foreach exposure of local exposures {
	if "`exposure'" == "imp" {
		local data_id 569
		local model_id 220
		}
	if "`exposure'" == "piped" {
		local data_id 570
		local model_id 243
		}
/*	if "`exposure'" == "itreat_imp" {
		local data_id 429
		local model_id 111
		}  
	if "`exposure'" == "itreat_piped" {
		local data_id 430
		local model_id 114
		} 
	if "`exposure'" == "itreat_unimp" {
		local data_id 431
		local model_id 115
		} 
	if "`exposure'" == "tr_imp" {
		local data_id 432
		local model_id 116
		} 
	if "`exposure'" == "tr_piped" {
		local data_id 433
		local model_id 117
		} 
	if "`exposure'" == "tr_unimp" {
		local data_id 434
		local model_id 118
		} 
*/
 		local input_dir /share/covariates/ubcov/04_model/wash_water_`exposure'/_models/`data_id'/`model_id'/draws
		local logs -o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
		local project -P proj_custom_models
		! qsub -N `exposure' -pe multi_slot 8 -P proj_custom_models `logs' "`stata_shell'" "`code_folder'/01_post_gpr_append.do" "`input_dir' `output_dir' `exposure'"
	}
