#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 06/25/2015
# Purpose: Launch RR calculation for household air pollution based on the exposure from Astha and the IER curve
# source("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/00_master_as.R", echo=T)
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
	rscript <-  paste0("/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/01_gen_RR_as.R")
	
	# Job settings.
	rr.version <- "4"
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
	  out.environment <- paste0(root, "/WORK/05_risk/01_database/02_data/smoking_direct/02_rr/04_models/data/prepped/clean.Rdata") #this file will be read in by each parallelized run in order to preserve draw covariance) #this file will be read in by each parallelized run in order to preserve draw covariance
	  #objects exported:
	  #AS.global.exp - calculated PM exposure for smokers in a given country year, see calculation steps below
	  #age.cause - list of all age-cause pairs currently being calculated
	  #rr.curves - compiled list of all the RR curves for the ages/causes of interest)
	  cigs.ps <- fread(paste0(data.dir, "/raw/cigarettes_ps_", covariate.version,".csv"))

	  # set PM per cigarette from (Rick's email on 11/19/14: anyway,  the conversion used is correct 666.6 ug/m3 = 1 cig/day - this comes from the 12ng of PM2.5 per 1 cig and a average adult breating rate of 18 m3/day - 12,000 ug/1cig/(18 m3.day) = 666.6  ug/m3 per day)
	  pm.per.cig <- 666.6	  
	  
	  # set mean and SD to determine variation around the cigs/smoker metric (determined from ACSII Pope table of smoking frequencies and this code "J:\WORK\05_risk\01_database\02_data\air_pm\02_rr\04_models\code\AS_SHS_prep_covariates.do")
	  # decided to change the previous approach to better preserve covariance. took the mean/SD from ASCII Pope table of smoking frequency and converted into logspace - using wikipedia formula, then create draws, then exponeniate and divide by the mean cigs/smoker in the study in order to normalize it so that it can be multiplied against marie's country year cigs/smoker data and provide uncertainty
	  # new change on 07152015, realized that the IER curve is an estimation of uncertainty around the mean, whereas using the SD from ASCII would be an estimation of uncertainty around the population. As such, I have converted it to SE using the sqrt of N from ACSII Pope table, in the future we will need to think of a new method that Mehrdad has ideas about regarding calculating the entire IER curve for each draw of exposure and taking the mean. 
	  
	  log.mean <- 2.97
	  log.sd <- .47
	  mean <- 22.4095
	  sd <- 11.98967
	  se <- sd / sqrt(794784)
	  
	  draws <- rnorm(1000,mean=mean, sd=se)/22.4095
	  
	  pm.draw.colnames <- paste0(1:draws.required)
	  AS.global.exp <- cigs.ps[, c(pm.draw.colnames) := lapply(1:draws.required, 
	                                                    function(draw.number){
	                                                      
	                                                      cig_ps * pm.per.cig * draws[draw.number]
	                                                      
	                                                    })]
	  AS.global.exp <- AS.global.exp[, c("iso3", 
	                                       "year", 
	                                       pm.draw.colnames), 
	                                   with = F]

	  AS.global.exp <- melt(AS.global.exp, 
	                         id=c("iso3","year"), 
	                         variable.name = "draw",
	                         value.name = "exposure",
	                         variable.factor = F)
	  AS.global.exp[, sex := 3]
	                                                   
	  
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
	  
	  save(AS.global.exp,
	       age.cause,
	       rr.curves,
	       file=out.environment)
	  
	}

	for (country in locations.list) {
	  for (year in c(1990, 1995, 2000, 2005, 2010, 2013)) {
		# Launch jobs
		jname <- paste0("as_RR_", country,"_",year,"_",rr.version)
		sys.sub <- paste0("qsub -N ", jname, " -pe multi_slot ", mycores, " -l mem_free=", 2 * mycores, "G")
		args <- paste(country, year, rr.version, ier.curve.version, rr.functional.form, draws.required, mycores)

		system(paste(sys.sub, rshell, rscript, args))	
	  }
	}
	
	rr.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/smoking_direct/02_rr/04_models/output")
	dir.create(paste0(rr.dir, "/", rr.version))
	dir.create(paste0(rr.dir, "/", rr.version, "/lite/"))
	dir.create(paste0(rr.dir, "/", rr.version, "/summary/"))	