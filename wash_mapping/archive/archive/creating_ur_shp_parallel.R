# Set library and load packages
root <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
package_lib <- paste0(root,'/temp/geospatial/packages')
.libPaths(package_lib)
package_list <- c('sp','rgdal','rgeos','dplyr')
for(package in package_list) {
  library(package, lib.loc = package_lib, character.only=TRUE)
}

# Load in args from qsub command
index <- commandArgs()[3]

# Define objects for loop
time_band <- c(2000,2005,2010,2015)
setwd('/home/j//WORK/11_geospatial/05_survey shapefile library/Shapefile directory')
svy_shp <- list.files(pattern = "*.shp")
svy_shp <- sub(".shp.xml", ".xml", svy_shp)
svy_shp <- svy_shp[grep(".shp",svy_shp)]
svy_shp2 <- sub(".shp","",svy_shp)

# Create survey shapefile for each time period intersected with ur_pop raster
for (i in 1:4) {
  ur_pop <- raster(paste0("/home/j//WORK/11_geospatial/wash/urban_pop_rasters/","urban_pop_",time_band[i],".tif"))
  adm0_sen <- shapefile(svy_shp[index])
  sen_test <- mask(crop(x = ur_pop, y = adm0_sen), adm0_sen)
  sen_test_poly <- rasterToPolygons(sen_test, n = 16, dissolve = T)
  adm1_sen <- adm0_sen

  test <- raster::intersect(adm1_sen, sen_test_poly)
  test2 <- raster::union(adm1_sen, test)
  test2@data$layer[which(is.na(test2@data$layer))] <- 0
  test2@data$layer[which(test2@data$layer == 0)] <- "no_pop"
  test2@data$layer[which(test2@data$layer == 1)] <- "rural"
  test2@data$layer[which(test2@data$layer == 2)] <- "urban"

  writeOGR(test2, dsn = paste0('/home/j//WORK/11_geospatial/05_survey shapefile library/shapefile_urban/',
                             time_band[i]), layer = svy_shp2[index], driver = "ESRI Shapefile")
}
