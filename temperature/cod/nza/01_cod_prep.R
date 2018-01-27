#Purpose: Prep COD data to be merged onto temperature raster by day, admin2
#Output should have observation for each death with the corresponding date and admin 2 to be linked to temperature
#source('/snfs2/HOME/wgodwin/temperature/cod/nza/01_cod_prep.R', echo = T)
rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

#install pacman library
if("pacman" %in% rownames(installed.packages())==FALSE){
  library(pacman,lib.loc="/homes/wgodwin/R/x86_64-pc-linux-gnu-library/3.3")
}

# load packages, install if missing  
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
pacman::p_load(data.table, fst, ggplot2, parallel, magrittr, maptools, raster, rgdal, rgeos, sp, splines, stringr, RMySQL, snow, ncdf4, foreign, haven)

#source functions
source(paste0(j, "temp/central_comp/libraries/current/r/get_ids.R"))
ages <- get_ids("age_group")
causes <- get_ids("cause")

#####################################################################################
################## New Zealand COD Prep ###########################################
#####################################################################################
codpath <- paste0(j, "LIMITED_USE/PROJECT_FOLDERS/NZL/GBD_ONLY/MORTALITY_COLLECTION/")
outpath <- paste0(j, "temp/wgodwin/temperature/cod/nza/")

#Read in full dataset, clean and subset
dt <- read_dta(paste0(codpath, "NZL_MORT_COLLECTION_1988_2014_DEATHS_BY_AGE_SEX_ICD_MAORI_NON_MAORI_Y2017M10D02.dta")) %>% as.data.table
setnames(dt, c("DOD", "DOB", "SEX", "DHBDOM", "icdd", "prioritised_ethnic_group"),
         c("death_date", "birth_date", "sex_id", "dhb12", "icd10", "race"))
dt <- dt[, c("death_date", "birth_date", "sex_id", "dhb12", "icd10", "race")]
dt[, dhb12 := as.integer(dhb12)]
dt[, country_id := 72]
dt[sex_id == "M", sex_id := "1"]
dt[sex_id == "F", sex_id := "2"]

#Merge on the correct admin 2 code that applies to shapefile admin 2 codes
codes <- fread(paste0(outpath, "dhbcodes.csv"))
dt <- merge(dt, codes, by = "dhb12", all.x = T)

#Convert birth date to age
dt[, age := as.numeric(death_date - birth_date)/365.25]

#Query for acauses
source("/share/code/coverage/functions/sql_query.R")
acauses <- sql_query(dbname="cod",
                     host="modeling-cod-db.ihme.washington.edu",
                     query=paste0("SELECT * FROM shared.cause"))
acauses <- acauses[,.(acause, cause_id)]

#generate gbd age_group_ids
age_map <- fread(paste0(outpath, "age_map.csv"))
dt[age > 1, age2 := round(age)]
dt[, age2 := as.integer(age2)]
dt <- merge(dt, age_map, by = "age2", all.x = T)
dt[age == 0,  age_group_id := 0]
dt[age > 0 & age < .01917808, age_group_id := 1]
dt[age >= .01917808 & age < .07671233, age_group_id := 2]
dt[age >= .07671233 & age < 1, age_group_id := 3]
dt[, age2 := NULL]

#Assign appropriate location_ids
dt[race == "non-Maori", location_id := 44851]
dt[race == "Maori", location_id := 44850]

#Clean up icd codes
dt[, icd1 := substr(icd10, 4, 4)]
dt[, icd3 := substr(icd10, 1, 3)]
dt[, icd10_new := paste0(icd3, ".", icd1)]
dt[nchar(icd10) > 3, icd10 := icd10_new]
dt[, c("icd1", "icd3", "icd10_new") := NULL]

#Read in gbd cause_ids
icd_map <- fread(paste0(j, "temp/wgodwin/temperature/cod/icd_map.csv"))
cause_map <- merge(icd_map, acauses, by="acause", all.x=T)

#merge ICD 10 codes onto gbd cause map
dt <- merge(dt, cause_map, by = "icd10", all.x = T)

# clean and save
dt[, year_id := substr(death_date, 1,4)]
dt <- dt[year_id>1999,] #subsetting because ICD codes are in different form pre-1999
setnames(dt, c("adm2_code", "name", "location_id"), c("adm2_id_res", "adm2_name_res", "location_id_res"))
write.csv(dt, paste0(outpath, "nzaCodPrepped.csv"), row.names = F)
