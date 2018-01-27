library(raster)
library(tmap)
library(sp)
library(dplyr)

india <- shapefile("J:/WORK/11_geospatial/06_original shapefiles/GAUL_admin/admin1/g2015_2014_1/g2015_2014_1.shp")
rajasthan <- india[which(india$ADM1_NAME == "Rajasthan"),]

time_band <- c(2000,2005,2010,2015)

for (i in 1) {
  ur_pop <- raster(paste0("J:/WORK/11_geospatial/wash/urban_pop_rasters/","urban_pop_",time_band[i],".tif"))
  adm0_sen <- rajasthan
  sen_test <- mask(crop(x = ur_pop, y = adm0_sen), adm0_sen)
  sen_test_poly <- rasterToPolygons(sen_test, n = 16, dissolve = T)
  adm1_sen <- adm0_sen
  
  test <- raster::intersect(adm1_sen, sen_test_poly)
  test2 <- raster::union(adm1_sen, test)
  test2@data$urban_pop_2000[which(is.na(test2@data$urban_pop_2000))] <- 0
  test2@data$urban_pop_2000[which(test2@data$urban_pop_2000 == 0)] <- "no_pop"
  test2@data$urban_pop_2000[which(test2@data$urban_pop_2000 == 1)] <- "rural"
  test2@data$urban_pop_2000[which(test2@data$urban_pop_2000 == 2)] <- "urban"
  
  ur_raj <- test2
}

ovr_rand <- spsample(rajasthan, 4, type = "random")
u_rand <- spsample(ur_raj[which(ur_raj$urban_pop_2000 == "urban"),],2, type = "random")
r_rand <- spsample(ur_raj[which(ur_raj$urban_pop_2000 == "rural"),],2, type = "random")

w_pts2 <- data_pt
w_pts <- filter(w_pts2, point == 1)
w_pts$year[which(w_pts$year <= 2000)] <- 2000
w_pts$year[which(w_pts$year > 2000 & w_pts$year <= 2005)] <- 2005
w_pts$year[which(w_pts$year > 2005 & w_pts$year <= 2010)] <- 2010
w_pts$year[which(w_pts$year > 2010)] <- 2015

ur_bias <- list()
for (i in 1:4) {
  ghsl <- raster("J:/WORK/11_geospatial/01_covariates/09_MBG_covariates/GHS_settlement_model_stack.tif",
                   layer = i)
  full_data <- w_pts
  relevant <- filter(w_pts, year == time_band[i])
  relevant <- ungroup(relevant)
  rel_pts <- SpatialPointsDataFrame(coords =(cbind(relevant$long, relevant$lat)),
                                    relevant)
  rel_pts$ghsl <- extract(ghsl, rel_pts)
  ur_bias[[length(ur_bias)+1]] <- rel_pts@data
}

ur_bias <- do.call(rbind, ur_bias)
ur_bias2 <- select(ur_bias, lat, long, urban, ghsl)
ur_bias2 <- distinct(ur_bias2)
length(ur_bias2$urban[which(ur_bias2$urban == 1 & ur_bias2$ghsl == 1)])
length(ur_bias2$urban[which(ur_bias2$urban == 1 & ur_bias2$ghsl == 0)])
length(ur_bias2$urban[which(ur_bias2$urban == 0 & ur_bias2$ghsl == 0)])
length(ur_bias2$urban[which(ur_bias2$urban == 0 & ur_bias2$ghsl == 1)])

#graph 1
tm_shape(rajasthan) + tm_borders()

#graph 2
tm_shape(rajasthan) + tm_borders() +
  tm_shape(ovr_rand) + tm_dots(size = 0.15)

#graph 3
tm_shape(sen_test) + tm_raster(legend.show = F)

#graph 4
tm_shape(ur_raj) + tm_borders() + tm_fill("urban_pop_2000", legend.show = F)

#graph 5
tm_shape(ur_raj) + tm_borders() + tm_fill("urban_pop_2000", legend.show = F) +
  tm_shape(u_rand) + tm_dots(col = "blue", size = 0.15) + 
  tm_shape(r_rand) + tm_dots(col = "red", size = 0.15)