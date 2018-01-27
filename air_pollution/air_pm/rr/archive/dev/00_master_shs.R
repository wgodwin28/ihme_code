#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 06/25/2015
# Purpose: Launch RR calculation for household air pollution based on the exposure from Astha and the IER curve
# source("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/00_master_shs.R", echo=T)
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

  # Job settings.
  draws.required <- 1000
	mycores <- 20
	rshell <- paste0("/home/j/WORK/05_risk/01_database/02_data/air_hap/02_rr/04_models/code/rshell.sh")
	rscript <-  paste0("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/01_gen_RR_shs.R")
	
	# Job settings.
	rr.version <- "11"
  ier.curve.version <- "stan"
  rr.functional.form <- "power2"
  prep.data <- F

	# Get list of countries
  countries <- read.csv(paste0(root, "/DATA/IHME_COUNTRY_CODES/IHME_COUNTRY_CODES_Y2013M07D26.CSV"))
	countries <- countries[countries$indic_epi == 1 & countries$type %in% c("admin0", "admin1") & !(countries$iso3 %in% c("CHN", "GBR", "MEX")), ]
# 	countries <- countries[countries$indic_epi == 1 & countries$type %in% c("admin1") & !(countries$iso3 %in% c("CHN", "GBR", "MEX")), ] # run subnationals only
	countries$whereami_id <- ifelse(countries$type == "admin0", as.character(countries$iso3), paste0(countries$gbd_country_iso3, "_", countries$location_id))
	
	locations.list <- unique(countries$whereami_id)
	
	# prep the PM2.5/cigarette draws to preserve covariance across parallelization 
	
	if (prep.data == TRUE) {
	  
	  # bring in the smoking prevalence and cigarettes per capita/smoker datasets to scale by country
	  data.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/smoking_shs/02_rr/04_models/data")
	  covariate.version <- "01162015"
	  # results of RR curve fitting analysis
	  # parameters that define these curves are used to generate age/cause specific RRs for a given exposure level
	  rr.parameters <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/output/", ier.curve.version, "/rr_curve_", rr.functional.form)
	  out.environment <- paste0(data.dir, "/prepped/clean.Rdata") #this file will be read in by each parallelized run in order to preserve draw covariance
	  #objects exported:
	  #SHS.global.exp - calculated PM exposure for smokers in a given country year, see calculation steps below
	  #age.cause - list of all age-cause pairs currently being calculated
	  #rr.curves - compiled list of all the RR curves for the ages/causes of interest)
	  cigs.ps <- fread(paste0(data.dir, "/raw/cigarettes_ps_", covariate.version,".csv"))

	  # set study cigarettes per smoker from which to derive ratios
	  study.cigs.ps.semple <- (13.65175+13.74218+13.74416+13.64030+13.52084)/5 # using the average 2009-2013 Scotland cigarettes per smoker, as these are the years of the studies used in Semple's 2014 paper where we have drawn the distribution of PM2.5 from SHS)

	  # calculate draws of the PM2.5 per cigarette using information from Semple et al (2014)
	  log.sd <- (log(111)-log(31))/qnorm(.75) # formula calculates the log SD from Q3 and Median reported by Semple and assumption of lognormal
	  log.se <- log.sd/sqrt(93) #divide by the sqrt of reported sample size to get the SE
	  log.median <- log(31)
	  pm.cig.semple <- exp(rnorm(draws.required, mean = log.median, sd = log.se))/study.cigs.ps.semple # using a lognormal distribution to convert draws based on median into mean, then divide by cigarettes per smoker in the study to get pm per cigarette
	  
	  pm.draw.colnames <- paste0(1:draws.required)
	  SHS.global.exp <- cigs.ps[, c(pm.draw.colnames) := lapply(1:draws.required, 
	                                                    function(draw.number){
	                                                      
	                                                      cig_ps * pm.cig.semple[draw.number]
	                                                      
	                                                    })]
	  SHS.global.exp <- SHS.global.exp[, c("iso3", 
	                                       "year", 
	                                       pm.draw.colnames), 
	                                   with = F]

	  SHS.global.exp <- melt(SHS.global.exp, 
	                         id=c("iso3","year"), 
	                         variable.name = "draw",
	                         value.name = "exposure",
	                         variable.factor = F)
	  SHS.global.exp[, sex := 3]
	                                                   
	  
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
	  
	  save(SHS.global.exp,
	       age.cause,
	       rr.curves,
	       file=out.environment)
	  
	}

	for (country in locations.list) {
	  for (year in c(1990, 1995, 2000, 2005, 2010, 2013)) {
		# Launch jobs
		jname <- paste0("shs_RR_", country,"_",year,"_",rr.version)
		sys.sub <- paste0("qsub -N ", jname, " -pe multi_slot ", mycores, " -l mem_free=", 2 * mycores, "G")
		args <- paste(country, year, rr.version, ier.curve.version, rr.functional.form, draws.required, mycores)

		system(paste(sys.sub, rshell, rscript, args))	
	  }
	}
	
	rr.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/smoking_shs/02_rr/04_models/output")
	dir.create(paste0(rr.dir, "/", rr.version))
	dir.create(paste0(rr.dir, "/", rr.version, "/lite/"))
	dir.create(paste0(rr.dir, "/", rr.version, "/summary/"))	