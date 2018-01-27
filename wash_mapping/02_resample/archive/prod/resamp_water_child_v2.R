# Set library and load packages
root <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
package_list <- c('dplyr','raster', 'tiff', 'seegSDM','seegMBG')
if(Sys.info()[1]=="Windows") {
  for(package in package_list) {
    library(package, character.only = T)
  }
} else {
  package_lib <- paste0(root,'temp/geospatial/packages') 
  .libPaths(package_lib)     
  for(package in package_list) {
    library(package, lib.loc = package_lib, character.only=TRUE)
  }
}

shp <- commandArgs()[3]
indic <- commandArgs()[4]

polydat <- read.csv('/home/j/WORK/11_geospatial/wash/data/agg/water_poly_agg_2017-07-11.csv')
subset <- polydat[which(polydat$shapefile == shp),]
#### READ IN THE WORLDPOP RASTER AND CROP IT TO SHAPEFILE ####
shape_master <- shapefile(paste0('/home/j//WORK/11_geospatial/05_survey shapefile library/Shapefile directory/',shp,'.shp'))

generated_pts <- list()
for (loc in unique(subset$location_code)) {
  shape <- shape_master[shape_master$GAUL_CODE == loc,]
  polydat_loc <- filter(polydat, location_code == loc)
  
  for (pid in unique(subset_loc$id_short)) {
    polydat_loc2 <- filter(subset_loc, id_short == pid)
    
    year <- subset_loc2$year_start
    if (year <= 2000) {
      pop_raster <- raster('/snfs1/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPop_total_global_stack.tif', band = 1)
    } else {
      if (year > 2000 & year <= 2005) {
        pop_raster <- raster('/snfs1/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPop_total_global_stack.tif', band = 2)
        } else {
                if (year > 2005 & year <= 2010) {
                  pop_raster <- raster('/snfs1/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPop_total_global_stack.tif', band = 3)
                  } else {
                          pop_raster <- raster('/snfs1/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPop_total_global_stack.tif', band = 4)
                    }
      } 
    } 
    
    raster_crop <- mask(crop(x = pop_raster, y = shape), shape)
    
    prop <- unique(polydat_loc2[,indic])
    samp_pts <- getPoints(shape = shape, raster = raster_crop, n = 0.001, perpixel = T)
    polydat_loc2 <- as.data.frame(samp_pts)
    names(polydat_loc2) <- c("long", "lat","weight")
    # if (n_pts < 5) {polydat_loc2$weight <- 0.2}
    
    polydat_loc2$prop <- prop
    polydat_loc2$N <- polydat_loc2$total_hh
    polydat_loc2$year <- polydat_loc2$year_start
    polydat_loc2 <- mutate(polydat_loc2, water_bin = round(prop * N))
    polydat_loc2$country <- subset_loc2$iso3
    polydat_loc2$cluster_id <- id_short
    polydat_loc2 <- dplyr::select(polydat_loc2, country, year, prop, N, water_bin, lat,
                               long, cluster_id, weight)
    polydat_loc2$point <- 0
    generated_pts[[length(generated_pts) + 1]] <- polydat_loc2
  }
  
}
generated_pts2 <- do.call(rbind, generated_pts)

write.csv(generated_pts2, file = paste0("/home/j//WORK/11_geospatial/wash/resampling/water/", indic,"/poly_df/", shp, "_", Sys.Date(),".csv"))