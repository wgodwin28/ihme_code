################################################################################
# SUPPLEMENTAL MATERIAL of the article:
#   "Mortality risk attributable to high and low ambient temperature:
#     a multi-country study"
#   Antonio Gasparrini and collaborators
#   The Lancet - 2015
#
# This code reproduces the analysis with the subset of data only including UK
#
# 17 March 2016
# * an updated version of this code, (hopefully) compatible with future
#   versions of the software, is available at the personal website of the
#   first author (www.ag-myresearch.com)
################################################################################

################################################################################
# PREPARE THE DATA
################################################################################
#source("/snfs2/HOME/wgodwin/temperature/risk/dlnm/00.prepdata_bycause.R", echo =T)
# LOAD THE PACKAGES
rm(list=ls())
#pack_lib = '/snfs2/HOME/wgodwin/R'
pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
library(dlnm) ; library(mvmeta) ; library(splines) ; library(tsModel) ; library(data.table) # ; library(lubridate)
j <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
source(paste0(j, "temp/central_comp/libraries/current/r/get_covariate_estimates.R"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_ids.R"))
#covs <- get_ids("covariate")
#sdi <- covs[covariate_name =="Socio-demographic Index", covariate_id]
#sdi <- get_covariate_estimates(sdi)[, .(location_id, year_id, mean_value)]

################################################################################
# Set toggles
startyear <- 1999 #2008,mex or 1992,bra or 1999,nza
endyear <- 2015 #2015,nza or 2016,mex,bra
prep_data <- T
country <- T #analysis at country or adm 2 level?
location <- "mex" #mex or bra or nza
location_id <- 130 #130-MEX, 135-BRA, 72-NZA
launch <- F

#Set directories
cod.dir <- paste0(j, "temp/wgodwin/temperature/cod/", location, "/")
temp.dir <- paste0(j, "temp/wgodwin/temperature/exposure/prepped_data/", location, "/era_interim")
diag.dir <- paste0(j, "temp/wgodwin/temperature/gasparrini_dlnm/diagnostics", "/", location, "/")

causes <- c("cvd", "diarrhea","resp", "resp_copd", "resp_asthma", 
            "lri", "ntd_dengue", "zoonotic", "resp_allergic",
            "malaria", "mental", "skin", "inj", "sids", "ntd_guinea",
            "cvd_ihd", "ntd_foodborne", "varicella")

################################################################################
# Prep cause data
if(prep_data){
  
  ##Read in COD data and collapse to death counts for groups of interest
  data <- fread(paste0(cod.dir, location, "CodPrepped.csv"))
  ifelse(location == "nza", data[, date := as.Date(death_date)], data[, date := as.Date(paste(day_id, month_id, year_id, sep = "/"), "%d/%m/%Y")])
  data <- data[order(date)]
  data <- data[!is.na(date),]
  data <- data[year_id > startyear,] ## drop all random deaths before 2008
  data[, adm2_id_res := as.numeric(adm2_id_res)]
  data[, deaths := 1]
  setkey(data, "date")
  #data <- data[sample(.N, 100000),]
  data <- data[, .(deaths, adm2_id_res, adm2_name_res, date, location_id_res, acause)]
  data <- data[, .(deaths = sum(deaths)),
               by = .(adm2_name_res, adm2_id_res, date, location_id_res, acause)] #will want to add in age,sex, etc later
  
  #Read in temperature and prep for merge
  files <- list.files(temp.dir, pattern = ".csv", full.names = T)
  temp.dt <- rbindlist(lapply(files, fread), fill = T)
  
  #Set date variable
  if(location == "mex"){
    temp.dt[, year_id := as.numeric(year_id)]
    temp.dt[, date := paste(day, year_id, sep = "/")]
    temp.dt[, date := as.Date(date, format = "%j/%Y")]
  }else{
    temp.dt[, date := as.Date(date)]
    temp.dt[, year_id := substr(date, 1, 4)]
  }
  
  #format for merge with COD, WILL NEED TO CHANGE THESE VARIABLE NAMES WHEN ANALYSIS LOCATION OF DEATH, NOT LOCATION OF RESIDENCE
  setnames(temp.dt, c("adm2_code", "temperature"), c("adm2_id_res", "temp"))

  ##########CHECK ON IF INCLUDING EXTRA TEMP YEARS FOR BRA, MEX
  temp.dt <- temp.dt[year_id > startyear & year_id < endyear,] 

  #Create list for each cause of interest
  cause.list <- lapply(causes, function(cause){ data[grep(paste(cause), acause)]})
  names(cause.list) <- causes

  #Loop through elements of list and merge with temp and save
  for (i in causes){
    
    #Subset and merge on temperature
    data <- cause.list[[i]]
    data <- merge(data, temp.dt, by = c("date", "adm2_id_res"), all.y = T)
    
    #Merge on admin2/state-level mapping for covariates
    if(location == "bra"){
      admin2 <- fread(paste0(cod.dir, "admin2_map.csv"))
      setnames(admin2, "adm2_id", "adm2_id_res") #CHANGE THIS ALSO WHEN ANALYZING LOCATION OF EVENT
      admin2[, adm2_id_res := as.numeric(substr(adm2_id_res, 1, 6))]
      data <- merge(data, admin2, by="adm2_id_res", all.x = T)
      data[is.na(adm2_name_res), adm2_name_res := adm2_name]
      data[, adm2_name := NULL]
    }
    
    #Merge on covariates
    #sdi <- get_covariate_estimates(covariate_id = 22)
    
    #Clean and write to csv for future use
    data <- data[!is.na(temp)]
    data[is.na(deaths), deaths := 0]
    data[is.na(acause), acause := i]
    data <- setnames(data, c("temp","year_id", "deaths"), c("tmean", "year", "death"))
    data[, dow := weekdays(date)]
    #data <- data[!is.na(adm2_name_res)]
    #data[, time := as.numeric(date - date[1] + 1)]
    outpath <- paste0(cod.dir,"causes/", i, "_cod_temp.csv")
    print(paste("Saving ", i, " ", location))
    write.csv(data, file = outpath, row.names = F)
  }  
}

#############################LAUNCH JOBS BY CAUSE############################################
#set filepaths objects to read in for model running
if(launch){
  paths <- list.files(paste0(cod.dir, "causes"), full.names = T)
  #paths <- lapply(causes, function(x){grep(x, paths, value = T)})
  paths <- grep(".csv", paths, value = T)
  
  # METADATA FOR causes and paths
  cause.meta <- data.table(
    cause = sort(causes),
    path = sort(paths)
  )
  
  #Versioning
  version <- 1 # first run, with subset of causes
  version <- 2
  version <- 3 #run with neg binomial instead of quasi-possion
  
  ##Set qsub objects
  cores <- 4
  rshell <- "/homes/wgodwin/risk_factors2/air_pollution/air_hap/rr/_lib/R_shell.sh"
  project <- "-P proj_custom_models"
  rscript <- "/homes/wgodwin/temperature/risk/dlnm/01.firststage_bycause_child.R"
  sge.output.dir <- "-o /share/temp/sgeoutput/wgodwin/output/ -e /share/temp/sgeoutput/wgodwin/errors/"
  diag.dir <- paste0(diag.dir, "/", version)
  dir.create(diag.dir)
  cause.meta <- fread(paste0(diag.dir, "/cause.meta.csv"))
  
  #loop through causes and submit job to model for each  
  for(acause in causes){
    path <- cause.meta[cause == acause, path]
    args <- paste(path, acause, diag.dir, location)
    jname.arg <- paste0("-N temp_", acause, "_", version)
    mem.arg <- paste0("-l mem_free=", cores*2, "G")
    slot.arg <- paste0("-pe multi_slot ", cores)
    sys.sub <- paste("qsub", project, sge.output.dir, jname.arg, mem.arg, slot.arg)
    system(paste(sys.sub, rshell, rscript, args))
  }
}
############################################################################################