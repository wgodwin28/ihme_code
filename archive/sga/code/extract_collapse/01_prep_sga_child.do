// lower level script for sga prep
clear all
set more off

// Pass in arguments
local input_root 	`1'
local output_root 	`2'
local a 			`3'

// Debugging
// local input_root		"J:/temp/wgodwin/sga/data"
// local output_root 	"J:/temp/wgodwin/sga/data"
// local a 				3

// Set directories
	if c(os) == "Windows" {
		global j "J:"
		set mem 1g
	}
	if c(os) == "Unix" {
		global j "/home/j"
		set mem 8g
	} 

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

	// Applying local names
	local count = 1
	foreach colname of local mata_colnames {
		mata: st_local("`colname'", x[`a', `count'])
		local count = `count' + 1
	}

	use "$j/`filepath'", clear
	
		rename *, lower	
		local variables gestage birthweight mat_age mat_educ plurality c_section prenat_attn
		foreach var of local variables {
			rename ``var'' `var'
		}

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
				
		if "`iso3'" == "MEX" {
			destring `sex', replace
				replace mat_age = substr(mat_age, -4, .)
				rename mat_age mat_year
				destring mat_year, replace
				gen mat_age = year_start - mat_year
			replace c_section = "vaginal" if c_section == "1"
			replace c_section = "cesearian" if c_section =="2"
			replace mat_educ = "none" if mat_educ == "01" | mat_educ == "1"
			replace mat_educ = "primary" if mat_educ == "02" | mat_educ == "03"	| mat_educ == "2" | mat_educ == "3"	
			replace mat_educ = "secondary" if mat_educ == "04" | mat_educ == "05" | mat_educ == "4" | mat_educ == "5"
			replace mat_educ = "bachelors" if mat_educ == "06" | mat_educ == "07" | mat_educ == "6" | mat_educ == "7"
			replace mat_educ = "masters" if mat_educ == "08" | mat_educ == "8"
			replace mat_educ = "post-graduate" if mat_educ == "10"	

			rename `instit_birth' instit_birth
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
			gen module = "`module'"
		}
		
		if "`iso3'" == "URY" {
			decode mat_educ, gen(mat_educ2)
			decode `instit_birth', gen(instit_birth)
			decode c_section, gen(c_section2)
			decode plurality, gen(plurality2)
			drop plurality c_section mat_educ
			rename (mat_educ2 c_section2 plurality2) (mat_educ c_section plurality)
		}
		gen mat_age_rec = .
		replace mat_age_rec = 1 if mat_age >= 10 & mat_age < 15
		replace mat_age_rec = 2 if mat_age >= 15 & mat_age < 20
		replace mat_age_rec = 3 if mat_age >= 20 & mat_age < 25
		replace mat_age_rec = 4 if mat_age >= 25 & mat_age < 30
		replace mat_age_rec = 5 if mat_age >= 30 & mat_age < 35
		replace mat_age_rec = 6 if mat_age >= 35 & mat_age < 40
		replace mat_age_rec = 7 if mat_age >= 40 & mat_age < 45
		replace mat_age_rec = 8 if mat_age >= 45 & mat_age < 50
		replace mat_age_rec = 9 if mat_age >= 50 & mat_age < 55
		replace mat_age_rec = 10 if mat_age >= 55 & mat_age < 60

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
			keep nid iso3 year_start year_end nid filepath pweight sex gestage birthweight mat_educ mat_age mat_age_rec plurality num_prev_children instit_birth c_section prenat_attn
		}
	// Now to clean U.S. states and territories sources
	if "`subnational'" != "" & `starttime' <= 2002 {
			foreach var in subnational num_prev_children alcohol mat_race mat_race_recode smoker {
				rename ``var'' `var'
			}
			tostring mat_race_recode, replace
			replace mat_race_recode = "White" if mat_race_recode == "1"
			replace mat_race_recode = "Other" if mat_race_recode == "2"
			replace mat_race_recode = "Black" if mat_race_recode == "3"
			keep nid iso3 year_start year_end nid filepath pweight sex birthweight gestage subnational mat_educ mat_age mat_age_rec plurality num_prev_children c_section prenat_attn mat_race mat_race_recode smoker alcohol module
		}
	if "`subnational'" != "" & `starttime' >= 2003 & `starttime' <= 2006 {
			foreach var in subnational instit_birth num_prev_children alcohol mat_race mat_race_recode smoker {
				rename ``var'' `var'
			}
			tostring mat_race_recode, replace
			replace mat_race_recode = "White" if mat_race_recode == "1"
			replace mat_race_recode = "Black" if mat_race_recode == "2"
			replace mat_race_recode = "American Indian" if mat_race_recode == "3"
			replace mat_race_recode = "Asian/Pacific Islander" if mat_race_recode == "4"
			keep nid iso3 year_start year_end nid filepath pweight sex birthweight gestage subnational mat_educ mat_age mat_age_rec plurality num_prev_children instit_birth c_section prenat_attn mat_race mat_race_recode smoker alcohol module
		}
	if "`subnational'" != "" & `starttime' >= 2007 {
			foreach var in subnational instit_birth mat_race mat_race_recode smoker {
				rename ``var'' `var'
				}
			tostring mat_race_recode, replace
			replace mat_race_recode = "White" if mat_race_recode == "1"
			replace mat_race_recode = "Black" if mat_race_recode == "2"
			replace mat_race_recode = "American Indian" if mat_race_recode == "3"
			replace mat_race_recode = "Asian/Pacific Islander" if mat_race_recode == "4"
			keep nid iso3 year_start year_end nid filepath pweight sex subnational birthweight gestage mat_educ mat_age mat_age_rec plurality instit_birth c_section prenat_attn mat_race mat_race_recode smoker module
		}

// So use the standard age curves from lancet paper to find the threshold for SGA for each week. Interpolate the weeks below week 33 with linear curve.
	//NEED TO ADD IN A LOOP THAT DOES THIS FOR BOTH SEXES	
		di in red "Generating age and weight tags..."
	
	// Tag babies by gestational week born
	foreach sex in 1 2 { // boys are 1 and girls are 2
		forvalues x = 21/45 {
			gen wk_`x'_`sex' = .
			replace wk_`x'_`sex' = 1 if gestage == `x' & sex == `sex'
			replace wk_`x'_`sex' = 0 if gestage != `x'
		}
	}
	// Load locals
	foreach sex in boys girls {
		preserve
		import delimited "`input_root'/`sex'.csv", clear
			foreach var of varlist * {
				local `var' = `var'
		}
		restore
		if "`sex'" == "boys" {
			local num 1
		}
		if "`sex'" == "girls" {
			local num 2
		}
	// Tag sga for each individual week. Janky way for now, should make cleaner
		forvalues x = 21/27 {
			gen sga_tag1_`x'_`sex' = 1 if wk_`x'_`num' == 1 & birthweight < `wk_`x''
			replace sga_tag1_`x'_`sex' = 0 if sga_tag1_`x'_`sex' == . // this is creating a 0 even when gestage may be missing. should keep this in mind
		}
		forvalues x = 28/31 {
			gen sga_tag2_`x'_`sex' = 1 if wk_`x'_`num' == 1 & birthweight < `wk_`x''
			replace sga_tag2_`x'_`sex' = 0 if sga_tag2_`x'_`sex' == . // this is creating a 0 even when gestage may be missing. should keep this in mind
		}
		forvalues x = 32/36 {
			gen sga_tag3_`x'_`sex' = 1 if wk_`x'_`num' == 1 & birthweight < `wk_`x''
			replace sga_tag3_`x'_`sex' = 0 if sga_tag3_`x'_`sex' == . // this is creating a 0 even when gestage may be missing. should keep this in mind
		}
		forvalues x = 37/42 {
			gen sga_tag4_`x'_`sex' = 1 if wk_`x'_`num' == 1 & birthweight < `wk_`x''
			replace sga_tag4_`x'_`sex' = 0 if sga_tag4_`x'_`sex' == . // this is creating a 0 even when gestage may be missing. should keep this in mind

		}
	}
	// Tag sga babies for the preterm weeks we care about
	/*	local groups = "27 31 36"
		foreach y of local groups {
			gen sga_group _`y' = .
		}
			forvalues x = 21/27 {
				egen group_27_indic = rowtotal(sga_tag_`x')
		} */
		egen group_1_indic = rowtotal(sga_tag1_*)
		egen group_2_indic = rowtotal(sga_tag2_*)
		egen group_3_indic = rowtotal(sga_tag3_*)
		egen group_4_indic = rowtotal(sga_tag4_*)
		egen sga_all = rowtotal(sga_tag*)

	// Clean and save
	drop wk_* sga_tag*
	save "`output_root'/`iso3'/`iso3'_`module'_`starttime'_sga_prep.dta", replace
