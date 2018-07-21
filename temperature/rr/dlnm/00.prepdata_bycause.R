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
pack_lib = '/snfs2/HOME/wgodwin/R'
#pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
library(dlnm) ; library(mvmeta) ; library(splines) ; library(tsModel) ; library(data.table) # ; library(lubridate)
j <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
source(paste0(j, "temp/central_comp/libraries/current/r/get_covariate_estimates.R"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_ids.R"))
covs <- get_ids("covariate")
sdi <- covs[covariate_name =="Socio-demographic Index", covariate_id]
sdi <- get_covariate_estimates(sdi)[, .(location_id, year_id, mean_value)]
setnames(sdi, "mean_value", "sdi")

################################################################################
# Set toggles
startyear <- 1995 #1995,mex or 1992,bra or 1999,nza
endyear <- 2015 #2015,nza or 2016,mex,bra
prep_data <- T
country <- T #analysis at country or adm 2 level?
location <- "mex" #mex or bra or nza
country <- "Mexico"
location_id <- 130 #130-MEX, 135-BRA, 72-NZA
launch <- F

#Set directories
cod.dir <- paste0("/share/epi/risk/temp/temperature/rr/cod/", location, "/")
temp.dir <- paste0(j, "temp/wgodwin/temperature/exposure/prepped_data/", location, "/era_interim")
diag.dir <- paste0(j, "temp/wgodwin/temperature/gasparrini_dlnm/diagnostics/", location, "/")
covar.dir <- paste0(j, "temp/wgodwin/temperature/cod/covariates/", location, "/")
lights <- fread(paste0(covar.dir, "lights_full.csv"))
setnames(lights, "adm2_id", "adm2_id_res")

causes <- c("cvd", "diarrhea","resp", "resp_copd", "resp_asthma", 
            "lri", "ntd_dengue", "zoonotic", "resp_allergic",
            "malaria", "mental", "skin", "inj", "sids", "ntd_guinea",
            "cvd_ihd", "ntd_foodborne", "varicella")
causes <- c("_enteric_all", "_gc", "_hiv_std", "_infect", 
            "_intent", "_mental", "_neo", "_neuro", "_ntd", 
            "_otherncd", "_ri", "_sense", "_subs", "_unintent")

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
  temp.dt[, date := as.Date(date)]
  temp.dt[, year_id := substr(date, 1, 4)]
  
  #format for merge with COD, WILL NEED TO CHANGE THESE VARIABLE NAMES WHEN ANALYSIS LOCATION OF DEATH, NOT LOCATION OF RESIDENCE
  setnames(temp.dt, c("adm2_id", "temperature"), c("adm2_id_res", "temp"))

  ##########CHECK ON IF INCLUDING EXTRA TEMP YEARS FOR BRA, MEX
  temp.dt <- temp.dt[year_id >= startyear & year_id =< endyear,] 

  #Create list for each cause of interest
  cause.list <- lapply(causes, function(cause){data[grep(paste(cause), acause)]})
  names(cause.list) <- causes

  #Loop through elements of list and merge with temp and save
  for (i in causes){
    
    #Subset and merge on temperature
    data <- cause.list[[i]]
    data <- merge(data, temp.dt, by = c("date", "adm2_id_res"), all.y = T)
    
    #Merge on admin2/state-level mapping for covariates
    #if(location == "bra"){
      admin2 <- fread(paste0(cod.dir, "admin2_map.csv"))
      setnames(admin2, "adm2_id", "adm2_id_res") #CHANGE THIS ALSO WHEN ANALYZING LOCATION OF EVENT
      admin2[, adm2_id_res := as.numeric(substr(adm2_id_res, 1, 6))]
      data <- merge(data, admin2, by="adm2_id_res", all.x = T)
      data[is.na(adm2_name_res), adm2_name_res := adm2_name]
      data[is.na(location_id_res), location_id_res := location_id]
      data[, adm2_name := NULL]
      data[, year_id := as.numeric(year_id)]
      data[, adm2_id_res := as.character(adm2_id_res)]
    #}
    
    #Merge on covariates and populations (contained in night-time lights dataset)
    data <- merge(data, sdi, by = c("location_id", "year_id"), all.x = T)
    data <- merge(data, lights, by = c("adm2_id_res", "year_id"), all.x = T)
      
    #Clean and write to csv for future use
    #data <- data[!is.na(temp)]
    data[is.na(deaths), deaths := 0]
    data[is.na(acause), acause := i]
    data <- setnames(data, c("temp","year_id", "deaths"), c("tmean", "year", "death"))
    #data[, dow := weekdays(date)]
    #data <- data[!is.na(adm2_name_res)]
    #data[, time := as.numeric(date - date[1] + 1)]
    data[, c("location_id", "adm2_name") := NULL]
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
  version <- 4 #offset implementation, plus sdi in model
  
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
    args <- paste(path, acause, diag.dir, location, country)
    jname.arg <- paste0("-N temp_", acause, "_", version)
    mem.arg <- paste0("-l mem_free=", cores*2, "G")
    slot.arg <- paste0("-pe multi_slot ", cores)
    sys.sub <- paste("qsub", project, sge.output.dir, jname.arg, mem.arg, slot.arg)
    system(paste(sys.sub, rshell, rscript, args))
  }
}
############################################################################################

####SCRAP####
pop <- fread("/home/j/WORK/05_risk/risks/temperature/data/exp/pop/mex/age_broad/pop_full.csv")
pop[age_group_id == 39, age_bin := 1]
pop[age_group_id == 156, age_bin := 2]
pop[age_group_id == 223, age_bin := 3]
#Sum over sex_id since not running models by sex
pop <- pop[, .(population = sum(population)),
           by = .(adm2_id, year_id, age_bin)]

#Bring in cod data
data2 <- fread("/home/j/temp/Jeff/temperature/inputs/mex/mexCodPrepped_1996-2015.csv")
data2[, date := as.Date(date_id, "%d%b%Y")]
data2 <- data2[order(date)]
data2 <- data2[!is.na(date),]
data2 <- data2[year_id > startyear,] ## drop all random deaths before 2008
data2[, adm2_id_res := as.numeric(adm2_id_res)]
data2[, deaths := 1]
setkey(data2, "date")
data2[age_value > 0 & age_value < 14.99, age_bin := 1]
data2[age_value >= 15 & age_value < 44.99, age_bin := 2]
data2[age_value >= 45 & age_value < 121, age_bin := 3]

#Sum deaths by date, location, age
data2 <- data2[, .(deaths, adm2_id_res, adm2_name_res, date, location_id_res, gbd_level2_cause, gbd_cause_name, age_bin)]
data2 <- data2[, .(deaths = sum(deaths)),
             by = .(adm2_name_res, adm2_id_res, date, location_id_res, gbd_level2_cause, age_bin)]

#Read in temperature and prep for merge
files <- list.files(temp.dir, pattern = ".csv", full.names = T)
temp.dt <- rbindlist(lapply(files, fread), fill = T)

#Set date variable
temp.dt[, date := as.Date(date)]
temp.dt[, year_id := substr(date, 1, 4)]

#format for merge with COD, WILL NEED TO CHANGE THESE VARIABLE NAMES WHEN ANALYSIS LOCATION OF DEATH, NOT LOCATION OF RESIDENCE
#setnames(temp.dt, c("adm2_id", "temperature"), c("adm2_id_res", "temp"))
setnames(data2, c("adm2_id_res", "location_id_res"), c("adm2_id", "location_id"))
##########CHECK ON IF INCLUDING EXTRA TEMP YEARS FOR BRA, MEX
temp.dt <- temp.dt[year_id > startyear & year_id < endyear,] 
temp.dt[, population := NULL]

#Create list for each cause of interest
cause.list <- lapply(causes, function(cause){data2[grep(paste(cause), gbd_level2_cause)]})
names(cause.list) <- causes

#Loop through causes
for (i in causes){
  
  #Subset and merge on temperature
  data <- cause.list[[i]]
  data <- merge(data, temp.dt, by = c("date", "adm2_id"), all.y = T)
  
  #Merge on admin2/state-level mapping for covariates
  #if(location == "bra"){
  admin2 <- fread(paste0(cod.dir, "admin2_map.csv"))
  #setnames(admin2, "adm2_id", "adm2_id_res") #CHANGE THIS ALSO WHEN ANALYZING LOCATION OF EVENT
  admin2[, adm2_id := as.numeric(substr(adm2_id, 1, 6))]
  data <- merge(data, admin2, by="adm2_id", all.x = T)
  data[is.na(adm2_name_res), adm2_name_res := adm2_name]
  data[is.na(location_id.x), location_id.x := location_id.y]
  data[, adm2_name := NULL]
  data[, year_id := as.numeric(year_id)]
  data[, adm2_id := as.character(adm2_id)]
  setnames(data, "location_id.x", "location_id")
  #}
  
  #Merge on covariates and populations (contained in night-time lights dataset)
  data <- merge(data, sdi, by = c("location_id", "year_id"), all.x = T)
  data <- merge(data, pop, by = c("location_id", "year_id", "age_bin"))
}