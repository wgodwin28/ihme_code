// Compile

// Set up
	clear all
	set more off
	if c(os) == "Unix" {
		local prefix "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		local prefix "J:"
	}

// Set locals
	local in_dir "J:\WORK\01_covariates\02_inputs\water_sanitation\data\01_Data_Audit"

	local surveys "chns dhs dlhs ipums lsms mis other pma reports rhs whs" // mics1, whois, unstats should be added separately. Check on "other, JMP"
	gen test=1
	tempfile master
	save `master', replace

// Loop through each survey and append together
	foreach svy of local surveys {
		use "`in_dir'/`svy'/prev_`svy'_final", clear
		append using `master', force
		save `master', replace
	}

	append using "`in_dir'/MICS/prev_mics1", force
	append using "`in_dir'/MICS/prev_mics2_final", force
	append using "`in_dir'/MICS/prev_mics3_final", force
	append using "`in_dir'/MICS/prev_mics4_final", force
	append using "`in_dir'/UN Stats/prev_unstats", force
	append using "`in_dir'/WHO/prev_whosis", force
	drop if iwater_mean == . & ipiped_mean == . & isanitation_mean == . & isewer_mean == . 
	drop if startyear < 1990