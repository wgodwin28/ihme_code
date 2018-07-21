#Purpose: Prep temperature data at the Mexico or Brazil municipality level for link up with COD data
#Output should have average daily temperature by admin 2 level for each day, saved by year
#source('/snfs2/HOME/wgodwin/temperature/era_interim/municipality_prep_erac.R', echo = T)
rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

#load libraries
# for(ppp in c('parallel', 'rgdal', 'sp', 'raster','ncdf4','data.table', 'ggplot2')){
#   library(ppp, lib.loc = pack_lib, character.only =T)
# }

#install pacman library
#if("pacman" %in% rownames(installed.packages())==FALSE){
#  library(pacman,lib.loc="/homes/wgodwin/R/x86_64-pc-linux-gnu-library/3.3")
#}

# load packages, install if missing  
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
pacman::p_load(data.table, fst, ggplot2, parallel, magrittr, maptools, raster, rgdal, rgeos, sp, splines, stringr, RMySQL, snow, ncdf4)

## set filepath objects
iso <- "mex" #bra or mex or us or nza or gtm
max.cores <- 6 #CHANGE
proj <- "era_interim"
data.dir = paste0(j,'WORK/05_risk/risks/temperature/data/exp/prepped/mean/', proj, '/')
out.dir = paste0(j,'WORK/05_risk/risks/temperature/data/exp/prepped/', iso,'/', proj, '/')
shapefile.dir = paste0(j, "WORK/05_risk/risks/temperature/data/exp/shapes/", iso, "/", iso)
map.dir = paste0(j,'WORK/05_risk/risks/temperature/diagnostics/')
pop.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/", iso, "/all_age/")
code.dir = paste0('/snfs2/HOME/wgodwin/temperature/')

#source locations function
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
#locations <- get_location_metadata(location_set_id=22)
#locations <- locations[, .(location_id, region_name, super_region_name)]
source(paste0(code.dir, 'functions/era_functions.R'))

########Read in shapefile and extract##########
#if(iso == "us"){borders <- readOGR(paste0(shapefile.dir, "cb_2016_us_county_500k.shp"))}
borders <- readOGR(paste0(shapefile.dir, "_admin2.shp"))

#Loop through years
for(year in c(2017)){
  #read in file and crop to borders of specified country
  brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
  brik <- rotate(brik) # b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
  brik <- crop(brik, borders)
  
  
  #NEED TO PULL IN POPS AND EXTRACT IN ORDER TO POP WEIGHT
  
  ##extract temperatures to the municipality
  print(paste0("extracting ", year))
  #ugh <- extract(brik, borders, fun=mean, na.rm = T) %>% as.data.table
  ugh <- extract(brik, coordinates(borders), fun = mean, na.rm = T, method='bilinear')
  
  ##add on important metadata- muni codes
  bord <- cbind(as.numeric(as.character(borders@data$adm2_code)), as.character(borders@data$adm2_name)) %>% as.data.table
  #if(iso == "us"){bord <- cbind(as.numeric(as.character(borders@data$GEOID)), as.character(borders@data$NAME)) %>% as.data.table}
  setnames(bord, c("V1", "V2"), c("adm2_id", "adm2_name"))
  ugh <- cbind(ugh, bord)
  
  ##melt down by day
  dt <- melt(ugh, id = c("adm2_id", "adm2_name"))
  dt[, day := substring(as.character(variable), 2, 7)]
  setnames(dt, "value", "temperature")
  
  #Extract for tiny municipalities that didn't extract correctly
  missing.munis <- dt[is.na(temperature), unique(adm2_id)]
  missing.countries.vals <- mclapply(missing.munis,
                                     estimateIslands,
                                     borders=borders,
                                     ras=brik,
                                     mc.cores=max.cores)
  missing.dt <- rbindlist(missing.countries.vals)
  
  #Bind together missing temp munis with bigger ones and covert to celsius
  dt <- dt[!is.na(temperature),]
  dt <- dt[, lapply(.SD, mean, na.rm = T), .SDcols = "temperature", by = c("adm2_id", "adm2_name", "day")]
  dt <- rbind(dt, missing.dt, fill = T)
  dt[, temperature := temperature - 273.15]
  dt[, year_id := year]
  dt[, date := paste(day, year_id, sep = "/")]
  dt[, date := as.Date(date, "%j/%Y")]
  if(iso == "bra"){dt[, adm2_id := substr(adm2_id, 0,6)]}
  dt[, adm2_id := as.numeric(adm2_id)]
  
  #Merge on pops
  #pop <- fread(paste0(pop.dir, "pop_full.csv"))
  #pop[, adm2_id := as.numeric(adm2_id)]
  #dt <- merge(dt, pop[, .(adm2_id, year_id, population)], by = c("adm2_id", "year_id"), all.x = T)
  
  #clean and save
  #dt <- dt[, .(adm2_id, temperature, date, year_id, population)]
  dt <- dt[, .(adm2_id, temperature, date, year_id)]
  write.csv(dt, paste0(out.dir, "municipality_temp_", year, ".csv"), row.names = F)
  print(paste0("saved ", year))

}
#end#


## combine all years and calculate all years mean for all admin 2s from 1990-2017
iso <- "nza"
out.dir <- paste0(j,'WORK/05_risk/risks/temperature/data/exp/prepped/', iso,'/', proj, '/')
all.dt <- data.table(year_id = as.numeric(), adm2_id = as.numeric(), temperature = as.numeric())
dir.create(paste0(out.dir, "annual"))
for(year in 1990:2017){
  temp.dt <- fread(paste0(out.dir, "municipality_temp_", year, ".csv"))
  temp.dt <- temp.dt[, lapply(.SD, mean), .SDcols = "temperature", by = c("year_id", "adm2_id")]
  all.dt <- rbind(all.dt, temp.dt)
  print(year)
}
all.dt <- all.dt[, lapply(.SD, mean), .SDcols = "temperature", by = c("adm2_id")]
write.csv(all.dt, paste0(out.dir, "/annual/all_years.csv"), row.names = F)
#u <- fread("/home/j/LIMITED_USE/PROJECT_FOLDERS/USA/NVSS_MORTALITY/us_counties/parsed_microdata/cleaned/data_1990_cleaned.csv")


out.dir <- paste0(j,'WORK/05_risk/risks/temperature/data/exp/prepped/mex/era_interim')

dt <- fread(paste0(j,'WORK/05_risk/risks/temperature/data/exp/prepped/bra/era_interim/municipality_temp_1989.csv'))
files <- list.files(path = out.dir, pattern = ".csv", full.names = T)
dt <- rbindlist(lapply(files, fread), fill = T)
dt[, date := as.Date(date)]
lag_coords_30 <- function(i, data){
  d <- data[adm2_id == i,]
  d[, mmt := sapply(1:nrow(d), mean_lag_30, data = d)]
  return(d)
}

start_time <- Sys.time()
adm2s <- unique(dt$adm2_id)
dt <- mclapply(adm2s, lag_coords_30, data = dt, mc.cores = 15) %>% rbindlist
end_time <- Sys.time()
end_time - start_time

dt[, mean_ann := mclapply(.SD, mean, na.rm = T, mc.cores = 15), .SDcols = "temperature", by = c("adm2_id")]
dt[, mmt_tmrel := 35.81728 * exp(-exp(-0.0630098 * (mean_ann - 4.76978)))]
dt[, mmt_dif := mmt - mmt_tmrel]
quantile(dt$mmt_dif, probs=c(.01,.05,.1,.25,.5,.75,.9,.95,.99), na.rm = T)


mean_lag_30 <- function(i, data) {
  is.near <- as.numeric(data$date[i] - data$date) >= 0 & as.numeric(data$date[i] - data$date) < 30
  mean(data$temperature[is.near], na.rm = T)
} 
