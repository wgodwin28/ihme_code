// do "/snfs2/HOME/wgodwin/risk_factors2/wash/04_save_results/submit_save_results.do"
// Set directories
	if c(os) == "Unix" {
		global j "/home/j"
		set more off
		set odbcmgr unixodbc
	}
	else if c(os) == "Windows" {
		global j "J:"
	}

// Set locals	
	//Risk toggle
		//local risk = "wash_sanitation"
		local risk = "wash_water"
		//local risk = "wash_hwws"
		//local risk = "air_hap"
		local run = "run5"

		if "`risk'" == "wash_sanitation" {
			local exposures 	"improved unimp"
		}

		if "`risk'" == "wash_water" {
			local exposures 	"imp_t imp_t2 imp_untr unimp_t unimp_t2 unimp_untr bas_piped_t bas_piped_t2 bas_piped_untr piped_untr_hq piped_t2_hq"
		}

		if "`risk'" == "wash_hwws" {
			local exposures "wash_hwws"
		}
		
		if "`risk'" == "air_hap" {
			local exposures "air_hap"
		}

	local code_folder	"/snfs2/HOME/wgodwin/risk_factors2/wash/04_save_results"
	local logs 			-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors
	local stata_shell 	"/share/code/wash/04_save_results/stata_shell.sh"
	local dir 			"/share/epi/risk/temp/`risk'/`run'/locations"

//WaSH and HAP save_results master
	foreach exp of local exposures {
		! qsub -N `exp'_save_results -P proj_custom_models -pe multi_slot 20 `logs' "`stata_shell'" "`code_folder'/save_results.do" "`exp' `risk' `dir'"
	}
