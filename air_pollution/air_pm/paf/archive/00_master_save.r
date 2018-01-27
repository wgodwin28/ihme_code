# Greg Freedman
# Launch PAF calculation for outdoor air pollution
# source("/home/j/WORK/2013/05_risk/01_database/02_data/air_pm/04_paf/04_models/code/00_master_save.r", echo=T)

if (Sys.getenv('SGE_CLUSTER_NAME') == "prod" ) {
  
  project <- "-P proj_gbd_maps" # -p must be set on the production cluster in order to get slots and not be in trouble
  
} else {
  
  project <- "-P proj_gbd_maps" # -dev cluster has projects now
  
}
	
	# System settings
	mycores <- 40
	rshell <- paste0("/home/j/WORK/2013/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/rshell.sh")
	rscript <- "/home/j/WORK/2013/05_risk/01_database/02_data/air_pm/04_paf/04_models/code/01_calculate_paf.r"
	
	# Job settings.
	functional.form <- "power2"
	rr.version <- "stan"
	#rr.version <- "gbd2010"
	exp.grid.version <- "3" # updated version of the gridded dataset with a fix on the extrapolation to 2013
	exp.reg.version <- "adv_regress_draws2014_12_15.csv" # GBD2013 advanced regression
# 	output.version <- "20" # VERSION MATCHES GBD2013 FINAL
#  output.version <- "21" # VERSION CORRECTING FOR THE BUG THAT OVERESTIMATED CVD IHD YLD BURDEN (DID NOT APPLY RATIO)
# 	output.version <- "22" # SAME AS v21 BUT CORRECTION OF THE CORRELATION BUG IN EXPOSURE AS WELL
#   output.version <- "23" # fixed some formatting issues in the code, testing to make sure that it matches #22
# output.version <- "24" # running a version with the GBD2010 relative risks as a sensitivity analaysis for expert group
#	output.version <- "25" # running a version that matches #23 but includes global, and CHN/MEX/GBR
#	output.version <- "26" # new version of scenario calculation (most applicable to CHN)
	output.version <- "27" # new version of code that matches 26 but saves a gridded mean/CI calibrated exposure dataset for outside collaboraters
	
  draws.required <- 1000
  
	# Select the requested outputs
	write.exposure <- TRUE
	write.pafs <- TRUE
	write.rrs <- FALSE
	
	# Get list of countries
	countries <- read.csv("/home/j/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.CSV")
	countries <- countries[countries$indic_epi == 1 & countries$type %in% c("admin0", "admin1"), ]
# 	countries <- countries[countries$indic_epi == 1 & countries$type %in% c("admin1") & !(countries$iso3 %in% c("CHN", "GBR", "MEX")), ] # toggle to run subnationals only
	countries$whereami_id <- ifelse(countries$type == "admin0", as.character(countries$iso3), paste0(countries$gbd_country_iso3, "_", countries$location_id))
	
	locations.list <- unique(countries$whereami_id)
 	locations.list <- c(locations.list, "GLOBAL") # add on global to generate for all grids in world
 	locations.list <- c(locations.list, "CHN", "MEX", "GBR")
# locations.list <- c("CHN", "MEX", "GBR") # toggle to run just aggregate
#	locations.list <- locations.list[grep("CHN",locations.list)] #toggle to only run China and subnationals (for scenario analysis)
# locations.list <- c("GLOBAL") # toggle to run just global
	
	for (country in locations.list) {
	  ifelse(substr(country,1,3) == "CHN",   
           years.list <- c(1990,
                           1995,
                           2000,
                           2005,
                           2010,
                           2013,
                           2014), #note that right now this year is used for calculation of burden attributable to future scenarios (which are only run for China)
	         years.list <- c(1990,
	                         1995,
	                         2000,
	                         2005,
	                         2010,
	                         2013))
    
	for (year in years.list) {
      
	    ifelse(year == 2014,
	           scenario.list <- seq(5,105,10), #these are current scenarios for future air pollution in China
	           scenario.list <- "NA") #if the analysis year is not 2025, these future scenarios do not apply
      
	    for (scenario.pm in scenario.list) {
       
  		# Launch jobs
  		jname <- paste0("air_pm_", country, "_", year, "_v", output.version, "_scenario_",scenario.pm)
  		sys.sub <- paste0("qsub ", project, " -N ", jname, " -pe multi_slot ", mycores, " -l mem_free=", 2 * mycores, "G")
  		args <- paste(country, 
                    year, 
                    functional.form, 
                    rr.version, 
                    exp.grid.version, 
                    exp.reg.version, 
                    output.version, 
                    draws.required, 
                    scenario.pm, 
                    write.exposure, 
                    write.pafs, 
                    write.rrs)
  
  		system(paste(sys.sub, rshell, rscript, args))	

	    }
	  }
	}


