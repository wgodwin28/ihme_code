clear all
set more off
set maxvar 20000

// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 

// SO in parent script, read in the codebook and count number of rows. Then set up the qsub and loop through each row of the codebook while passing the `a' argument
// In the child script, "keep if _n==`a' and then "
// Locals

	// Directory Locals
		local code_root 	`c(pwd)'
		local input_root	"$j/temp/wgodwin/sga/data"
		local output_root 	"$j/temp/wgodwin/sga/data"	

// Setting up mata 
    insheet using "`input_root'/microdata_cb.csv", clear

// Sets into a format that you can input into mata
tostring *, force replace
foreach var of varlist * {
	replace `var' = "" if `var' == "."
}


quietly: ds
local mata_colnames `r(varlist)'

// Put into mata
putmata x = (`mata_colnames')


// Begins a loop that looks at each survey individually
	local set_num = _N
	forvalues a = 1/`set_num' { 

timer on 1
	// Applying local names
	local count = 1
	foreach colname of local mata_colnames {
		mata: st_local("`colname'", x[`a', `count'])
		local count = `count' + 1
	}

	use "`filepath'", clear
	
	rename *, lower
	
		
		rename `gestage' gestage
		rename `birthweight' birthweight
		rename `mat_age' mat_age
		rename `mat_educ' mat_educ
		rename `plurality' plurality
		rename `c_section' c_section
		rename `prenat_attn' prenat_attn

/*		if "`rec_wt'" == "" {
			gen death_wt = .
		}
		else {
			rename `rec_wt' death_wt
		}
*/		
		gen pweight = 1
		
		gen iso3 = "`iso3'" 
		gen year_start = `starttime'
		gen year_end = `endtime'
		gen nid = `nid'
		gen filepath = "`filepath'"
		
		//replace age = . if age == `age_mi'
		
		if "`iso3'" == "MEX" {
			destring `sex', replace
		}
		
		//replace sex = 1 if `sex' == `male'
		//replace sex = 2 if `sex' == `female'
		
		if "`iso3'" == "USA" {
			capture confirm string variable `sex'
			if !_rc { // means if there's no return code, do what's below
				rename `sex' sexstring
				gen sex = .
				replace sex = 1 if sexstring == "M"
				replace sex = 2 if sexstring == "F" 
			}
			else {
				rename `sex' sex
				replace sex = 1 if `sex' == 1
				replace sex = 2 if `sex' == 2
			}
		}
		
		cap replace gestage = . if gestage == `gestage_mi'
		cap replace birthweight = . if birthweight == `birthweight_mi'
		cap replace mat_age = . if mat_age == `mat_age_mi'
		cap replace num_prev_children = . if num_prev_children == `num_child_mi'
		cap replace plurality = . if plurality == `plurality_mi'
		cap replace prenat_attn = . if prenat_attn == `prenat_attn_mi'

***** Make this specific so that it cleans up correctly and doesn't break
	// Clean URY and MEX sources
		if "`subnational'" == "" {
			rename `num_prev_children' num_prev_children
			rename `instit_birth' instit_birth
			keep nid iso3 year_start year_end nid filepath pweight sex birthweight gestage mat_educ mat_age plurality num_prev_children instit_birth c_section prenat_attn
		}
	// Now to clean U.S. states and territories sources
		if "`subnational'" != "" & `starttime' <= 2002 {
			rename `subnational' subnational
			rename `num_prev_children' num_prev_children
			rename `alcohol' alc
			rename `mat_race' mat_race
			rename `mat_race_recode' mat_race_rec
			rename `smoker' smoker
			keep nid iso3 year_start year_end nid filepath pweight sex subnational birthweight gestage mat_educ mat_age plurality num_prev_children c_section prenat_attn mat_race mat_race_rec smoker alc
		}
		if "`subnational'" != "" & `starttime' >= 2003 & `starttime' <= 2006 {
			rename `subnational' subnational
			rename `instit_birth' instit_birth
			rename `num_prev_children' num_prev_children
			rename `alcohol' alc
			rename `mat_race' mat_race
			rename `mat_race_recode' mat_race_rec
			rename `smoker' smoker
			keep nid iso3 year_start year_end nid filepath pweight sex subnational birthweight gestage mat_educ mat_age plurality num_prev_children instit_birth c_section prenat_attn mat_race mat_race_rec smoker alc
		}
		if "`subnational'" != "" & `starttime' >= 2007 {
			rename `subnational' subnational
			rename `instit_birth' instit_birth
			rename `mat_race' mat_race
			rename `mat_race_recode' mat_race_rec
			rename `smoker' smoker
			keep nid iso3 year_start year_end nid filepath pweight sex subnational birthweight gestage mat_educ mat_age plurality instit_birth c_section prenat_attn mat_race mat_race_rec smoker
		}
		timer off 1
	tempfile data_num_`a'
	save data_num_`a', replace
	timer list 1
	}
// So use the standard age curves from lancet paper to find the threshold for SGA for each week. Interpolate the weeks below week 33 with linear curve.
		
		di "generating dummies"
		gen wk_28 = .
		replace wk_28 = 1 if gestage < 28
		replace wk_28 = 0 if gestage >= 28

		gen wk_32 = .
		replace wk_32 = 1 if gestage < 32 & gestage >= 28
		replace wk_32 = 0 if gestage >= 32

		gen wk_37 = .
		replace wk_37 = 1 if gestage < 37 & gestage >= 32
		replace wk_37 = 0 if gestage >= 37

		gen wk_44 = .
		replace wk_44 = 1 if gestage < 44 & gestage >= 37
		replace wk_44 = 0 if gestage >= 44

		gen vlw_wt = .
		replace vlw_wt = 1 if birthweight < 1500
		replace vlw_wt = 0 if birthweight >= 2500

		gen lw_wt = .
		replace lw_wt = 1 if birthweight < 2500 & birthweight >= 1500
		replace lw_wt = 0 if birthweight > 2500

		gen sga_tag = .
		replace sga_tag = 1 if wk_28 == 1 & vlw_wt == 1
		replace sga_tag = 1 if wk_32 == 1 & lw_wt == 1
		replace sga_tag = 1 if wk_32 == 1 & vlw_wt == 1
		replace sga_tag = 0 if sga_tag == .
		
/*		di "me_id 2571"
		gen me_2571 = .
		replace me_2571 = 1 if me_1557 == 1 & aged <29
		replace me_2571 = 0 if me_1557 == 0
		replace me_2571 = 0 if me_1557 == 1 & aged >28

		di "me_id 1558"
		gen me_1558 = .
		replace me_1558 = 1 if gestage >= 28 & gestage < 32
		replace me_1558 = 0 if gestage < 28 | gestage >= 32 & gestage

		di "me_id 2572"
		gen me_2572 = .
		replace me_2572 = 1 if me_1558 == 1 & aged <29
		replace me_2572 = 0 if me_1558 == 0
		replace me_2572 = 0 if me_1558 == 1 & aged >28
		
		gen me_1559 = .
		replace me_1559 = 1 if gestage >= 32 & gestage < 37
		replace me_1559 = 0 if gestage < 32 | gestage >= 37 & gestage

		di "me_id 2573"
		gen me_2573 = .
		replace me_2573 = 1 if me_1559 == 1 & aged <29
		replace me_2573 = 0 if me_1559 == 0
		replace me_2573 = 0 if me_1559 == 1 & aged >28

		gen me_8675 = .
		replace me_8675 = 1 if gestage < 37 
		replace me_8675 = 0 if gestage >= 37 & gestage

		di "me_id 8676"
		gen me_8676 = .
		replace me_8676 = 1 if me_8675 == 1 & aged <29
		replace me_8676 = 0 if me_8675 == 0
		replace me_8676 = 0 if me_8675 == 1 & aged >28

		gen me_8679 = .
		replace me_8679 = 1 if gestage >= 28 & gestage < 37
		replace me_8679 = 0 if gestage < 28 | gestage >= 37 & gestage
		
		gen me_8683 = .
		replace me_8683 = 1 if gestage < 32
		replace me_8683 = 0 if gestage >= 32 & gestage
		
		gen me_8687 = .
		replace me_8687 = 1 if birthweight <= 1500
		replace me_8687 = 0 if birthweight > 1500 & birthweight
		
		gen me_8691 = .
		replace me_8691 = 1 if birthweight <= 2500
		replace me_8691 = 0 if birthweight > 2500 & birthweight

		di "done with dummies!"
*/		
	
		tempfile data_num_`a'
	save data_num_`a', replace
}	
   capture confirm file "`output_root'/`iso3'/nul" // check if `name' subdir exists
	if _rc { // _rc will be >0 if it doesn't exist
		mkdir "`output_root'/`iso3'"
	}

if regexm("`file_name'", "_SP_") {
	di "This survey is not nationally representative"
}

else {
	save "`output_root'/`iso3'/`iso3'_`module'_`starttime'_`endtime'_neonatal_death.dta", replace
 }
}
