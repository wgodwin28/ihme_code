// File Name: run_analysis.do

// File Purpose: Call and execute all do files to perform full analysis of water and sanitation data
// Author: Leslie Mallinger
// Date: 2/12/10
// Edited on:

// Additional Comments: 

/* Options for steps_to_run:
		lsms - standardize LSMS survey data
		other - standardize other (mainly country-specific) surveys
		extract - construct list of files/surveys to process
		lookfor - find variables within surveys
		labels - extract labels from surveys and match with standardized versions
		reports - import and calculate prevalence from reports
		prevalence - calculate prevalence for each type of data
		plot - plot prevalence and proportion uncertain
*/
local steps_to_run extract

** lsms other extract lookfor labels reports prevalence plot

	** assign local for the code directory
	global root_folder 	"J:/WORK/01_covariates/02_inputs/water_sanitation"
	global code_folder 	"H:/rf_code/water/code_extract/code_source/01_Data_Audit"
	global data_folder 	"J:/WORK/01_covariates/02_inputs/water_sanitation/data/01_Data_Audit"
	global model_folder "C:/Users/asthak/Documents/Covariates/Water and Sanitation/model"
	pause on
	capture log close
	log using "${code_folder}/run_all.log", replace

	** create necessary output folders
	cap mkdir "${data_folder}/LSMS"
	cap mkdir "${data_folder}/LSMS/Merged Original Files"
	cap mkdir "${data_folder}/Other"
	cap mkdir "${data_folder}/Other/Merged Original Files"
	cap mkdir "${data_folder}/CHNS"
	cap mkdir "${data_folder}/CHNS/Merged Original Files"
	cap mkdir "${data_folder}/Reports"
	cap mkdir "${data_folder}/Compiled"

	** call do files to prepare data		
		// 1) standardize LSMS survey data
		if regexm("`steps_to_run'", "lsms") {
			di in red _newline _newline "Standardizing LSMS microdata..."
			local do_files: dir "${code_folder}/01.Standardize LSMS" files "*.do", respectcase
			foreach f of local do_files {
				di in red "`f'"
				do "${code_folder}/01.Standardize LSMS/`f'"
			}
		}
		
		// 2) standardize other (mainly country-specific) surveys
		if regexm("`steps_to_run'", "other") {
			di in red _newline _newline "Standardizing other microdata..."
			local do_files: dir "${code_folder}/02.Standardize Other Surveys" files "*.do", respectcase
			foreach f of local do_files {
				di in red "`f'"
				do "${code_folder}/02.Standardize Other Surveys/`f'"
			}
		}
			
		// 3) construct list of files/surveys to process
		if regexm("`steps_to_run'", "extract") {
			di in red _newline _newline "Extracting file list for survey families..."
			local do_files: dir "${code_folder}/03.Extract Files" files "*.do", respectcase
			foreach f of local do_files {
				di in red "`f'"
				do "${code_folder}/03.Extract Files/`f'"
			}
		}
		
		// 4) find variables within surveys
		if regexm("`steps_to_run'", "lookfor") {
			di in red _newline _newline "Looking for variables within survey families..."
			local do_files: dir "${code_folder}/04.Look for Variables" files "*.do", respectcase
			foreach f of local do_files {
				di in red "`f'"
				do "${code_folder}/04.Look for Variables/`f'"
				count if w_srcedrnk == "" & t_type == ""
				if `r(N)' != 0 {
					di in red "WARNING: Survey family `i' has observations without either water or sanitation variables."
					pause
				}
			}
		}
		
		// 5) extract labels from surveys and match with standardized versions
		if regexm("`steps_to_run'", "labels") {
			di in red _newline _newline "Extracting and standardizing labels within survey families..."
			do "${code_folder}/05.Extract and Stdize Labels/extract_labels_all.do"
		}
		
		// 6) import reports
		if regexm("`steps_to_run'", "reports") {
			di in red _newline _newline "Importing report data..."
			local do_files: dir "${code_folder}/06.Import Report Data" files "*.do", respectcase
			foreach f of local do_files {
				di in red "`f'"
				do "${code_folder}/06.Import Report Data/`f'"
			}
		}
		
		// 7) calculate prevalence for each type of data
		if regexm("`steps_to_run'", "prevalence") {
			di in red _newline _newline "Calculating prevalence..."
			do "${code_folder}/07.Calculate Prevalence/run_calculate_prev.do"
		}
		
		// 8) plot
		if regexm("`steps_to_run'", "plot") {
			di in red _newline _newline "Plotting results..."
			do "${code_folder}/08.Plot Prevalence/plot_prop_uncertain.do"
			do "${code_folder}/08.Plot Prevalence/plot_prev_all.do"
		}
		
		
		capture log close
		

		