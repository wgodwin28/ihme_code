#Purpose: Brazil temperature RR analysis prep-merge on ages, causes, location_ids, format date
rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

# load packages, install if missing  
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
pacman::p_load(data.table, fst, ggplot2, parallel, magrittr, maptools, raster, rgdal, rgeos, sp, splines, stringr, RMySQL, snow, ncdf4)

#source functions
source(paste0(j, "temp/central_comp/libraries/current/r/get_ids.R"))
ages <- get_ids("age_group")
causes <- get_ids("cause")
cod.dir <- paste0(j, "temp/wgodwin/temperature/cod/bra/")

#Query for acauses
source("/share/code/coverage/functions/sql_query.R")
acauses <- sql_query(dbname="cod",
                     host="modeling-cod-db.ihme.washington.edu",
                     query=paste0("SELECT * FROM shared.cause"))
acauses <- acauses[,.(acause, cause_id)]

#read in and append temperature and COD data
bra_cod <- paste0(cod.dir, "years")
cod_dt <- rbindlist(lapply(list.files(bra_cod, full.names = T), fread), fill = T)

#generate gbd age_group_ids
age_map <- fread(paste0(cod.dir, "age_map.csv"))
cod_dt[age > 1, age2 := round(age)]
cod_dt[, age2 := as.integer(age2)]
data <- merge(cod_dt, age_map, by = "age2", all.x = T)
data[age == 0,  age_group_id := 0]
data[age > 0 & age < .01917808, age_group_id := 1]
data[age >= .01917808 & age < .07671233, age_group_id := 2]
data[age >= .07671233 & age < 1, age_group_id := 3]
data[, age2 := NULL]

#merge on gbd location_ids
loc_map <- fread(paste0(cod.dir, "admin2_map.csv"))
loc_map[, adm2_id := substr(adm2_id, 1,6)]
setnames(loc_map, c("adm2_id","adm2_name", "location_id"), c("adm2_id_res", "adm2_name_res", "location_id_res"))
data <- merge(data, loc_map, by = "adm2_id_res", all.x = T)

setnames(loc_map, c("adm2_id_res", "adm2_name_res", "location_id_res"), 
         c("adm2_id_event", "adm2_name_event", "location_id_event"))
data <- merge(data, loc_map, by = "adm2_id_event", all.x = T)

#Read in gbd cause_ids
icd_map <- fread(paste0(j, "temp/wgodwin/temperature/cod/icd_map.csv"))
cause_map <- merge(icd_map, acauses, by="acause", all.x=T)

#Clean bra icd codes
data[nchar(icd10) > 3, icd4 := icd10]
#data[, icd4 := as.integer(icd4)]
data[, icd1 := substr(icd4, 4, 4)]
data[, icd3 := substr(icd4, 1, 3)]
data[, icd10_new := paste0(icd3, ".", icd1)]
data[nchar(icd10) == 3, icd10_new := icd10]
data[, year_id := as.numeric(year_id)]
data[year_id < 1996, i4 := icd10]
data[, i1 := substr(i4, 4, 4)]
data[, i3 := substr(i4, 1, 3)]
data[year_id < 1996, icd10_new := paste0(icd1, ".", icd3)]
data[, c("icd10", "icd1", "icd3", "icd4", "i1", "i3", "i4") := NULL]
setnames(data, "icd10_new", "icd10")

#merge ICD 10 codes onto gbd cause map
data <- merge(data, cause_map, by = "icd10", all.x = T)
data[, country_id := 135]
write.csv(data, paste0(cod.dir, "braCodPrepped.csv"), row.names = F)
