// Merge on new variables to ubcov codebook

local ubcov_lib "J:/WORK/01_covariates/common/ubcov_library/01_prep/MACRO_DHS"
local new_vars_dir "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/DHS"
local new_vars shared_san

import excel "`ubcov_lib'/codebook_wash.xlsx", firstrow clear
egen filepath_full = concat(file_path file_name), punct(/)

// Prep new codebook with new variable to be merged on
preserve
	use "`new_vars_dir'/varlist_temp_dhs", clear
	keep filepath_full `new_vars'
	tempfile new_var_df
	save `new_var_df', replace
restore

// Merge
merge 1:1 filepath_full using `new_var_df', nogen keep(1 3)
drop filepath_full
order `new_vars', after(t_type)
export excel "`ubcov_lib'/codebook_wash_tmp.xlsx", replace firstrow(var)

forvalues x = 1/16 {
	replace v`x' = "" if regexm(v`x', "share")
}
forvalues x = 1/16 {
	replace v`x' = "" if regexm(v`x', "compart")
}
forvalues x = 1/16 {
	replace v`x' = "" if !regexm(v`x', "flush know")
}
replace v3 = "" if regexm(v3, "know")