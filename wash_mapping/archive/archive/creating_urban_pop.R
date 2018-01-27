library(sp)
library(rgdal)
library(raster)
library(rgeos)
library(dplyr)
library(tmap)

# Process and Create Rasters for Urban x WorldPop
time_band <- c(2000,2005,2010,2015)
for (i in 1:4) {
urban <- raster('J:/WORK/11_geospatial/01_covariates/09_MBG_covariates/GHS_settlement_model_stack.tif', band = i)
pop <-  raster('J:/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPoP_total_global_stack.tif',
               band = i)

rural <- calc(urban, function(x) {ifelse(x == 0, 1, ifelse(x == 1, 0, NA))})
urban2 <- calc(urban, function(x) {ifelse(x == 1, 2, ifelse(x == 0, 0, NA))})

rural_pop <- rural*pop
rural_pop2 <- calc(rural_pop, function(x) {ifelse(x > 0, 1, ifelse(x == 0, 0, NA))})

ur_pop <- urban2 + rural_pop2

writeRaster(ur_pop,
            filename = paste0("J:/WORK/11_geospatial/wash/urban_pop_rasters/","urban_pop_",time_band[i]),
            format = "GTiff")
}