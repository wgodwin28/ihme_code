library(sp)
library(rgdal)
library(raster)
library(rgeos)
library(dplyr)
library(tmap)

# Process and Create Rasters

urban <- raster('J:/WORK/11_geospatial/01_covariates/09_MBG_covariates/GHS_settlement_model_stack.tif')
pop <-  raster('J:/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPoP_total_global_stack.tif')

rural <- calc(urban, function(x) {ifelse(x == 0, 1, ifelse(x == 1, 0, NA))})
urban2 <- calc(urban, function(x) {ifelse(x == 1, 2, ifelse(x == 0, 0, NA))})

rural_pop <- rural*pop
rural_pop2 <- calc(rural_pop, function(x) {ifelse(x > 0, 1, ifelse(x == 0, 0, NA))})

ur_pop <- urban2 + rural_pop2

# Polygon processing with toy senegal example
setwd('J:/WORK/11_geospatial/06_original shapefiles/GAUL_admin/admin0/g2015_2014_0')
adm0 <- readOGR(layer = "g2015_2014_0", stringsAsFactors = F, dsn = '.')

setwd('J:/WORK/11_geospatial/06_original shapefiles/GAUL_admin/admin1/g2015_2014_1')
adm1 <- readOGR(layer = "g2015_2014_1", stringsAsFactors = F, dsn = '.')

cntry_list <- read.csv("C:/Users/adesh/Documents/WASH/dhs_mics_countries.csv", stringsAsFactors = F)

sampling_frame <- list()
for (i in cntry_list$Gaul) {
  message(paste("Processing", adm0@data$ADM0_NAME[which(adm0@data$ADM0_CODE == i)]))
  
  print("Subsetting AD0")
  adm0_sen <- adm0[adm0$ADM0_CODE == i,]
  
  print("Cropping Raster to Country")
  sen_test <- mask(crop(x = ur_pop, y = adm0_sen), adm0_sen)
  
  print("Converting Raster to Polygons")
  sen_test_poly <- rasterToPolygons(sen_test, n = 16, dissolve = T)
  
  print("Subsetting AD1")
  adm1_sen <- adm1[adm1$ADM0_CODE == i,]
  
  print("Merging Geographies")
  test <- raster::intersect(adm1_sen, sen_test_poly)
  test2 <- raster::union(adm1_sen, test)
  test2@data$layer[which(is.na(test2@data$layer))] <- 0
  test2@data$layer[which(test2@data$layer == 0)] <- "no_pop"
  test2@data$layer[which(test2@data$layer == 1)] <- "rural"
  test2@data$layer[which(test2@data$layer == 2)] <- "urban"
  test3 <- aggregate(test2, by = c("layer",'ADM1_CODE.1','ADM1_NAME.1','ADM0_CODE.1','ADM0_NAME.1'), dissolve = T)
  
  test3 <- spChFIDs(test3, paste(adm0@data$ADM0_NAME[which(adm0@data$ADM0_CODE == i)], row.names(test3), sep="."))
  
  print("Saving to List")
  sampling_frame[[length(sampling_frame)+1]] <- test3
  
}

test4 <- do.call(rbind, sampling_frame)
qtm(test4, fill = "layer")

save(test4, file = "C:/Users/adesh/Documents/WASH/ad1_ur_pop_shp.RData")

