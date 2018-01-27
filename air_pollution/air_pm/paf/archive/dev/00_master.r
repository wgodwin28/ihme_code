#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 06/25/2015
# Purpose: Launch the parallelized calculation of PAF from/exposure to air pollution worldwide
# source("/home/j/WORK/05_risk/01_database/02_data/air_pm/04_paf/04_models/code/dev/00_master.r", echo=T)
#********************************************************************************************************************************

#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  root <- "/home/j" 
} else { 
  root <- "J:"
}

library(data.table)

	# System settings
	mycores <- 4
	rshell <- paste0("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/rshell.sh")
	rscript <- "/home/j/WORK/05_risk/01_database/02_data/air_pm/04_paf/04_models/code/dev/01_calculate_paf.r"
	
	# Job settings.
	functional.form <- "power2"
	rr.version <- "stan"
	exp.grid.version <- "3" # updated version of the gridded dataset with a fix on the extrapolation to 2013
	exp.reg.version <- "adv_regress_draws2014_12_15.csv" # GBD2013 advanced regression
# 	output.version <- "20" # VERSION MATCHES GBD2013 FINAL
#  output.version <- "21" # VERSION CORRECTING FOR THE BUG THAT OVERESTIMATED CVD IHD YLD BURDEN (DID NOT APPLY RATIO)
# 	output.version <- "22" # SAME AS v21 BUT CORRECTION OF THE CORRELATION BUG IN EXPOSURE AS WELL
#   output.version <- "23" # fixed some formatting issues in the code, testing to make sure that it matches #22
#   output.version <- "24" # running a version with the GBD2010 relative risks as a sensitivity analaysis for expert group
#     rr.version <- "gbd2010"
    output.version <- "24" # added some new functionality, testing to make sure that it matches #22	
  
  draws.required <- 1000
  
	# Select the requested outputs
	write.exposure <- TRUE
	write.pafs <- TRUE
	write.rrs <- FALSE
	
	
	# Prep directories to save outputs
	out.paf.dir <-  "/clustertmp/WORK/05_risk/03_outputs/02_results/air_pm"
	out.exp.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/01_exp/05_products/iso3_draws")
	out.rr.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/05_products/")
	
	# Prep directory to save exposure
	dir.create(paste0(out.exp.dir,"/", output.version))
	dir.create(paste0(out.exp.dir,"/", output.version, "/summary"))
	dir.create(paste0(out.exp.dir,"/", output.version, "/draws"))
	
	# Prep directory to save PAFs
	dir.create(paste0(out.paf.dir,"/", output.version))
	dir.create(paste0(out.paf.dir,"/", output.version, "/summary"))
	dir.create(paste0(out.paf.dir,"/", output.version, "/draws"))
	
	# Prep directory to save RRs
	dir.create(paste0(out.rr.dir,"/", output.version))
	dir.create(paste0(out.rr.dir, "/", output.version, "/summary"))
	dir.create(paste0(out.rr.dir, "/", output.version, "/draws"))	
	
	# Get list of countries
	countries <- read.csv("/home/j/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.CSV")
	countries <- countries[countries$indic_epi == 1 & countries$type %in% c("admin0", "admin1"), ]
# 	countries <- countries[countries$indic_epi == 1 & countries$type %in% c("admin1") & !(countries$iso3 %in% c("CHN", "GBR", "MEX")), ] # toggle to run subnationals only
	countries$whereami_id <- ifelse(countries$type == "admin0", as.character(countries$iso3), paste0(countries$gbd_country_iso3, "_", countries$location_id))
	
	locations.list <- unique(countries$whereami_id)
# 	locations.list <- c("GBR_433")
	
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
  		sys.sub <- paste0("qsub -N ", jname, " -pe multi_slot ", mycores, " -l mem_free=", 2 * mycores, "G")
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


