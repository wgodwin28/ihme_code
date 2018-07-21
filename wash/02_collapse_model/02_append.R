## Append on new collapsed data for WaSH and HAP indicators pre-STGPR modeling
## Author: Will Godwin
## Date: 02/20/2018


## SETUP ############################################################
## Setup environment
rm(list=ls())
windows <- Sys.info()[1]=="Windows"
j <- ifelse(Sys.info()[1]=="Windows","J:/","/home/j/")
user <- ifelse(windows, Sys.getenv("USERNAME"), Sys.getenv("USER"))
library(boot)

#Versioning
version <- 1 #update with ~15 new surveys (IND DHS) to run before review week
version <- 2 # batch extract and collapse with new modeling framework
version <- 3 # string mapping fixes
version <- 4 # more string mapping fixes
version <- 5 # some hacky outliering pre-first submission
version <- 6 # water vetting

#set in and out objects
in.dir <- paste0(j, "WORK/05_risk/risks/wash_water/data/exp/02_analyses/collapse/")
date <- "2018-07-18"
data.dir <- paste0(j, "WORK/05_risk/risks/wash_water/data/exp/03_model/", version-1, "/")
out.dir <- paste0(j, "WORK/05_risk/risks/wash_water/data/exp/03_model/", version, "/")
dir.create(out.dir, showWarnings = F)
piped_cov <- F

#get locations
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
locations <- get_location_metadata(location_set_id=22)[, .(location_id, ihme_loc_id)]

#Read in current collapsed dataset
dt <- fread(paste0(in.dir, "collapse_wash_", date, ".csv"))
census <- fread(paste0(in.dir, "collapse_census_", date, ".csv"))
dt <- rbind(dt, census)
dt <- merge(dt, locations, by = "ihme_loc_id", all.x = T)
me_ids <- dt[, unique(var)]

#Loop through me_ids
for(me in me_ids) {
  #subset to me_id of interest
  dt.temp <- dt[var == me]
  dt.temp <- dt.temp[,.(nid, location_id, ihme_loc_id, year_start, mean, standard_error, sample_size)]
  
  ####HACKY OUTLIERING#########
  if(me == "wash_water_piped"){
    dt.temp[ihme_loc_id == "ITA" | ihme_loc_id == "ESP", mean := NA]
    dt.temp[ihme_loc_id == "ITA" & year_start == 2006, mean := NA]
    dt.temp[ihme_loc_id == "BGD" & nid == 95474, mean := NA] ## Actually oulier this point
    dt.temp[ihme_loc_id == "COD", mean := NA]
    dt.temp[ihme_loc_id == "DJI", mean := NA]
    dt.temp <- dt.temp[mean > 0]
  }
  if(me == "wash_sanitation_piped"){
    dt.temp[ihme_loc_id == "VNM" | nid == 43571, mean := NA] ## Actually oulier this point
    dt.temp[ihme_loc_id == "ISR" & year_start == 1983, mean := NA] ## check on this point-shouldn't be 0
    dt.temp[ihme_loc_id == "ARG" & year_start == 2011, mean := NA] ## check on this point-shouldn't be 0
    dt.temp[ihme_loc_id == "JAM" & year_start == 2006, mean := NA] ## check on this point-shouldn't be so high
    dt.temp[ihme_loc_id == "PER" & year_start > 2010, mean := NA] ## check on these point-shouldn't be so low
    dt.temp[ihme_loc_id == "ECU" & nid == 105801, mean := NA] ## check on this point-shouldn't be 0
    dt.temp[ihme_loc_id == "BOL", mean := NA] ## EVERYTHING IN BOL IS CRAZY!!
    dt.temp[ihme_loc_id == "MEX" & year_start > 2007, mean := NA] ## check on these points-shouldn't be so low
    dt.temp[ihme_loc_id == "BRA" & year_start == 2002, mean := NA] ## check on these points-weird trend
    dt.temp[ihme_loc_id == "JOR" & year_start == 2004, mean := NA] ## check on this point-shouldn't be 0
    dt.temp[ihme_loc_id == "MAR" & mean < .05, mean := NA] ## check on this point-shouldn't be 0
    dt.temp[ihme_loc_id == "IND" & year_start == 2015, mean := NA] ## check on this point-shouldn't be low
    dt.temp[ihme_loc_id == "BWA", mean := NA] #Why is everything 0??
    dt.temp[ihme_loc_id == "ZAF" & mean > .9, mean := NA] #two crazy high data points to check on
    dt.temp[ihme_loc_id == "NGA" & nid == 50441, mean := NA] ## check on this point-shouldn't be so high
    dt.temp[ihme_loc_id == "AGO" & nid == 30394, mean := NA]
    dt.temp[ihme_loc_id == "YEM" & nid == 244467, mean := NA]
    dt.temp[ihme_loc_id == "ECU" & nid == 95320, mean := NA]
    dt.temp[ihme_loc_id == "ESP" & nid == 227200, mean := NA]
    dt.temp[ihme_loc_id == "BLZ" & nid == 314646, mean := NA]
    
  }
  if(me == "wash_sanitation_imp_prop"){
    dt.temp[ihme_loc_id == "UGA" & mean < .43, mean := NA]## look at this low data points
  }
  if(me == "wash_hwws"){
    dt.temp[ihme_loc_id == "EGY" & nid == 19511, mean := NA]## look at this low data points
    dt.temp[ihme_loc_id == "EGY" & nid == 19529, mean := NA]## look at this low data points
  }
  if(me == "wash_water_imp_prop"){
    dt.temp[ihme_loc_id == "ECU" & mean < .43, mean := NA]## look at this low data points
    dt.temp[ihme_loc_id == "ECU" & mean < .5, mean := NA]## look at this low data points
    dt.temp[ihme_loc_id == "MEX" & year_start > 2009, mean := NA]
    dt.temp[ihme_loc_id == "BOL" & nid == 1344, mean := NA] ## check on this point-shouldn't be so high
    dt.temp[ihme_loc_id == "BOL" & nid == 1301, mean := NA] ## check on this point-shouldn't be so high
    dt.temp[ihme_loc_id == "BOL" & nid == 1308, mean := NA] ## check on this point-shouldn't be so high
    dt.temp[ihme_loc_id == "BOL" & nid == 1357, mean := NA] ## check on this point-shouldn't be so high
    dt.temp[ihme_loc_id == "BOL", mean := NA] ## BOL
    dt.temp[ihme_loc_id == "PER" & nid == 41267, mean := NA] ## check on this point-shouldn't be so high
    dt.temp[ihme_loc_id == "PER" & nid == 33288, mean := NA] ## check on this point-shouldn't be so high
    dt.temp[ihme_loc_id == "PER" & nid == 49279, mean := NA] ## check on this point-shouldn't be so high
    dt.temp[ihme_loc_id == "DOM", mean := NA] ### ALL OF DOM IS CRAZY!!! Check on this
    dt.temp[ihme_loc_id == "JAM" & nid == 39450, mean := NA] ## check on this point-shouldn't be so low
    dt.temp[ihme_loc_id == "URY" & nid == 56532, mean := NA]
    dt.temp[ihme_loc_id == "URY" & nid == 151322, mean := NA]
    dt.temp[ihme_loc_id == "AUT" & nid == 859, mean := NA]
    dt.temp[ihme_loc_id == "AUT" & nid == 854, mean := NA]
    dt.temp[ihme_loc_id == "ARG" & nid == 34012, mean := NA]
    dt.temp[ihme_loc_id == "ARG" & nid == 137208, mean := NA]
    dt.temp[ihme_loc_id == "CHL" & nid == 2301, mean := NA]
    dt.temp[ihme_loc_id == "ESP" & nid == 43199, mean := NA]
    dt.temp[ihme_loc_id == "ESP" & nid == 227200, mean := NA]
    dt.temp[ihme_loc_id == "PRT" & nid == 41861, mean := NA]
    dt.temp[ihme_loc_id == "PRT" & nid == 41866, mean := NA]
    dt.temp[ihme_loc_id == "PRT" & nid == 41871, mean := NA]
    dt.temp[ihme_loc_id == "ITA" & nid == 39432, mean := NA]
    dt.temp[ihme_loc_id == "IRL" & nid == 39376, mean := NA]
  }
  #Clean collapsed dataset to match modeling template dataset
  setnames(dt.temp, c("mean", "year_start"), c("data", "year_id"))
  dt.temp[, variance := standard_error^2]
  dt.temp[variance == 0, variance := (data*(1-data))/sample_size]
  dt.temp[, age_group_id := 22]
  dt.temp[, sex_id := 3]
  dt.temp[, me_name := me]
  dt.temp[data > .9999, data := .99]
  if(me == "wash_water_imp_prop" | me == "wash_sanitation_imp_prop"){
    dt.temp <- dt.temp[data > 0]
  }
  #dt.temp <- dt.temp[data > 0] #drop all zeros because I don't believe them...
  dt.temp <- dt.temp[!is.na(location_id)]
  dt.new <- copy(dt.temp)
  #read in old data to append on
  dt.old <- fread(paste0(data.dir, me, ".csv"))
  dt.new <- rbind(dt.old, dt.temp, fill = T)
  
  #save for modeling
  print(me)
  write.csv(dt.new, paste0(out.dir, me, ".csv"), row.names = F)
}

#copy over prop_fecal dataset
fecal <- fread(paste0(data.dir, "prop_fecal.csv"))
write.csv(fecal, paste0(out.dir, "prop_fecal.csv"), row.names = F)

#If need to add on piped covariate for handwashing and prop_fecal model
if(piped_cov){
  source("/share/code/coverage/functions/collapse_point.R")
  dt <- fread("/share/epi/risk/temp/wash_water/run5/wash_water_piped.csv") ### CHANGE THIS TO CURRENT BEST PIPED WATER MODEL OUTPUT
  dt <- collapse_point(dt)
  setnames(dt, "mean", "cv_piped")
  dt <- dt[, .(location_id, year_id, cv_piped)]
  
  #Handwashing
  hw <- fread("/home/j/WORK/05_risk/risks/wash_water/data/exp/03_model/best_2016/wash_hwws.csv") #most recent handwashing input data
  hw$cv_piped <- NULL
  new <- merge(hw, dt, by = c("location_id", "year_id"), all.y = T)
  new[cv_piped >= 1, cv_piped := .999]
  new[, age_group_id := 22]
  new[, sex_id := 3]
  new[, me_name := "wash_hwws"]
  write.csv(new, paste0(out.dir, "wash_hwws.csv"), row.names = F)
  
  #Prop_fecal
  fecal <- fread(paste0(out.dir, "prop_fecal.csv"))
  fecal$cv_piped <- NULL
  new <- merge(fecal, dt, by = c("location_id", "year_id"), all.y = T)
  new[cv_piped >= 1, cv_piped := .999]
  new[, age_group_id := 22]
  new[, sex_id := 3]
  new[, me_name := "prop_fecal"]
  write.csv(new, paste0(out.dir, "prop_fecal.csv"), row.names = F)
}