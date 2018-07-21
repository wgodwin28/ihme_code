#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: WG
# Date: 04/24/2018
# Purpose: RR max calculation for temperature SEVs
# source("/homes/wgodwin/temperature/risk/rr_max.R", echo=T)
#********************************************************************************************************************************
# qsub -N rr_max -pe multi_slot 60 -P "proj_custom_models" -o /homes/wgodwin/output -e /homes/wgodwin/errors /homes/wgodwin/functions/rshell.sh /homes/wgodwin/temperature/risk/rr_max.R 
#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  
  j <- "/home/j/" 
  h <- "/homes/wgodwin/"
  
} else { 
  
  j <- "J:"
  h <- "H:"
  
}

#Load packages
pack_lib = '/snfs2/HOME/wgodwin/R'
pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
# load packages, install if missing
pacman::p_load(data.table, magrittr, ggplot2)

# Settings
draws.required <- 1000
paf.version <- 20
cores.provided <- 6

#--------------------------------Directories---------------------------------------------------------------------------------
rr.dir <- paste0("/share/epi/risk/temp/temperature/paf/",paf.version,"/rr_max/")
causes <- list.dirs(rr.dir, full.names = F, recursive = F)
dir.create(paste0(rr.dir, "values"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_cause_metadata.R"))
cause.dt <- get_cause_metadata(cause_set_version_id = 264)[,.(acause,cause_id)]

find_rr_max <- function(cause){
  #read in files by cause
  files <- list.files(paste0(rr.dir, cause), full.names = T)
  dt <- mclapply(files,fread, mc.cores = cores.provided-1) %>% rbindlist(fill = T)
  
  #generate mean of draws
  dt <- cbind(dt[,.(heat)], collapse_point(dt, draws_name = "rr_", keep_draws = T))
  
  #create ids within groups
  dt[,group_id:=seq_len(.N), by=c("heat")]
  
  #find the 99th percentile
  dt[,perc:=quantile(mean,probs=.99), by=c("heat")]
  dt[,this_row:=which.min(abs(mean-perc)), by=c("heat")]
  dt <- dt[group_id==this_row]
  
  #Format
  cause.id <- cause.dt[acause == cause, cause_id]
  dt[,cause_id := cause.id]
  for(t in c(1,0)){
    #Add necessary columns
    dt.temp <- dt[heat == t]
    
    #for ages where there is a PAF
    ages <- c(seq(3,20),30,31,32,235)
    dt.temp[, age_group_id := 2]
    temp <- copy(dt.temp)
    
    #duplicate out for most detailed ages
    for (i in ages) {
      temp[, age_group_id := i]
      dt.temp <- rbind(dt.temp, temp)
    }

    #Duplicate out for most detailed sex and save
    temp <- copy(dt.temp)
    dt.temp[, sex_id := 1]
    temp[, sex_id := 2]
    dt.temp <- rbind(dt.temp, temp)
    
    #melt and save for Kelly
    dt.temp <- melt(dt.temp,id.vars=setdiff(names(dt.temp),paste0("rr_",1:1000)),measure.vars=paste0("rr_",1:1000),variable.name="draw",value.name="rr_max")
    dt.temp[, draw := as.numeric(gsub("rr_","",draw))]
    dt.temp <- dt.temp[,.(cause_id, sex_id, age_group_id, draw, rr_max)]
    setnames(dt.temp, "rr_max","rr")
    message(paste0("saving ", cause))
    write.csv(dt.temp, paste0(rr.dir, "values/", "rr_max_", cause.id, "_", t, ".csv"), row.names = F)
  }
}

#Run the function over causes of interest
causes <- c("cvd_ihd", "ckd", "diabetes", "cvd_stroke", "resp_copd", "inj_drowning", "nutrition_pem", "lri", "resp_asthma", "uri", "tb")
lapply(causes,find_rr_max)
