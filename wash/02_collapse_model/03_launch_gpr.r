#----HEADER-------------------------------------------------------------------------------------------------------------
# Author:  Will Godwin (stolen from Rachel Updike)
# Date:    January 2018
# Purpose: Run ST-GPR for WaSH and HAP (first, add me_name to this file ONE time - "J:/WORK/01_covariates/common/ubcov_library/model/me_db.csv")
# Run:     source("/snfs2/HOME/wgodwin/risk_factors2/wash/02_collapse_prep/03_launch_gpr.r", echo=TRUE)
#***********************************************************************************************************************

#----CONFIG-------------------------------------------------------------------------------------------------------------
### clear memory
rm(list=ls())

### clean workspace and load special functions
beta_version <- T
if (beta_version) { model_root <- "/ihme/code/st_gpr/beta/model" 
} else { model_root <- "/ihme/code/st_gpr/prod/model" }
setwd(model_root)
source("init.r"); source("register_data.r")

#imp <- model_load(17789, "data")
### set date
date <- format(lubridate::with_tz(Sys.time(), tzone="America/Los_Angeles"), "%m_%d_%y_%H%M")

### load config
config_path <- "/snfs1/WORK/05_risk/risks/wash_water/data/exp/03_model/wash_hap_model_db.csv"
config_file <- fread(config_path)[is_best==1, ]
if (config_file[duplicated(me_name), ] %>% nrow > 0 ) stop(paste0("BREAK | You marked best multiple models for the same me_name: ", 
                                                                  toString(config_file[duplicated(me_name), me_name])))
RUNS <- NULL
#***********************************************************************************************************************

#----FUNCTIONS----------------------------------------------------------------------------------------------------------
###Given a draw directory and save directory, appends together separate csv's and writes full draws to output directory
append_save_draws <- function(in_path, out_path){
  files<-list.files(in_path)
  stack<-list()
  print("stacking 890 csv's")
  for(i in 1:length(files)){
    df<-fread(paste0(in_path, files[i]))
    stack[[i]]<-df
    #print(paste(files[i], "added to stack:", i, "of", length(files)))
  }
  full<-rbindlist(stack, use.names=T)
  print(paste0("saving to ", out_path))
  write.csv(full, file=out_path, row.names=F)
}

#----PREP---------------------------------------------------------------------------------------------------------------
### prep for data upload
all_me_name     <- config_file$me_name %>% unique 
all_my_model_id <- NULL
all_my_model_id <- lapply( 1:length(all_me_name), function(x) c(all_my_model_id, config_file[me_name==all_me_name[x], my_model_id]) )
all_data_notes  <- rep(c("mucho outliering"), length(all_me_name))

### settings
holdouts        <- 0 # 0-10 (0 indicating no cross-validation)
ko_pattern      <- "country"
cluster_project <- "proj_custom_models"
draws           <- 1000                                     
nparallel       <- 60                                       
slots           <- 5
master_slots    <- 3
logs            <- "/share/temp/sgeoutput/wgodwin/logs"
plot            <- F
save_draws 		  <- T
data.version    <- 5

#Versioning for draws saving
run 			<- "run1" #First run using GBD 2016 data
run 			<- "run2" #Run with new data sources ahead of Review Week. New beta testing
run 			<- "run3" #Run batch extract and new modeling structure
run 			<- "run4" #Run after outliering for 1st submission
run       <- "run5"
#***********************************************************************************************************************
#----BATCH LAUNCH-------------------------------------------------------------------------------------------------------------

### batch launch wash and hap models
#for (xx in 1:length(all_me_name)) {
for (xx in c(6)) {
    
me_name     <- all_me_name[xx]
my_model_id <- all_my_model_id[[xx]]
username    <- "wgodwin"
data_notes  <- all_data_notes[xx]
mark_best   <- 0
data_path   <- paste0("/home/j/WORK/05_risk/risks/wash_water/data/exp/03_model/", data.version,"/", me_name, ".csv")
#***********************************************************************************************************************


#----RUN MODEL----------------------------------------------------------------------------------------------------------
### register data
my_data_id  <- register_data(me_name=me_name, path=data_path, user_id=username, notes=data_notes, is_best=mark_best, bypass=TRUE)

### load config file to get model_ids and run_ids assigned
run_ids     <- lapply(1:length(my_data_id), function(x) {
	                  data_id <- my_data_id[x]
	                  id <- register.config(path        = config_path,
	                                        my.model.id = my_model_id, 
	                                        data.id     = data_id)
	                  return(id$run_id)
	})
RUNS <- c(RUNS, run_ids)

### run entire pipeline for each new run_id
mapply(submit.master, run_ids, holdouts, draws, cluster_project, nparallel, slots, model_root, 
	   logs, master_slots, ko_pattern)
#***********************************************************************************************************************


#----SAVE LOG-----------------------------------------------------------------------------------------------------------
### save log to gpr log file
logs_path <- "/home/j/WORK/05_risk/risks/wash_water/data/exp/03_model/wash_hap_run_log.csv"
logs_df   <- data.frame("date"         = format(lubridate::with_tz(Sys.time(), tzone="America/Los_Angeles"), "%m_%d_%y"), 
                        "me_name"      = me_name, 
                        "my_model_id"  = my_model_id, 
                        "run_id"       = run_ids[[1]], 
                        "data_id"      = my_data_id, 
				                "model_id"     = "", 
				                "data_path"    = data_path, 
				                "is_best"      = 0,
				                "notes"        = data_notes,
				                "status"       = "",
				                "best_gbd2016" = NA)
#write.table(logs_df, logs_path, sep=",", col.names=FALSE, append=TRUE, row.names=FALSE)
logs_file <- fread(logs_path) %>% rbind(., logs_df, fill=TRUE)
write.csv(logs_file, logs_path, row.names=FALSE)
print(paste0("Log file saved for ", me_name, " under run_id ", run_ids[[1]]))
#***********************************************************************************************************************
}

#---SAVE DRAWS----------------------------------------------------------------------------------------------------------
###append together and save draws to share if 1000 draws were specified
if(save_draws){
	for(xx in 1:length(all_me_name)){
	  ###Set model objects
	  run_id <- RUNS[[xx]]
	  me_name <- all_me_name[xx]
	  if(grepl("water", me_name) | grepl("fecal", me_name) | grepl("treat", me_name)){risk <- "wash_water"}
	  if(grepl("sanitation", me_name)){risk <- "wash_sanitation"}
	  if(grepl("hwws", me_name) | grepl("air", me_name)){risk <- me_name}
	  
	  ##Set input and output directories
	  dir.create(paste0("/share/epi/risk/temp/", risk, "/", run))
	  save_path <- paste0("/share/epi/risk/temp/", risk, "/", run, "/", me_name, ".csv")
	  draws_dir <- paste0("/share/covariates/ubcov/model/output/", run_id, "/draws_temp_1/")
	  
	  if(draws>0){
	    flag <- 0
	    counter <- 0
	    ##check if draw files are there. Is so, append and save. If not, sleep for 5 min (will repeat for 1 hours).
	    while(flag == 0 & counter < 1) {
	      if(file.exists(paste0(draws_dir, "10.csv"))){
	       append_save_draws(draws_dir, save_path)
	       flag <- 1
	      }else{
	        print(paste0("Draws for ", me_name, " not produced yet, waiting for 5 then re-checking..."))
	        Sys.sleep(300) # wait 5 min
	        counter <- counter + 1
	      }
	    }
	  }
	}
}
#***********************************************************************************************************************

#---PLOT GPR----------------------------------------------------------------------------------------------------------
if(plot){
  #load libraries and functions
  library(magrittr);library(ini);library(stringr);library(rhdf5)
  library(data.table);library(RMySQL);library(grid)
  
  #set some things and check output_path
  risk <- "wash_water" # air_hap, wash_water, wash_sanitation, wash_hygiene
  me_name <- "prop_fecal"
  version <- "v3"
  run_id <- 43940
  
  #Create directory and outpath
  dir.create(paste0("/home/j/WORK/05_risk/risks/", risk, "/diagnostics/exposure/", version))
  date <- format(Sys.Date(), "%m%d%y")
  outpath <-paste0("/home/j/WORK/05_risk/risks/", risk, "/diagnostics/exposure/", version,"/", me_name, "_", run_id, "_", date, ".pdf")
  
  #get time-series plots
  source(paste0("/home/j/WORK/05_risk/central/code/diagnostics/plot_gpr.R"))
  plot_gpr(run.id = run_id, output.path = outpath, add.regions = T, cluster.project = "proj_custom_models", add.gbd2016 = T) #add.gbd2016 = T
  
}
#***********************************************************************************************************************
#MAP
dt.temp <- fread("/share/epi/risk/temp/wash_water/run5/wash_water_piped.csv")
source("/share/code/coverage/functions/collapse_point.R")
source(paste0(j,"WORK/05_risk/central/code/maps/global_map.R"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))

locs <- get_location_metadata(location_set_id=22)[, .(location_id, ihme_loc_id, location_name, super_region_name)]
dt.temp <- collapse_point(dt.temp)
dt.temp <- merge(dt.temp, locs, by = "location_id", all.x = T)
pdf(paste0("/home/j/WORK/05_risk/risks/wash_water/diagnostics/exposure/maps/wash_water_piped.pdf"))
global_map(data=dt.temp, map.var="mean", years = c(1990, 2005, 2017),
           plot.title=paste0("Piped water proportion"),
           #output.path=paste0(out.dir, "global_mmtDif_mexNzl_cold_", c, ".pdf"),
           subnat=T,
           scale="cont",
           #limits = c(seq(0, .2, .04),.25,.3,.4),
           #limits = seq(mi,ma,interval),
           col.rev = F)
dev.off()
