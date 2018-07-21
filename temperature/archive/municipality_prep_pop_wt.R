#Purpose: Prep temperature data at the Mexico or Brazil municipality level for link up with COD data
rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

#load libraries
# pack_lib = '/snfs2/HOME/wgodwin/R'
# .libPaths(pack_lib)
# for(ppp in c('parallel', 'rgdal', 'sp', 'raster','ncdf4','data.table', 'ggplot2')){
#   library(ppp, lib.loc = pack_lib, character.only =T)
# }

#install pacman library
if("pacman" %in% rownames(installed.packages())==FALSE){
  library(pacman,lib.loc="/homes/wgodwin/R/x86_64-pc-linux-gnu-library/3.3")
}

# load packages, install if missing  
pacman::p_load(data.table, fst, ggplot2, parallel, magrittr, maptools, raster, rgdal, rgeos, sp, splines, stringr, RMySQL, snow, ncdf4)

## set filepath objects and source locations function
iso <- "mex" #bra or mex
proj <- "era_interim"
data.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/mean/', proj, '/')
out.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/era_nat/', proj, '/')
shapefile.dir = paste0(j, "temp/Jeff/temperature/shapefiles/")
map.dir = paste0(j,'temp/wgodwin/temperature/exposure/diagnostics/')
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/total/1y/")
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
locations <- get_location_metadata(location_set_id=22)
locations <- locations[, .(location_id, region_name, super_region_name)]

########Read in shapefile and extract##########
if(iso == "bra"){borders <- readOGR(paste0(shapefile.dir, "brazilAdmin2.shp"))}
if(iso == "mex"){borders <- readOGR(paste0(shapefile.dir, "/mex/GIS Mexican Municipalities/Mexican Municipalities.shp"))}

#Loop through years
for(year in seq(1900, 1909)){

  ##Read in temp data
  brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
  brik <- rotate(brik) # b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
  brik <- crop(brik, borders)
  
  #Read in and crop pop
  pop <- raster(paste0(pop.dir, 'worldpop_total_1y_',year,'_00_00', '.tif'))
  pop <- crop(pop, borders)
  
  #polygonize the temperature raster grid
  #I'm not totally sure how this scales
  temp_grid = brik[[1]]
  temp_grid[] = 1:length(temp_grid)
  temp_grid = rasterToPolygons(temp_grid)
  
  #calculate the population at each cell of the temperature grid
  temp_pop = extract(pop, temp_grid, fun = sum)
  
  #convert back to raster
  pop_grid = brik[[1]]
  pop_grid[] = temp_pop
  
  #pop weight temperature values
  brik <- brik * pop_grid

  #extract temperature and population values up to the municipality level
  muni_temp = as.data.table(extract(brik, borders, fun = sum, na.rm = T))
  muni_temp2 <- cbind(muni_temp,borders@data$ADM2_CODE, borders@data$ADM2_NAME)
  dt.temp <- melt(muni_temp2, id = c("V2", "V3"), variable.name = "day")

  
  muni_pop = extract(pop, borders, fun = sum, na.rm = T)
  dt.pop <- cbind(muni_pop,borders@data$ADM2_CODE, borders@data$ADM2_NAME) %>% as.data.table
  dt <- merge(dt.temp, dt.pop, by = "location_id")
  dt[, temperature := value/V1]
  
  
  ###########New downsampling way################
  pop <- as.data.frame(pop, xy=T) %>% as.data.table
  pop[is.na(worldpop_total_1y_2015_00_00), worldpop_total_1y_2015_00_00 := 0] ## try to replace NAs with 0

  sub.pop <- SpatialPointsDataFrame(pop[, c("x", "y")], pop)
  temp <- extract(brik, sub.pop) %>% as.data.table
  temp2 <- cbind(temp, pop)
  spatial <- temp2[, c("x", "y", paste0("X", 1:365)), with = F]
  
  coordinates(spatial) <- ~x+y
  crs(spatial) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
  test <- over(spatial, borders)
  dt <- cbind(test, temp2) %>% as.data.table
  
  #Melt and multiply temp by populations
  dt <- dt[, c("x", "y", "IDUNICO", paste0("X", 1:365), "worldpop_total_1y_2015_00_00"), with = F]
  dt.temp <- melt(dt, id = c("x", "y", "IDUNICO", "worldpop_total_1y_2015_00_00"), variable.name = "day")
  dt.temp[, day := substring(as.character(day), 2, 6)]
  dt.temp[, temp.weighted := value * worldpop_total_1y_2015_00_00]
  
  #Agg up to the municipality by populations and temperature-weighted
  dt.temp2 <- dt.temp[, lapply(.SD, sum, na.rm = T), by = .(IDUNICO, day), .SDcols = c("worldpop_total_1y_2015_00_00", "temp.weighted")]
  dt.temp2[, temperature := temp.weighted/worldpop_total_1y_2015_00_00]
  
  
  
  ### Trouble shooting- Covert points to raster
  points <- temp2[, .(X1, x , y)]
  setcolorder(points, c("x", "y", "X1"))
  r <- rasterFromXYZ(points)
  missings <- points[is.na(X1), X1 := 1]
  missings <- missings[X1 > 2, X1 := NA]
  na.r <- rasterFromXYZ(missings)
  
  
  
  
  
  
  
  
  #melt to long format and generate more interpretable day variable
  dt.temp <- melt(temp, id = c("location_name", "location_id"))
  dt.temp[, day := substring(as.character(variable), 10, 16)]
  dt.temp <- dt.temp[,.(location_name, location_id, day, value)]
  dt.temp <- dt.temp[, lapply(.SD, sum), by = .(location_name, location_id, day), .SDcols = c("value")]
  
  #melt to long format and generate more interpretable day variable
  dt.pop <- copy(temp)
  dt.pop <- dt.pop[, lapply(.SD, sum), by = .(location_name, location_id)]
  dt.pop <- dt.pop[, .(location_id, id)]
  
  #merge on cumulative pops with cumulative temps
  dt <- merge(dt.temp, dt.pop, by = "location_id")
  dt[, temperature := value/id]

  #Clean and save
}

### old scrap
## For jeff
# brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
# brik <- rotate(brik) # b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
# brik <- crop(brik, borders)
# print(paste0("extracting ", year))
# ugh <- extract(brik, borders, fun=mean, na.rm = T) %>% as.data.table
# bord <- cbind(borders@data$IDUNICO, borders@data$NOM_MUN) %>% as.data.table
# setnames(bord, c("V1", "V2"), c("adm2_code", "adm2_name"))
# ugh2 <- cbind(ugh, bord)
# dt <- melt(ugh2, id = c("adm2_code", "adm2_name"))
# dt[, day := substring(as.character(variable), 2, 7)]
# setnames(dt, "value", "temperature")
# dt[, temperature := temperature - 273.15]
# dt[, year_id := year]
# write.csv(dt, paste0("/home/j/temp/wgodwin/temperature/exposure/prepped_data/mex/municipality_temp_", year, ".csv"), row.names = F)
# print(paste0("saved ", year))
# 
# 
# for(year in seq(1992, 2016)){
#   pop <- raster(paste0(pop.dir, 'worldpop_total_1y_',year,'_00_00', '.tif'))
#   pop <- crop(pop, borders)
#   dt <- extract(pop, borders, fun = sum)
#   dt <- cbind(dt, borders@data$IDUNICO) %>% as.data.table
#   setnames(dt, c("V1", "V2"), c("population", "adm2_code"))
#   coll <- fread(paste0("/home/j/temp/wgodwin/temperature/exposure/prepped_data/mex/archive/municipality_temp_", year, ".csv"))
#   final <- merge(coll, dt, by = "adm2_code")
#   final <- final[, .(adm2_code, temperature, day, population, year_id)]
#   write.csv(final, paste0("/home/j/temp/wgodwin/temperature/exposure/prepped_data/mex/muni_temp_", year, ".csv"), row.names = F)
# }
