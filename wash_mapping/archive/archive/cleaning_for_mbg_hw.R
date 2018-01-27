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
data$hw_sdg <- ifelse(data$hw_sdg == 2|data$hw_sdg == 1, 1, 0)

# Split data into points and polygons
data_pt <- filter(data, pt_drop)
data_poly <- filter(data, poly_drop)

# Aggregate to cluster level for points
data_pt <- data_pt %>% group_by(cluster_id) %>% mutate(pweight_total = sum(pweight*hh_size))
data_pt <- mutate(data_pt, wt_indic = (hh_size*pweight*hw_sdg)/pweight_total)
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
data_poly <- mutate(data_poly, wt_indic = (hh_size*pweight*hw_sdg)/pweight_total)
data_poly <- data_poly %>% group_by(poly_id, shapefile, location_code, ihme_loc_id,
                                    year_start) %>% summarize(mbg_indic = sum(wt_indic), weight = length(unique(hh_size)))
data_poly$latitude <- NA
data_poly$longitude <- NA
data_poly$cluster_id <- 1:nrow(data_poly)
data_poly$N <- data_poly$weight
data_poly <- mutate(data_poly, mbg_indic_bin = floor(weight*mbg_indic))

# Resample areal data to generate points
pop_raster <-  raster('J:/WORK/11_geospatial/01_covariates/09_MBG_covariates/WorldPoP_total_global_stack.tif')



for (shp in unique(data_poly$shapefile)[1]) {
  subset <- filter(data_poly, shapefile == shp)
  
  #### READ IN THE WORLDPOP RASTER AND CROP IT TO SHAPEFILE ####
  shape_master <- shapefile(paste0('J:/WORK/11_geospatial/05_survey shapefile library/Shapefile directory/',shp,'.shp'))
  
  generated_pts <- list()
  for (loc in unique(subset$location_code)[1:2]) {
    # raster_crop <- mask(crop(x = pop_raster, y = shape), shape)
    shape <- shape_master[shape_master$GAUL_CODE == loc,]
    subset_loc <- filter(subset, location_code == loc)
    
    for (pid in unique(subset_loc$poly_id)) {  
      subset_loc2 <- filter(subset_loc, poly_id == pid)
      prop <- unique(subset_loc2$mbg_indic)
      samp_pts <- spsample(shape, unique(subset_loc2$weight), type = "random") 
      N <- extract(pop_raster, samp_pts)
      samp_pts2 <- as.data.frame(samp_pts@coords)
      names(samp_pts2) <- c("long", "lat")
      samp_pts2$prop <- prop
      samp_pts2$N <- N
      samp_pts2 <- mutate(samp_pts2, mbg_indic_bin = floor(prop * N))
      samp_pts2$N <- floor(samp_pts2$N)
      pop_cdf <- ecdf(samp_pts2$N)
      samp_pts2 <- mutate(samp_pts2, ntile = pop_cdf(N))
      samp_pts2 <- mutate(samp_pts2, N_adj = floor(quantile(hh_vector, ntile)))
      samp_pts2 <- mutate(samp_pts2, mbg_indic_bin_adj = floor(prop*N_adj))
      samp_pts2$country <- subset_loc2$ihme_loc_id
      samp_pts2$year <- subset_loc2$year_start
      samp_pts2$cluster_id <- pid
      samp_pts2 <- dplyr::select(samp_pts2, country, year, prop, N_adj, mbg_indic_bin_adj, lat,
                          long, cluster_id)
      samp_pts2 <- rename(samp_pts2, N = N_adj)
      samp_pts2 <- rename(samp_pts2, mbg_indic_bin = mbg_indic_bin_adj)
      samp_pts2$point <- 0
      generated_pts[[length(generated_pts) + 1]] <- samp_pts2
    }
    
  }
  generated_pts2 <- do.call(rbind, generated_pts)
}



# Bind together all data for MBG Input

