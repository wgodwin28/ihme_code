#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 06/25/2015
# Purpose: Launch RR calculation for household air pollution based on the exposure from Astha and the IER curve
# source("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/00_master_hap.R", echo=T)
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


  # load packages
  require(data.table)
  require(stringr)
  require(reshape2)

	# System settings
	mycores <- 20
	rshell <- paste0("/home/j/WORK/05_risk/01_database/02_data/air_hap/02_rr/04_models/code/rshell.sh")
	rscript <-  paste0("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/01_gen_RR_hap.R")
	
	# Job settings.
	draws.required <- 1000
	rr.version <- "13"
  ier.curve.version <- "stan"
  rr.functional.form <- "power2"
  prep.data <- T

	# Get list of countries
	countries <- read.csv(paste0(root, "/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.CSV"))
	countries <- countries[countries$indic_epi == 1 & countries$type %in% c("admin0", "admin1") & !(countries$iso3 %in% c("CHN", "GBR", "MEX")), ]
# 	countries <- countries[countries$indic_epi == 1 & countries$type %in% c("admin1") & !(countries$iso3 %in% c("CHN", "GBR", "MEX")), ] # run subnationals only
	countries$whereami_id <- ifelse(countries$type == "admin0", as.character(countries$iso3), paste0(countries$gbd_country_iso3, "_", countries$location_id))
	
	locations.list <- unique(countries$whereami_id)
	
	if (prep.data == TRUE) {
	  
	data.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/data")
	exposure.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_hap/02_rr/00_documentation/")
	exposure.version <- "16July2015"
	# results of RR curve fitting analysis
	# parameters that define these curves are used to generate age/cause specific RRs for a given exposure level
	rr.parameters <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/output/", ier.curve.version, "/rr_curve_", rr.functional.form)
	
	out.environment <- paste0(data.dir, "/prepped/clean.Rdata") #this file will be read in by each parallelized run in order to preserve draw covariance
	#objects exported:
	#HAP.global.exp = file created by Astha containing PM2.5 exposure estimates for all country years
	#age.cause - list of all age-cause pairs currently being calculated
	#rr.curves - compiled list of all the RR curves for the ages/causes of interest
	
	# Make a list of all cause-age pairs that we have.
	age.cause <- NULL
	for (cause.code in c("cvd_ihd", "cvd_stroke", "neo_lung", "resp_copd", "lri")) {
	  
	  if (cause.code %in% c("cvd_ihd", "cvd_stroke")) {
	    
	    ages <- seq(25, 80, by=5) # CVD and Stroke have age specific results
	    
	  } else {
	    
	    ages <- c(99) # LRI, COPD and Lung Cancer all have a single age RR (though they reference different ages...)
	    
	  }
	  
	  for (age.code in ages) {
	    
	    age.cause <- rbind(age.cause, c(cause.code, age.code))
	    
	  }
	}
	
	# Prep the RR curves into a single object, so that we can loop through different years without hitting the files extra times.
	rr.curves <- list()
	for (age.cause.number in 1:nrow(age.cause)) {
	  
	  cause.code <- age.cause[age.cause.number, 1]
	  age.code <- age.cause[age.cause.number, 2]
	  
	  rr.curves[[paste0(cause.code, "_", age.code)]] <- read.csv(paste0(rr.parameters, "_", cause.code, "_a", age.code, ".csv"))
	  
	  rr.curves[[paste0(cause.code, "_", age.code)]]$draw <- NULL # Get rid of the draw numbers
	  
	}
	
	# bring in astha's file to scale HAP exposure by region
	HAP.global.exp <- fread(paste0(exposure.dir, "/PM2.5_draws_", exposure.version, ".csv"),stringsAsFactors=F)
	HAP.global.exp <- melt(HAP.global.exp, id=c("iso3","year"), variable.factor = F)
	HAP.global.exp[,c("sex","draw") :=  as.data.table(str_split_fixed(variable, fixed("_"), 2)[,1:2])]
	HAP.global.exp[is.na(as.numeric(draw))==F, draw := as.numeric(draw) + 1] #this step is done to convert from the weird draw numbering of 0-999 vs 1-1000
	setnames(HAP.global.exp, "value", "exposure")
	HAP.global.exp[,variable := NULL]
	
	
	save(HAP.global.exp,
	     rr.curves,
	     age.cause,
	     file=out.environment)
	
	}

	for (country in locations.list) {
	  for (year in c(1990, 1995, 2000, 2005, 2010, 2013)) {
		# Launch jobs
		jname <- paste0("hap_RR_", country,"_",year,"_",rr.version)
		sys.sub <- paste0("qsub -N ", jname, " -pe multi_slot ", mycores, " -l mem_free=", 2 * mycores, "G")
		args <- paste(country, year, rr.version, ier.curve.version, rr.functional.form, draws.required, mycores)

		system(paste(sys.sub, rshell, rscript, args))	
	  }
	}
	
	rr.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_hap/02_rr/04_models/output")
	dir.create(paste0(rr.dir, "/", rr.version))
	dir.create(paste0(rr.dir, "/", rr.version, "/lite/"))
	dir.create(paste0(rr.dir, "/", rr.version, "/summary/"))	

# 	for (country in locations.list) {
# 	  for (year in c(1990, 1995, 2000, 2005, 2010, 2013)) {
# 	    
# 	    x<-file.exists(paste0(rr.dir, "/", rr.version, "/HAP_RR_",country,"_",year,".csv"))
# 	    if (x == F) print(paste0(country,"_",year))
# 	    
# 	    
# 	    
# 	  }}