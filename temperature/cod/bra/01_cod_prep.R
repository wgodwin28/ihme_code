#Purpose: Prep COD data to be merged onto temperature raster by day, admin2
#Output should have observation for each death with the corresponding date and admin 2 to be linked to temperature
#source('/snfs2/HOME/wgodwin/temperature/cod/bra/01_cod_prep.R', echo = T)
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

#Helpful custom functions
stata_dt <- function(x){
  dt <- read_dta(x) %>% as.data.table
  print(paste("reading", x))
  return(dt)}
#####################################################################################
################## United States COD Prep ###########################################
#####################################################################################
for(year in 1990:2016){
  codpath <- paste0(j, "LIMITED_USE/PROJECT_FOLDERS/USA/NVSS_MORTALITY/", year, "/")
  outpath <- paste0(j, "temp/wgodwin/temperature/cod/us/")
  test <- read.table(paste0(codpath, "USA_NVSS_MORTALITY_1989_COUNTIES_Y2017M08D11.TXT"), header = T)
}
#####################################################################################
################### Brazil COD Prep #################################################
#####################################################################################

codpath <- paste0(j, "LIMITED_USE/PROJECT_FOLDERS/BRA/GBD_FROM_COLLABORATORS/SIM/")
outpath <- paste0(j, "temp/wgodwin/temperature/cod/bra/")

############# 2013,2014,2015 years prep #############################################
#bra <- fread(paste0(j, "LIMITED_USE/PROJECT_FOLDERS/BRA/GBD_FROM_COLLABORATORS/SIM/BRA_SIM_2014_DEATHS_ICD10_BY_STATE_Y2016M10D19.CSV"))
bra <- fread(paste0(j, "LIMITED_USE/PROJECT_FOLDERS/BRA/GBD_FROM_COLLABORATORS/SIM/BRA_SIM_2015_DEATHS_ICD10_BY_STATE_Y2016M10D26.CSV"))
#bra <- read_dta(paste0(j, "LIMITED_USE/PROJECT_FOLDERS/BRA/GBD_FROM_COLLABORATORS/SIM/BRA_2013_MORT_Y2014M11D04.DTA")) %>% as.data.table
vars <- length(names(bra))
setnames(bra, tolower(names(bra[1:vars])))
bra <- bra[, .(dtobito, dtnasc, sexo, codmunocor, codmunres, causabas)]
setnames(bra, c("dtobito", "dtnasc", "sexo", "codmunocor", "codmunres", "causabas"), 
         c("death_date", "birth_date", "sex_id", "adm2_id_event", "adm2_id_res", "icd10"))
bra[, parent_id := 135]

# Set date for linking with temperature
bra[nchar(death_date) == 7, date := paste0(0, death_date)]
bra[nchar(death_date) == 8, date := death_date]
bra[, date := as.Date(as.character(date), "%e%m%Y")]
bra[, year_id := substr(date, 1, 4)]
bra[, month_id := substr(date, 6,7)]
bra[, day_id := substr(date, 9,10)]

#Convert birth date to age
bra[nchar(birth_date) == 7, date2 := paste0(0, birth_date)]
bra[nchar(birth_date) == 8, date2 := birth_date]
bra[, birth_date := as.Date(as.character(date2), "%e%m%Y")]
bra[, age := as.numeric(date - birth_date)]
bra[, age := age/365.25]
year <- bra$year_id[1]

# clean and save
bra <- bra[, .(year_id, month_id, day_id, age, sex_id, parent_id, adm2_id_event, adm2_id_res, icd10, birth_date)]
write.csv(bra, paste0(outpath, "cod_", year, ".csv"), row.names = F)

##only processing 1993-2012 since previous years do not have day and month of death
########### 1993,1994,1995 years prep ##############################################
for (year in 1993:1995){
  bra.dir <- paste0(j, "DATA/BRA/MORTALITY_INFORMATION_SYSTEM_SIM/", year)
  files <- list.files(bra.dir, full.names = T)
  files <- grep("DTA", files, value = T)
  dt <- lapply(files, read.dta) %>% rbindlist
  
  #subset to the vars of interest
  dt <- dt[, .(dataobito, sexo, muniocor, munires, causabas, datanasc)]
  setnames(dt, c("dataobito", "datanasc", "sexo", "muniocor", "munires", "causabas"), 
           c("death_date", "birth_date", "sex_id", "adm2_id_event", "adm2_id_res", "icd10"))
  #standardize adm2 code (code is 7 numbers instead of 6 in these data for some reason...)
  dt[,adm2_id_event := substr(adm2_id_event, 1,6)]
  dt[,adm2_id_res := substr(adm2_id_res, 1,6)]
  
  #set date of death and date of birth
  dt[, date := as.Date(as.character(death_date), "%y%m%e")]
  dt[, year_id := substr(date, 1, 4)]
  dt[, month_id := substr(date, 6,7)]
  dt[, day_id := substr(date, 9,10)]
  dt[, birth_date := as.Date(as.character(birth_date), "%Y%m%e")]
  dt[, age := as.numeric(date - birth_date)]
  dt[, age := age/365.25]
  dt[, parent_id := 135]
  
  # clean and save
  dt <- dt[, .(year_id, month_id, day_id, age, sex_id, parent_id, adm2_id_event, adm2_id_res, icd10, birth_date)]
  write.csv(dt, paste0(outpath, "cod_", year, ".csv"), row.names = F)
}

########## 1996-2012 datasets cleaning ############################################
for (year in 1996:2012){
  bra.dir <- paste0(j, "DATA/BRA/MORTALITY_INFORMATION_SYSTEM_SIM/", year)
  files <- list.files(bra.dir, full.names = T)
  files <- grep("DTA", files, value = T)
  dt <- lapply(files, stata_dt) %>% rbindlist(fill = T)
  
  #subset to the vars of interest
  dt <- dt[, .(dtobito, sexo, codmunocor, codmunres, causabas, dtnasc)]
  setnames(dt, c("dtobito", "dtnasc", "sexo", "codmunocor", "codmunres", "causabas"), 
           c("death_date", "birth_date", "sex_id", "adm2_id_event", "adm2_id_res", "icd10"))
  
  #standardize adm2 code (code is 7 numbers instead of 6 in these data for some reason...)
  dt[,adm2_id_event := substr(adm2_id_event, 1,6)]
  dt[,adm2_id_res := substr(adm2_id_res, 1,6)]
  
  #set date of death and date of birth
  dt[, date := as.Date(as.character(death_date), "%e%m%Y")]
  dt[, year_id := substr(date, 1, 4)]
  dt[, month_id := substr(date, 6,7)]
  dt[, day_id := substr(date, 9,10)]
  dt[, birth_date := as.Date(as.character(birth_date), "%e%m%Y")]
  #ifelse(year < 2001, dt[, birth_date := as.Date(as.character(birth_date), "%e%m%Y")], dt[, birth_date := as.Date(as.character(birth_date), "%e%m%Y")])
  dt[, age := as.numeric(date - birth_date)]
  dt[, age := age/365.25]
  dt[, parent_id := 135]
      
  # clean and save
  dt <- dt[, .(year_id, month_id, day_id, age, sex_id, parent_id, adm2_id_event, adm2_id_res, icd10, birth_date)]
  print(paste0("saving COD-", year))
  write.csv(dt, paste0(outpath, "cod_", year, ".csv"), row.names = F)
}