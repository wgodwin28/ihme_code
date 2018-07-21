// File Name: extract_labels.ado

// File Purpose: Extract labels for W&S variables for relevant surveys
// Author: Leslie Mallinger
// Date: 4/1/10
// Edited on: 

// Additional Comments:


clear all
set mem 2000m
set maxvar 10000
set more off
capture log close

// set relevant locals
local survey pma
local dataloc "J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit/pma"
local keyloc "J:/Project/COMIND/Water and Sanitation/Data Audit/Data/Label Keys"
local keyversion "assigned_08082011"
local prevtype "final"
quietly run "J:/WORK/01_covariates/02_inputs/water_sanitation/code/01_Data_Audit/05.Extract and Stdize Labels/stdize_label.ado"
quietly run "J:/WORK/01_covariates/02_inputs/water_sanitation/code/01_Data_Audit/05.Extract and Stdize Labels/improved_label.ado"


** open dataset with variable list and store variable data in a mata matrix
use "`dataloc'/varlist_`survey'", clear

mata: vars=st_sdata(.,("location_name", "filedir", "filename", "w_srcedrnk", "t_type"))
local maxobs = _N


** create local with variables whose labels we want to extract
	// NOTE: These variable names are for the overall ("generic") variables that we want to measure, 
	// not the names ("new") present in the individual survey data files.  These "generic" names do not 
	// need to match the ones in the original variable file opened and used above.  They should be no 
	// longer than 9 (?) characters for the dummy variable code to work.
local varlist w_srcedr t_type
local varlistlength: word count `varlist'


** create vector for storing filename and others for storing labels; create local with vector names for later use
mata: filedir = J(`maxobs', 1, "")
mata: filename = J(`maxobs', 1, "")

macro drop _vectors
foreach var of local varlist {
	// default 22 label categories for each variable - should be more than enough, but check to be sure
	forvalues i = 1(1)22 {
		mata: `var'_`i' = J(`maxobs', 1, "")
		local vectors `vectors' `var'_`i'
	}
}


** loop through each file with applicable survey data
forvalues filenum = 1(1)`maxobs' {
	// create locals with file-specific information
		** country and filename
		mata: st_local("location_name", vars[`filenum',1])
		mata: st_local("filedir", vars[`filenum', 2])
		mata: st_local("filename", vars[`filenum', 3])

		** each "generic" variable in varlist
		macro drop _varlist_new
		forvalues varnum = 1(1)`varlistlength' {
			// determine what "generic" variable we are working with
			local var`varnum': word `varnum' of `varlist'
			
			// store local with actual variable name as present in the survey data file itself; append
			// to list of these "new" variable names
			mata: st_local("`var`varnum''", vars[`filenum', 3+`varnum'])
			local varlist_new `varlist_new' ``var`varnum'''
		}
	
	// display file information, then open file and save filename in local
	di _newline _newline "**********************************************************************************"
	di "location_name: `location_name'" _newline "filename: `filename'" _newline "filenum: `filenum'"
	di "**********************************************************************************"
	mata: filedir[`filenum', 1] = "`filedir'"
	mata: filename[`filenum', 1] = "`filename'"

	// check to make sure that the survey has the necessary information; if not, skip to next survey
	if "``var1''" == "NOINFO" continue
	
	// open file and keep variables of interest
	use `varlist_new' using "`filedir'/`filename'", clear

	// loop through variables and extract labels
	forvalues varnum = 1(1)`varlistlength' {
		** check to make sure that the variable exists; if not, skip to next variable
		if "``var`varnum'''" == "" continue
	
		** check to make sure that the variable has entries
		summarize ``var`varnum'''
		if r(N) == 0 {	// no entries
			// fill in list of empty variables
			display "variable empty"
			local emptyvars `emptyvars' `location_name'_`var`varnum''
		}
		else {	// has entries
			// change from numeric variable with string label to string variable
			capture decode ``var`varnum''', generate(`var`varnum'')
			if _rc continue
			drop ``var`varnum'''
		
			// create dummy variables for each category in variable; store list and number of these 
			// dummy variables as locals
			xi i.`var`varnum'', noomit
			local xilist: char _dta[__xi__Vars__To__Drop__]
			local xicount: word count `xilist'
			
			// loop through dummy variables
			forvalues dumnum = 1(1)`xicount' {
				** rename for clarity
				rename _I`var`varnum''_`dumnum' `var`varnum''_`dumnum'
				
				** extract variable labels; remove excess text in label
				local lab`dumnum': variable label `var`varnum''_`dumnum'
				local lab`dumnum' = regexr("`lab`dumnum''", "`var`varnum''==", "")
				
				** assign label to appropriate dummy variable and store in vector for later extraction
				label variable `var`varnum''_`dumnum' "`lab`dumnum''"
				mata: `var`varnum''_`dumnum'[`filenum', 1] = "`lab`dumnum''"
			}
		}		
	}
}


** open file with data file information, add in variable label information, save as label dataset
use "`dataloc'/datfiles_`survey'", clear
getmata `vectors', id(filename)
save "`dataloc'/varlabels_`survey'_`prevtype'", replace
use "`dataloc'/varlabels_`survey'_`prevtype'", clear

** create globals with the different names for each type of water source
insheet using "`keyloc'/label_key_water_`keyversion'.csv", names clear

local types hhconnection pubtapstandpipe tubewellborehole prowell prospring rainwater unprowell /// 
	unprospring carttruck bottled surface otherwater missingwater improvedotherwater unimprovedotherwater /// 
	halfimprovedwater unknownwater

foreach type of local types {
	// convert to use underscores rather than spaces for proper treatment in local
	replace `type' = subinstr(`type', " ", "_", .)
	
	// extract labels into global
	levelsof(`type'), local(`type')
}

** repeat for toilet types
insheet using "`keyloc'/label_key_sanitation_`keyversion'.csv", names clear

local types pubsewer septic pourflush simplepit vip composting bucket openlatrine hanging opendef ///
	othersan missingsan improvedothersan unimprovedothersan halfimprovedsan unknownsan
foreach type of local types {
	// convert to use underscores rather than spaces for proper treatment in local
	replace `type' = subinstr(`type', " ", "_", .)
	
	// extract labels into local
	levelsof(`type'), local(`type')
}


** create blank variables into which the new, standardized form of the label will be placed (`var's), and into which the 
** improved/unimproved designation will be placed (`var'i)
use "`dataloc'/varlabels_`survey'_`prevtype'", clear
foreach var of local vectors {
	// if ihme_loc_id == "GHA" {
		replace `var' = substr(`var', 4, .) if ihme_loc_id == "GHA"
		replace `var' = substr(`var', 4, .) if ihme_loc_id == "KEN" & filename != "KEN_PMA2020_2014_R1_HHQFQ_Y2016M05D13.DTA"
		replace `var' = substr(`var', 4, .) if ihme_loc_id == "UGA" & year_id == "2015"
		replace `var' = substr(`var', 4, .) if ihme_loc_id == "ETH" & year_id == "2015" 
		replace `var' = subinstr(`var', "_", " ", .)
		replace `var' = subinstr(`var', "-", " ", .)
		replace `var' = strlower(`var')
	replace `var' = rtrim(`var')
	replace `var' = ltrim(`var')
	gen `var's = ""
	gen `var'i = .
}


** enter standard form of source name into standardized variables: water sources
	// replace labels
	quietly {
		stdize_label, typelist(`hhconnection') varlist(`vectors') varmatch(w_srce) newlabel(household connection)
		stdize_label, typelist(`pubtapstandpipe') varlist(`vectors') varmatch(w_srce) newlabel(public tap/standpipe)
		stdize_label, typelist(`tubewellborehole') varlist(`vectors') varmatch(w_srce) newlabel(tubewell/borehole)
		stdize_label, typelist(`prowell') varlist(`vectors') varmatch(w_srce) newlabel(protected well)
		stdize_label, typelist(`prospring') varlist(`vectors') varmatch(w_srce) newlabel(protected spring)
		stdize_label, typelist(`rainwater') varlist(`vectors') varmatch(w_srce) newlabel(rainwater collection)
		stdize_label, typelist(`unprowell') varlist(`vectors') varmatch(w_srce) newlabel(unprotected well)
		stdize_label, typelist(`unprospring') varlist(`vectors') varmatch(w_srce) newlabel(unprotected spring)
		stdize_label, typelist(`carttruck') varlist(`vectors') varmatch(w_srce) newlabel(small cart)
		stdize_label, typelist(`bottled') varlist(`vectors') varmatch(w_srce) newlabel(bottled water)
		stdize_label, typelist(`surface') varlist(`vectors') varmatch(w_srce) newlabel(surface water)
		stdize_label, typelist(`otherwater') varlist(`vectors') varmatch(w_srce) newlabel(other)
		stdize_label, typelist(`missingwater') varlist(`vectors') varmatch(w_srce) newlabel(missing)
		stdize_label, typelist(`improvedotherwater') varlist(`vectors') varmatch(w_srce) newlabel(improved, other)
		stdize_label, typelist(`unimprovedotherwater') varlist(`vectors') varmatch(w_srce) newlabel(unimproved, other)
		stdize_label, typelist(`halfimprovedwater') varlist(`vectors') varmatch(w_srce) newlabel(half improved, other)
		stdize_label, typelist(`unknownwater') varlist(`vectors') varmatch(w_srce) newlabel(?)
	}
	
	// save names of standard labels in a local
	local std_labels_water household_connection public_tap/standpipe tubewell/borehole protected_well protected_spring /// 
		rainwater_collection unprotected_well unprotected_spring small_cart bottled_water tanker_truck /// 
		surface_water other missing improved,_other unimproved,_other half_improved,_other ?

	
** enter standard form of source name into standardized variables: toilet types
	// replace labels
	quietly {
		stdize_label, typelist(`pubsewer') varlist(`vectors') varmatch(t_type) newlabel(public sewer)
		stdize_label, typelist(`septic') varlist(`vectors') varmatch(t_type) newlabel(septic system)
		stdize_label, typelist(`pourflush') varlist(`vectors') varmatch(t_type) newlabel(pour-flush latrine)
		stdize_label, typelist(`simplepit') varlist(`vectors') varmatch(t_type) newlabel(simple pit latrine)
		stdize_label, typelist(`vip') varlist(`vectors') varmatch(t_type) newlabel(ventilated improved pit latrine)
		stdize_label, typelist(`composting') varlist(`vectors') varmatch(t_type) newlabel(composting toilet)
		stdize_label, typelist(`bucket') varlist(`vectors') varmatch(t_type) newlabel(bucket latrine)
		stdize_label, typelist(`openlatrine') varlist(`vectors') varmatch(t_type) newlabel(open latrine)
		stdize_label, typelist(`hanging') varlist(`vectors') varmatch(t_type) newlabel(hanging latrine)
		stdize_label, typelist(`opendef') varlist(`vectors') varmatch(t_type) newlabel(open defecation)
		stdize_label, typelist(`othersan') varlist(`vectors') varmatch(t_type) newlabel(other)
		stdize_label, typelist(`missingsan') varlist(`vectors') varmatch(t_type) newlabel(missing)
		stdize_label, typelist(`improvedothersan') varlist(`vectors') varmatch(t_type) newlabel(improved, other)
		stdize_label, typelist(`unimprovedothersan') varlist(`vectors') varmatch(t_type) newlabel(unimproved, other)
		stdize_label, typelist(`halfimprovedsan') varlist(`vectors') varmatch(t_type) newlabel(half improved, other)
		stdize_label, typelist(`unknownsan') varlist(`vectors') varmatch(t_type) newlabel(?)
	}

	// save names of standard labels in a local
	local std_labels_toilets public_sewer septic_system pour-flush_latrine simple_pit_latrine ///
		ventilated_improved_pit_latrine composting_toilet bucket_latrine open_latrine hanging_latrine /// 
		open_defecation other missing improved,_other unimproved,_other half_improved,_other ?

** specify the improved/unimproved status of each standard label; store in local
local improved_water household_connection public_tap/standpipe tubewell/borehole protected_well /// 
	protected_spring rainwater_collection improved,_other
	
local unimproved_water unprotected_well unprotected_spring small_cart tanker_truck /// 
	surface_water unimproved,_other other
	
local halfimproved_water half_improved,_other

local bottled_water bottled_water

local unknown_water missing ?

local improved_sanitation public_sewer septic_system pour-flush_latrine simple_pit_latrine ///
	ventilated_improved_pit_latrine	composting_toilet improved,_other

local unimproved_sanitation bucket_latrine open_latrine hanging_latrine open_defecation other /// 
	unimproved,_other
	
local halfimproved_sanitation half_improved,_other

local unknown_sanitation missing ?


** create variable designating whether a label relates to an improved or unimproved source/type
	// fill in variables (for both water source and toilet type)
	quietly {
		improved_label, typelist(`improved_water') varlist(`vectors') varmatch(w_srce) improved(1)
		improved_label, typelist(`unimproved_water') varlist(`vectors') varmatch(w_srce) improved(0)
		improved_label, typelist(`halfimproved_water') varlist(`vectors') varmatch(w_srce) improved(0.5)
		improved_label, typelist(`bottled_water') varlist(`vectors') varmatch(w_srce) improved(0.49)
		improved_label, typelist(`improved_sanitation') varlist(`vectors') varmatch(t_type) improved(1)
		improved_label, typelist(`unimproved_sanitation') varlist(`vectors') varmatch(t_type) improved(0)
		improved_label, typelist(`halfimproved_sanitation') varlist(`vectors') varmatch(t_type) improved(0.5)
	}
		
		
** clean up variable names and formatting and save
forvalues i = 1(1)22 {
	rename w_srcedr_`i' w_srcedr_o`i'
	rename w_srcedr_`i's w_srcedr_s`i'
	rename w_srcedr_`i'i w_srcedr_i`i'
	local water_vars `water_vars' w_srcedr_o`i' w_srcedr_s`i' w_srcedr_i`i'
	
	rename t_type_`i' t_type_o`i'
	rename t_type_`i's t_type_s`i'
	rename t_type_`i'i t_type_i`i'
	local toilet_vars `toilet_vars' t_type_o`i' t_type_s`i' t_type_i`i'
}
aorder
order location_name ihme_loc_id year_id filename, first
order `water_vars' `toilet_vars', last
save "`dataloc'/varlabels_`survey'_`prevtype'", replace


** for categorization purposes, print the labels lacking a standard designation
local count = 0
forvalues i = 1(1)22 {
	quietly count if w_srcedr_o`i' != "" & w_srcedr_s`i' == ""
	local count = `count' + `r(N)'
}
if `count' > 0 {
	display in red "WARNING: `count' water source labels not yet categorized."
	forvalues i = 1(1)22 {
		list w_srcedr_o`i' if w_srcedr_o`i' != "" & w_srcedr_s`i' == ""
	}
	pause
}

local count = 0
forvalues i = 1(1)22 {
	quietly count if t_type_o`i' != "" & t_type_s`i' == ""
	local count = `count' + `r(N)'
}
if `count' > 0 {
	display in red "WARNING: `count' toilet type labels not yet categorized."
	forvalues i = 1(1)22 {
		list t_type_o`i' if t_type_o`i' != "" & t_type_s`i' == ""
	}
	pause
}


end
