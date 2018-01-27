#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 1/15/2016
# Project: RF: air_pm/air_ozone
# Purpose: Take the global gridded shapefile and cut it up into different countries/subnationals using shapefiles
# This is an update of source("J:/WORK/05_risk/01_database/02_data/air_pm/01_exp/02_nonlit/01_code/gridded_dataset/01_assign_location_ids.r")
# source("/homes/jfrostad/_code/risks/air_pm/exp/01_assign_location_ids.R", echo=T)
# TODO: major wish list for this function is to add ability to produce agg national files for the subnats 
# right now i am just combining all the subnats and calling it national
# (avg exposure at this level often requested)
#********************************************************************************************************************************
 
#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
  rm(list=ls())
  
# disable scientific notation
  options(scipen = 999)
  
# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  
  j_root <- "/home/j/" 
  h_root <- "/homes/jfrostad/"
  #script_root <- dirname(sys.frame(1)$ofile) #this call is giving error of not that many frames in stack??
  script_root <- file.path(h_root, "_code/risks/air_pm/exp") #location of current script
  cores.provided <- 50 # on big jobs i can ask for 100 slots, rule of thumb is 2 slots per core
  
} else { 
  
  j_root <- "J:/"
  h_root <- "H:/"
  script_root <- file.path(h_root, "_code/risks/air_pm/exp") #location of current script
  cores.provided <- parallel::detectCores() - 1 # on my machine this will return 3 cores (quadcore)
  
}
  
  # set working directories
  home.dir <- file.path(j_root, "WORK/05_risk/risks/air_pm/")
  setwd(home.dir)

# load packages, install if missing
  pacman::p_load(data.table, ggplot2, parallel, magrittr, maptools, raster, rgdal, rgeos, sp, splines)
  
# set options
  prediction.method <- "spline" #suggested by mike for GBD2015
  prediction.method <- "aroc" #spline performed poorly, switching back to AROC
  draw.method <- "normal_space" #how to generate draws? (either log_space or normal_space)

# function library
# this pulls the current locations list
source(file.path(h_root, "_code/_lib/functions/get_locations.R"))
# these are helper functions that do a variety of small tasks, see file for more info
source(file.path(script_root, "_lib/assign_tools.R")) 
# this bash script will append all csvs to create a global file, then create national files for each subnational country
#aggregateResults <- paste0("bash ", file.path(h_root, "_code/risks/air_pm/exp/01b_aggregate_results.sh"))  

# Versioning
  #version <- "3" # final GBD2013 version, fixed extrapolation formula error
  #version <- "4" # preliminary GBD2015 version (still using GBD2013 input grids, has new locations/shapefiles/extrapolation function
  #version <- "5" #new GBD2015 verison that uses natural splines instead of smooth splines
  #version <- "6" #test of version should match#5
  #version <- "7" #back to using AROC for extrapolation
  #version <- "8" #first with GBD2015 data (no ozone)
  #version <- "9" #fixed issue with uncertainty
  #version <- 10 #new data sent by gavin to fix issue with island uncertainty
  version <- 11 #run with new shapefile, includes india urb/rural
  version <- 12 #run with fix to generating draws from median/ci (done in log then need to exponet)
  version <- 13 #running v12 again, some countries failed to save..
  version <- 14 #running v12 again, some countries failed to save..
  version <- 15 #running without the fix to test (in normal space, no exponent)
  version <- 16 #rerun of v14, countries all saved but some years were absent??
#********************************************************************************************************************************
   
#----IN/OUT----------------------------------------------------------------------------------------------------------------------
# Set directories and load files
###Input###  
# Get the list of most detailed GBD locations
location_id.list <- data.table(get_locations()) # use a function written by mortality (modified by me to use epi db) to pull from SQL

# Pull in the global shapefile (this was prepped by lucas earl - new mapping specialist)
# full version
# shapefile.dir <- file.path(j_root, "Project/geospatial/GBD2015_geographies/")
# shapefile.version <- "GBD_2015_final_20160201"
# lighter version - w/ bend simplification algorithm to smooth the edges of the polygons with a 5 km tolerance (should be OK for this application)
shapefile.dir <- file.path(j_root, "DATA/SHAPE_FILES/IHME_OFFICIAL/GLOBAL/GBD_v3/MASTER/shapefile")
shapefile.version <- "GBD_2015_full"
  borders <- readOGR(shapefile.dir, layer = shapefile.version)
  borders$location_id <- borders$loc_id # this variable is misnamed in the current official global shape, create it here
  
# import object "newdata" from the file Mike sent
  getwd() %>% file.path("data/exp/raw/GBD2015_PRED_20160706_merged.RData") %>% load(envir = globalenv())
  #getwd() %>% file.path("data/exp/incoming/GBD2015_PRED_merged2.RData") %>% load(envir = globalenv())

###Output### 	
# where to output the split gridded files
	out.dir <-  file.path("/share/gbd/WORK/05_risk/02_models/02_results/air_pm/exp/gridded", version)
	  dir.create(paste0(out.dir), recursive=T, showWarnings=F)

#********************************************************************************************************************************
 
#----PREP GRID-------------------------------------------------------------------------------------------------------------------		
# Set up pollution file
  pollution <- as.data.table(GBD2015_PRED_20160706_merged) #convert to DT
    rm(GBD2015_PRED_20160706_merged) #cleanup
	names(pollution) <- tolower(names(pollution))
	
	# Not interested in all columns
	legacy.variables <- c('id', 'idgridcell', 'iso3', 'pop2020v4', 'dust', 'dust_frac', 'region')
	pollution <- pollution[, -legacy.variables, with=F]
	setnames(pollution, 
	         c('pop_1990v3', 'pop_1995v3', 'pop2000v4', 'pop2005v4', 'pop2010v4', 'pop2011v4', 'pop2012v4', 'pop2013v4', 'pop2014v4', 'pop2015v4'),
	         c('pop_1990', 'pop_1995', 'pop_2000', 'pop_2005', 'pop_2010', 'pop_2011', 'pop_2012', 'pop_2013', 'pop_2014', 'pop_2015'))	

	#define years of interest
	years <- c(1990, 1995, 2000, 2005, 2010, 2011, 2012, 2013, 2014, 2015)
	
	#Create an id column
	pollution[, id := .GRP, by = c('lat', 'long')]

	# Make a raster of the id column
	pollution.sp <- pollution[, c("lat", "long", "id"), with=F]
	  coordinates(pollution.sp) = ~long+lat
	  proj4string(pollution.sp)=CRS("+init=epsg:4326")
	  gridded(pollution.sp) = TRUE
	  
	pollution.sp <- raster(pollution.sp[, c("id")])
	
#********************************************************************************************************************************

#----EXTRACT---------------------------------------------------------------------------------------------------------------------		
# Use raster's extract to get a list of the raster ids that are in a given country
	# The output is a list with one item per country in the borders file
	beginCluster(n=cores.provided) #extract function can multicore, this initializes cluster (must specify n or it will take all cores)
	  raster.ids <- extract(pollution.sp, borders)
	endCluster()
	
	# Convert to dataframe with two columns
	temp <- NULL
	for (iii in 1:length(raster.ids)) {
		if (!is.null(raster.ids[[iii]])) {
		  temp <- rbind(temp, data.frame(location_id=borders$location_id[iii],
		                                 location_name=borders$loc_nm_sh[iii],
		                                 id=raster.ids[[iii]]))
		}
  }
	
	#Some are missing ids
	temp <- temp[!is.na(temp$id), ]
	# Some ids are in multiple countries. Create an indicator
	temp$num_countries <- ave(temp$id, temp$id, FUN=length)
	# Merge back on
	pollution <- merge(temp, pollution, by="id")
	
	# Reduce population by 1/(number of countries grid is in). THis is kind of crude, we could try to get
	# the percentage of the area included in each. I don't really think this is worth it.
	pollution <- data.table(pollution)
	pollution[, paste0("pop_", years) := lapply(years, 
	                                            function(year) get(paste0("pop_", year)) / num_countries), 
	          with=F]
	
#********************************************************************************************************************************

#----MISSING COUNTRIES-----------------------------------------------------------------------------------------------------------	
	# Some countries are too small of islands to pick up any grids. To correct for this,
	# we will take the average values for the rectangular area around islands + 1 (or more if necessary) degrees in any direction
	# This is a pretty crude method, but it should work.
	# Find out which ones
	missing.countries <- unique(borders$location_id)[!(unique(borders$location_id) %in% unique(pollution$location_id))]

	missing.countries.vals <- mclapply(missing.countries,
	                                   estimateIslands,
	                                   borders=borders,
	                                   location_id.list=location_id.list,
	                                   mc.cores=cores.provided)

	pollution <- rbind(pollution, rbindlist(missing.countries.vals))
	pollution <- merge(pollution, 
	                   location_id.list[, c("ihme_loc_id", "location_id"), with=F], 
	                   by="location_id", 
	                   all.x=T)
	
	pollution$num_countries <- pollution$id <- NULL
	
#********************************************************************************************************************************

#----RESHAPE---------------------------------------------------------------------------------------------------------------------	

	# Reshape long
	setkey(pollution, "location_id") 
	pollution <- melt(pollution, id.vars=c("location_id", "location_name", "ihme_loc_id", "long", "lat", "elevation"))
	
	setkey(pollution, "variable")

	pollution[, c("var", "year") := tstrsplit(variable, "_", fixed=TRUE)]
  	pollution[, variable := NULL]
  	
  #reshape the different variables out wide (mean/ci and pop)	
  pollution	<- dcast(pollution, location_id + location_name + ihme_loc_id + long + lat + elevation + year ~ var)	%>% as.data.table #note for some reason when i dcast it reverts to df, look into this (TODO)
  
  #save the reshaped all grid file
  write.csv(pollution, file.path(out.dir, "all.csv"))
  
  #now cleanup	
	gc()

#********************************************************************************************************************************
 
#----FORECAST/SAVE---------------------------------------------------------------------------------------------------------------	
# only need to forecast for ozone, PM has data up to 2015
	# Save by iso3 so that we can run code in parallel
	setkeyv(pollution, c("ihme_loc_id", "long", "lat"))
	 	
	#system("export OMP_NUM_THREADS=1") # there is a potential conflict between R's auto multithreading and mclapply's forking. this command could disable mt to fix it

  global.list <- mclapply(unique(pollution$ihme_loc_id),
                          saveCountry,
                          global.dt = pollution,
                          method = draw.method, #transformation to use when generating draws (log or normal)
                          fx.cores = 10,
                          mc.cores = cores.provided/10) #be surve to divide mc.cores here by function.cores 
  
  #this function is breaking for (seemingly??) no reason on certain countries
  #luckily it returns a try error in the global list, so i can use this to resubmit those countries
  #note this is probably a janky approach to do this, talk to laura to see if i can improve the style
  #this call returns a vector of the indices for failed countries
  failures <- lapply(global.list, function(x) which(class(x)=="try-error")) %>% (function(x) which(x %in% 1))
  
  #set a loop to continue running until there are no failures
  while(length(failures)>0) {
    
    message("trying again, there were #", length(failures), " countries that failed")
    
    #resubmit the function call, except with only the countries who failed
    global.list <- mclapply(unique(pollution$ihme_loc_id)[failures],
                            saveCountry,
                            global.dt = pollution,
                            method = draw.method, #transformation to use when generating draws (log or normal)
                            fx.cores = 10,
                            mc.cores = cores.provided/10) #be surve to divide mc.cores here by function.cores 
    
    #afterwards, reassess the number of failures
    failures <- lapply(global.list, function(x) which(class(x)=="try-error")) %>% (function(x) which(x %in% 1))
  
  }
  
  #output the list of 2015 differences for interactive exploration
  #TODO this is only outputting the final global.list, bring that part out of the loop so it rbinds
  save(global.list,
       file=file.path(out.dir, "all_2015.Rdata"))

  system(aggregateResults) #run a bash script that will append all the results to create a global csv and also national csvs for each subnational
	  
#********************************************************************************************************************************
 
#----SCRAP-----------------------------------------------------------------------------------------------------------------------	
