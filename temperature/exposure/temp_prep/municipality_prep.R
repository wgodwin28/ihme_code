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
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/total/1y/")
code.dir = paste0('/snfs2/HOME/wgodwin/temperature/')

#source locations function
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
#locations <- get_location_metadata(location_set_id=22)
#locations <- locations[, .(location_id, region_name, super_region_name)]
source(paste0(code.dir, 'functions/era_functions.R'))

########Read in shapefile and extract##########
borders <- readOGR(paste0(shapefile.dir, "_admin2.shp"))

#create fake raster with dimensions of temp raster
b <- raster()
extent(b) <- extent(borders)
res(b) <- .5

#Loop through years
for(year in c(2017)){
  #read in file and crop to borders of specified country
  brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
  brik <- rotate(brik) # b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
  brik <- crop(brik, borders)
  
  #NEED TO PULL IN POPS AND EXTRACT IN ORDER TO POP WEIGHT
  #Read in and crop pop
  pop <- raster(paste0(pop.dir, 'worldpop_total_1y_',year,'_00_00', '.tif'))
  pop <- crop(pop, borders)
  pop <- resample(pop, b, method = "bilinear")
  
  #multiply temp times pop and resample to .05 x .05 resolution
  pop <- resample(pop, brik, method = "ngb")
  brik <- brik * pop
  
  ##extract weighted temperature and pop to the municipality
  print(paste0("extracting ", year))
  #ugh <- extract(brik, borders, fun=mean, na.rm = T) %>% as.data.table
  ugh <- extract(brik, coordinates(borders), fun = sum, na.rm = T, method='bilinear')
  pop <- extract(pop, coordinates(borders), fun = sum, na.rm = T, method='bilinear')
  
  ##add on important metadata- muni codes
  bord <- cbind(as.numeric(as.character(borders@data$adm2_code)), as.character(borders@data$adm2_name)) %>% as.data.table
  setnames(bord, c("V1", "V2"), c("adm2_id", "adm2_name"))
  ugh <- cbind(ugh, bord)
  pop <- cbind(pop, bord)
  
  ##melt down by day
  dt <- melt(ugh, id = c("adm2_id", "adm2_name"))
  
  #merge on pops by admin2 and divide by them to finish pop weighting
  dt <- merge(dt, pop, by = c("adm2_id", "adm2_name"))
  dt[, temperature := value / pop]
  dt[, day := substring(as.character(variable), 7, 9)]

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
