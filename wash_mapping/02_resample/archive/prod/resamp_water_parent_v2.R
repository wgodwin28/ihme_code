# Set library and load packages
root <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
package_lib <- paste0(root,'/temp/geospatial/packages')
.libPaths(package_lib)
package_list <- c('dplyr','raster', 'tiff', 'seegSDM','seegMBG')
for(package in package_list) {
  library(package, lib.loc = package_lib, character.only=TRUE)
}

shp <- commandArgs()[3]
indic <- commandArgs()[4]

load(paste0("/home/j//WORK/11_geospatial/wash/resampling/water/", indic,"/poly_df/water_poly_f.RData"))
#load(paste0("/home/j//WORK/11_geospatial/wash/resampling/water/", indic, "/hh_vector.RData"))
subset <- water_poly_f[which(shapefile == shp),]
#### READ IN THE WORLDPOP RASTER AND CROP IT TO SHAPEFILE ####
shape_master <- shapefile(paste0('/home/j//WORK/11_geospatial/05_survey shapefile library/Shapefile directory/',shp,'.shp'))

generated_pts <- list()
for (loc in unique(subset$location_code)) {
  shape <- shape_master[shape_master$GAUL_CODE == loc,]
  subset_loc <- filter(subset, location_code == loc)
  
  for (pid in unique(subset_loc$poly_id)) {
    subset_loc2 <- filter(subset_loc, poly_id == pid)
    
    year <- subset_loc2$year_start
    if (year <= 2000) {
      pop_raster <- raster('/snfs1/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPop_total_global_stack.tif', band = 1)}
    else if (year > 2000 & year <= 2005) {
      pop_raster <- raster('/snfs1/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPop_total_global_stack.tif', band = 2)}
    else if (year > 2005 & year <= 2010) {
      pop_raster <- raster('/snfs1/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPop_total_global_stack.tif', band = 3)}
    else if (year > 2010) {
      pop_raster <- raster('/snfs1/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPop_total_global_stack.tif', band = 4)}
    
    raster_crop <- mask(crop(x = pop_raster, y = shape), shape)
    n_pts <- subset_loc2$n_pts
    prop <- unique(subset_loc2$water)
    samp_pts <- getPoints(shape = shape, raster = raster_crop, n = n_pts, perpixel = F)
    samp_pts2 <- as.data.frame(samp_pts)
    names(samp_pts2) <- c("long", "lat","weight")
    if (n_pts < 5) {samp_pts2$weight <- 0.2}
    
    samp_pts2$prop <- prop
    samp_pts2$N <- subset_loc2$hh_total
    samp_pts2$year <- subset_loc2$year_start
    samp_pts2 <- mutate(samp_pts2, water_bin = floor(prop * N))
    samp_pts2$country <- subset_loc2$ihme_loc_id
    samp_pts2$cluster_id <- pid
    samp_pts2 <- dplyr::select(samp_pts2, country, year, prop, N, water_bin, lat,
                               long, cluster_id, weight)
    samp_pts2$point <- 0
    generated_pts[[length(generated_pts) + 1]] <- samp_pts2
  }
  
}
generated_pts2 <- do.call(rbind, generated_pts)

write.csv(generated_pts2, file = paste0("/home/j//WORK/11_geospatial/wash/resampling/water/", indic,"/poly_df/", shp, "_", Sys.Date(),".csv"))