#Purpose: Calculate the average age in each 5 year bin for each pixel, by sex
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

#source central functions
source(paste0(j, "temp/central_comp/libraries/current/r/get_ids.R"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_population.R"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_age_metadata.R"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
location_ids <- get_location_metadata(location_set_id=22)[most_detailed == 1,location_id]
#location_ids <- get_location_metadata(location_set_id=22)[level == 3,location_id]

#Set toggles
start <- 1980
end <- 2017
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/total/1y/")
lights.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/dmspntl/mean/1y/")
shapefile.dir <- paste0(j, "DATA/SHAPE_FILES/GBD_geographies/master/GBD_2017/master/shapefiles/")
cov.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/", iso, "/")
dir.create(cov.dir)

#Get the appropriate 1y populations
ages <- seq(49,147)
age.mid <- seq(.5, 98.5)
ages.temp <- data.table(age_group_id = ages,
                        age_midpoint = age.mid)
pops <- get_population(location_id = location_ids, year_id = 1980:2017, sex_id = c(1,2), single_year_age = T, age_group_id = ages)
pops <- merge(pops, ages.temp, by = "age_group_id")

#Add in age_group_id bins
pops[age_group_id < 54, age_bin := 236]
pops[age_group_id >= 54 & age_group_id < 59, age_bin := 6]
pops[age_group_id >= 59 & age_group_id < 64, age_bin := 7]
pops[age_group_id >= 64 & age_group_id < 69, age_bin := 8]
pops[age_group_id >= 69 & age_group_id < 74, age_bin := 9]
pops[age_group_id >= 74 & age_group_id < 79, age_bin := 10]
pops[age_group_id >= 79 & age_group_id < 84, age_bin := 11]
pops[age_group_id >= 84 & age_group_id < 89, age_bin := 12]
pops[age_group_id >= 89 & age_group_id < 94, age_bin := 13]
pops[age_group_id >= 94 & age_group_id < 99, age_bin := 14]
pops[age_group_id >= 99 & age_group_id < 104, age_bin := 15]
pops[age_group_id >= 104 & age_group_id < 109, age_bin := 16]
pops[age_group_id >= 109 & age_group_id < 114, age_bin := 17]
pops[age_group_id >= 114, age_bin := 154]

#Sum population across 5 year age bins
pops[, pop_bin := lapply(.SD, sum), .SDcols = "population", by = c("year_id", "location_id", "sex_id", "age_bin")]

#Calculate average age in each 5 year age bin by pop weighting the ages by multiplying age*population/total population by age bin
pops[, wt_age_avg := (age_midpoint * population)/pop_bin]
pops <- pops[, lapply(.SD, sum), .SDcols = "wt_age_avg", by = c("year_id", "location_id", "sex_id", "age_bin")]

#clean
setnames(pops, "age_bin", "age_group_id")

#read in GBD shapefile
globe <- readOGR(shapefile.dir, "GBD2017_analysis_final")
names(globe)[1] <- "location_id"
globe@data$location_id <- as.integer(globe@data$location_id)

#age template to match the way age groups are saved in population rasters
template <- data.table(age_string = c("0004", "0509", "1014", "1519",
                                      "2024", "2529", "3034", "3539",
                                      "4044", "4549", "5054", "5559",
                                      "6064", "65pl"),
                       age_group_id = c("236", "6", "7", "8", "9", 
                                        "10", "11", "12", "13", "14", 
                                        "15", "16", "17", "154"))
#loop through year_id, location_id
locations <- unique(pops$location_id)
years <- unique(pops$year_id)
for(year in years){
  for(sex in c(1,2)){
    for (age in ages) {
    #Merge on GBD shapefile to convert data table into polygon
    temp <- pops[year_id == year & sex_id == sex & age_group_id == age]
    shape.pop <- sp::merge(globe, temp, by = "location_id", all.y = T)
    
    
    #read in raster of population by pixel
    s <- ifelse(sex == 1, "m", "f")
    a <- template[age_group_id == age, age_string]
    pop.temp <- raster(paste0(pop.dir, "a", a, s, "/1y/worldpop_a", a, s,"_1y_", year, "_00_00.tif"))
    
    #Convert polygon to raster
    extent(pop.temp) <- extent(shape.pop)
    pop.ras <- rasterize(shape.pop, pop.temp, "wt_age_avg")
    
    }
  }
}