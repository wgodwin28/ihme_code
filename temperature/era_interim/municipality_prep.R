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
iso <- "nza" #bra or mex or us or nza
proj <- "era_interim"
data.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/mean/', proj, '/')
out.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/', iso,'/', proj, '/')
shapefile.dir = paste0(j, "temp/wgodwin/temperature/shapes/", iso, "/")
map.dir = paste0(j,'temp/wgodwin/temperature/exposure/diagnostics/')
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/total/1y/")

#source locations function
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
locations <- get_location_metadata(location_set_id=22)
locations <- locations[, .(location_id, region_name, super_region_name)]

########Read in shapefile and extract##########
if(iso == "bra"){borders <- readOGR(paste0(shapefile.dir, "municipios_2010.shp"))}
if(iso == "mex"){borders <- readOGR(paste0(j, "temp/Jeff/temperature/shapefiles/mex/GIS Mexican Municipalities/Mexican Municipalities.shp"))}
if(iso == "us"){borders <- readOGR(paste0(shapefile.dir, "cb_2016_us_county_500k.shp"))}
if(iso == "nza"){borders <- readOGR(paste0(shapefile.dir, "nz-district-health-boards-2013.shp"))}

#Loop through years
for(year in seq(1989, 2015)){
  #read in file and crop to borders of specified country
  brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
  brik <- rotate(brik) # b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
  brik <- crop(brik, borders)

  ##extract temperatures to the municipality
  print(paste0("extracting ", year))
  ugh <- extract(brik, borders, fun=mean, na.rm = T) %>% as.data.table
  
  ##add on important metadata- muni codes
  if(iso == "bra"){bord <- cbind(as.numeric(as.character(borders@data$codigo_ibg)), as.character(borders@data$nome)) %>% as.data.table}
  if(iso == "bra"){bord[, V1 := substr(V1, 0,6)]}
  if(iso == "mex"){bord <- cbind(as.character(borders@data$IDUNICO), as.character(borders@data$NOM_MUN)) %>% as.data.table}
  if(iso == "us"){bord <- cbind(as.numeric(as.character(borders@data$GEOID)), as.character(borders@data$NAME)) %>% as.data.table}
  if(iso == "nza"){bord <- cbind(as.numeric(as.character(borders@data$DHB12)), as.character(borders@data$NAME)) %>% as.data.table}
  setnames(bord, c("V1", "V2"), c("adm2_code", "adm2_name"))
  ugh <- cbind(ugh, bord)
  
  ##melt down by day and covert to celsius
  dt <- melt(ugh, id = c("adm2_code", "adm2_name"))
  dt[, day := substring(as.character(variable), 2, 7)]
  setnames(dt, "value", "temperature")
  dt[, temperature := temperature - 273.15]
  dt[, year_id := year]
  dt <- dt[, adm2_code := as.numeric(adm2_code)]
  dt[, date := paste(day, year_id, sep = "/")]
  dt[, date := as.Date(date, "%j/%Y")]
  
  #clean and save
  dt <- dt[, .(adm2_code, temperature, date, year_id)]
  write.csv(dt, paste0(out.dir, "municipality_temp_", year, ".csv"), row.names = F)
  print(paste0("saved ", year))

}
#u <- fread("/home/j/LIMITED_USE/PROJECT_FOLDERS/USA/NVSS_MORTALITY/us_counties/parsed_microdata/cleaned/data_1990_cleaned.csv")
