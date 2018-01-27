clear all
set more off
cap restore, not

// prep stata
if c(os) == "Unix" {
	local j "/home/j"
	set odbcmgr unixodbc
	local code_folder "/home/j/WORK/05_risk/risks/nutrition_underweight/01_exposure/02_analysis/01_code" 
	local stata_shell "/home/j/temp/wgodwin/save_results/stata_shell.sh" 
}
local get_location 	"`j'/WORK/10_gbd/00_library/functions/get_location_metadata.ado"
local malnutrition "stunting wasting underweight"
local cats "cat1 cat2 cat3"
local logs 		-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors

//Get location ids
	run "`get_location'"
	get_location_metadata, location_set_id(9) clear
	keep if level >= 3
	keep location_id parent_id location_name super_region_id super_region_name region_name ihme_loc_id
	quie levelsof location_id, local(locations)

// foreach loc of local locations { // only run for initial save
	foreach mal of local malnutrition {
		foreach cat of local cats {
	! qsub -N save_`mal'_`cat' -P proj_custom_models -pe multi_slot 4 `logs' "`stata_shell'" "`code_folder'/05_maln_final_prep.do" "`mal' `cat'"
		}
	}
// }
