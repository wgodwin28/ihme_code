# Prepare for WaSH Mapping

# Load Packages
library(dplyr)
library(raster)

# Load data and add in unique cluster ID, and categorize as pt or poly data
data2 <- read.csv('J:/WORK/11_geospatial/02_processed data/WASH/extractions_1_19_17/WaSH.csv', stringsAsFactors = F)
# data3 <- fread('J:/WORK/11_geospatial/02_processed data/WASH/extractions_1_19_17/WaSH.csv', stringsAsFactors = F)

# writing variable values for categorization
# w_source_val <- unique(data2$w_source_drink)
# w_other_val <- unique(data2$w_source_other)
# t_source_val <- unique(data2$t_type)
# 
# write.csv(w_source_val, 'C:/Users/adesh/Documents/WASH/definitions/w_source.csv')
# write.csv(w_other_val, 'C:/Users/adesh/Documents/WASH/definitions/w_other.csv')
# write.csv(t_source_val, 'C:/Users/adesh/Documents/WASH/definitions/t_source.csv')

# Get vector for hh_size in data across the 0:20
hh_vector <- data2$hh_size[which(data2$hh_size <= 20)]

# Start Cleaning
data <- data2
data$point <- NA
data$point <- ifelse(is.na(data$lat)|is.na(data$long), 0, 1)
data <- mutate(data, cluster_id = paste(survey_name, ihme_loc_id, 
                                        year, survey_module, psu, sep = "_"))
data <- mutate(data, poly_id = paste(survey_name, ihme_loc_id, 
                                     year, survey_module, shapefile,
                                     location_code, sep = "_"))

# Clean indicator data 
data$hw_sdg <- ifelse(data$hw_station == 1 & data$hw_water == 1 &
                        data$hw_soap == 1, 2, 
                      ifelse(data$hw_station == 1, 1,
                             ifelse(data$hw_station == 0, 0, NA)))

# Determine which clusters to retain based on data requirements for point and poly data
data <- data %>% group_by(cluster_id) %>% mutate(pt_drop = all(point == 1) & 
                                                   all(!is.na(hh_size)) &
                                                   all(hh_size > 0) &
                                                   all(!is.na(pweight)) &
                                                   all(!is.na(hw_sdg)) &
                                                   all(length(unique(pweight)) == 1))

data <- data %>% group_by(poly_id) %>% mutate(poly_drop = all(point == 0) & 
                                                all(!is.na(hh_size)) &
                                                all(hh_size > 0) &
                                                all(!is.na(pweight)) &
                                                all(!is.na(shapefile)) &
                                                all(!is.na(location_code)) &
                                                all(!is.na(hw_sdg)))

# test <- data %>% group_by(cluster_id) %>% summarize(drop_ct = n_distinct(poly_drop))
# test2 <- data %>% group_by(cluster_id) %>% summarize(drop_ct = n_distinct(pt_drop))

# Subset dataset to only retain acceptable clusters
data <- filter(data, pt_drop|poly_drop)
data$hw_basic <- ifelse(data$hw_sdg == 2, 1, 0)
data$hw_unimp <- ifelse(data$hw_sdg == 1, 1, 0)
data$hw_no <- ifelse(data$hw_sdg == 0, 1, 0)

# Split data into points and polygons
data_pt <- filter(data, pt_drop)
data_poly <- filter(data, poly_drop)

# Aggregate to cluster level for points
data_pt <- data_pt %>% group_by(cluster_id) %>% mutate(pweight_total = sum(pweight*hh_size))
data_pt <- mutate(data_pt, wt_indic = (hh_size*pweight*hw_no)/pweight_total)
data_pt <- data_pt %>% group_by(cluster_id, lat, long,
                                year_start, ihme_loc_id) %>% summarize(mbg_indic = sum(wt_indic), weight = sum(hh_size))
data_pt <- mutate(data_pt, mbg_indic_bin = floor(weight*mbg_indic))
data_pt <- rename(data_pt, country = ihme_loc_id)
data_pt <- rename(data_pt, year = year_start)
data_pt <- rename(data_pt, prop = mbg_indic)
data_pt <- rename(data_pt, N = weight)
data_pt <- as.data.frame(data_pt)
data_pt <- dplyr::select(data_pt, country, year, prop, N, mbg_indic_bin, lat, long, cluster_id)
data_pt$point <- 1

# Aggregate to shapefile x location_id level for polygons
data_poly <- data_poly %>% group_by(poly_id) %>% mutate(pweight_total = sum(pweight*hh_size))
data_poly <- mutate(data_poly, wt_indic = (hh_size*pweight*hw_no)/pweight_total)
data_poly <- data_poly %>% group_by(poly_id, shapefile, location_code, ihme_loc_id,
                                    year_start) %>% summarize(mbg_indic = sum(wt_indic), weight = length(unique(hh_size)))
data_poly$latitude <- NA
data_poly$longitude <- NA
data_poly$cluster_id <- 1:nrow(data_poly)
data_poly$N <- data_poly$weight
data_poly <- mutate(data_poly, mbg_indic_bin = floor(weight*mbg_indic))

# Resample areal data to generate points
pop_raster <-  raster('J:/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPoP_total_global_stack.tif')



for (shp in unique(data_poly$shapefile)) {
  subset <- filter(data_poly, shapefile == shp)
  save(subset, file = paste0("J:/WORK/11_geospatial/wash/resampling/hw/no_facility/subset_",shp,".RData"))
 }

save(data_pt, file = "J:/WORK/11_geospatial/wash/resampling/hw/no_facility/master_pt.RData")
save(data_poly, file = "J:/WORK/11_geospatial/wash/resampling/hw/no_facility/master_poly.RData")
save(hh_vector, file = "J:/WORK/11_geospatial/wash/resampling/hw/no_facility/hh_vector.RData")