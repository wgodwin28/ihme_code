#Prep exposure and populations for PAF calculation
rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}
options(scipen=999)

#load libraries
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
pacman::p_load(data.table, parallel, magrittr, raster, stringr, RMySQL, snow, ncdf4, feather,rgdal)
data.dir <- paste0(j,'WORK/05_risk/risks/temperature/data/exp/prepped/mean/era_interim/')
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/total/1y/")
out.dir <- paste0("/share/epi/risk/temp/temperature/exp/gridded/")
max.cores <- 6

#Get locations and the global shapefile
source(paste0(j,'temp/central_comp/libraries/current/r/get_location_metadata.R'))
loc_ids <- get_location_metadata(location_set_id=22)[most_detailed == 1, location_id]
borders <- readOGR(paste0(j,"DATA/SHAPE_FILES/GBD_geographies/master/GBD_2017/master/shapefiles"), layer ="GBD2017_analysis_final")
source(paste0('/snfs2/HOME/wgodwin/temperature/functions/era_functions.R'))
pop <- F

#begin loop
for(year in c(1994, 1995, 1999, 2000, 2009, 2010)){
  #read in file and crop to borders of specified country
  brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
  brik <- rotate(brik) # b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
  brik <- crop(brik, borders)
  data <- as.data.table(rasterToPoints(brik[[1]]))
  setnames(data, c("x","y"), c("long", "lat"))
  data[, id := .GRP, by = c('lat', 'long')]
  
  #Convert to raster
  d <- data[, .(lat, long, id)]
  coordinates(d) = ~long+lat
  proj4string(d)=CRS("+init=epsg:4326")
  #proj4string(d)=CRS("+ellps=WGS84")
  gridded(d) = TRUE
  
  #Extract temperature pixels to find the location_id of each pixel
  d <- raster(d[, c("id")])
  raster.ids <- extract(d, borders, small = T)
  temp <- NULL
  missing <- c()
  for (iii in 1:length(raster.ids)) {
    if (!is.null(raster.ids[[iii]])) {
      
      temp <- rbind(temp, data.frame(location_id=borders$loc_id[iii],
                                     location_name=borders$loc_nm_sh[iii],
                                     id=raster.ids[[iii]]))
    }else(missing <- c(missing, iii))
  }
  
  #Some are missing ids
  temp <- temp[!is.na(temp$id), ]

  #Some ids are in multiple countries. Create an indicator
  all.locs <- unique(as.numeric(borders$loc_id))
  good.locs <- unique(as.numeric(as.character(temp$location_id)))
  missing.locs <- setdiff(loc_ids, good.locs)

  #Convert raster brick with daily temp to data table
  points <- as.data.table(rasterToPoints(brik))
  points[, id := .GRP, by = c("x", "y")]
  #points[, c('x', 'y') := NULL]
  
  #Merge temp values with location_ids
  data <- merge(temp, points, by="id", all.x = T)
  setnames(data, c("x", "y"), c("long", "lat"))
  setDT(data)
  
  ##Extract for tiny municipalities that didn't extract correctly
  missing.countries.vals <- mclapply(missing.locs,
                                     estimateIslands2,
                                     borders=borders,
                                     ras=brik,
                                     mc.cores=max.cores)
  missing.dt <- rbindlist(missing.countries.vals)
  
  #Reshape long
  data <- melt(data, id = c("id", "location_id", "location_name", "long", "lat"))
  setnames(data, c("variable", "value"), c("day", "tmean"))
  data[, day := substring(as.character(day), 2, 7)]
  
  #Merge back on missing locs
  data <- data[location_id %in% good.locs]
  data <- rbind(data, missing.dt, fill= T)
  
  #Convert to celcius and clean day variable
  data[, tmean := tmean -273.15]
  data[, year_id := year]
  data[, date := paste(day, year_id, sep = "/")]
  data[, date := as.Date(date, "%j/%Y")]
  
  #Clean and save exposures ready for PAF calculation
  data[, c("id", "day", "year_id") := NULL]
  missing <- c()
  for (loc in loc_ids) {
    new <- data[location_id == loc]
    if(nrow(new[!is.na(long)])==0){
      missing <- c(missing, loc)
    }
    print(paste0("saving ", year, "-location ", loc)) 
    write_feather(new, paste0(out.dir, "loc_", loc, "_", year,".feather"))
  }
}
if(pop){
  #Run populations prep loop
  for(year in c(seq(1991,2004),2006, seq(2008,2016))){
    #Read in populations
    pop <- raster(paste0(pop.dir, 'worldpop_total_1y_',year,'_00_00', '.tif'))
    pop <- crop(pop, borders)
    
    #Prep appropriate temperature grip to resample from
    brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
    brik <- rotate(brik) # b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
    brik <- crop(brik, borders)
    
    #aggregate population to the exposure cell size
    pop_fact <- round(dim(pop)[1:2] / dim(brik)[1:2])
    pop <- aggregate(pop, pop_fact)
    pop <- resample(pop, brik[[1]])
    
    #Convert to data table and set variable names
    pop <- setDT(as.data.frame(pop, xy = T))
    setnames(pop, c("x", "y", paste0("worldpop_total_1y_", year, "_00_00")), c("long", "lat", "pop"))
    pop[is.na(pop), pop := 0]
    
    #Save in order for merging in paf caculation
    #SAVE AS FEATHER??
    out.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/paf/")
    print(year)
    write_feather(pop, paste0(out.dir, "gridded_pop_", year, ".feather"))
  }
}

#Look at mmt-tmrel
year <- 2017
brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
brik <- rotate(brik)# b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
brik <- brik - 273.15
m <- mean(brik)
m2 <- (35.81728 * exp((-1)*exp(-0.0630098 * (m - 4.76978))))

b <- calc(brik, function(x) movingFun(x, 30, mean, type = "to", na.rm = T))
