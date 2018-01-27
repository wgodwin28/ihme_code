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


data <- data2
data$point <- NA
data$point <- ifelse(is.na(data$lat)|is.na(data$long), 0, 1)
data <- mutate(data, cluster_id = paste(survey_name, ihme_loc_id, 
                                        year, survey_module, psu, sep = "_"))
data <- mutate(data, poly_id = paste(survey_name, ihme_loc_id, 
                                     year, survey_module, shapefile,
                                     location_code, sep = "_"))

# Clean indicator data 
# import water categorization
# water_definitions <- read.csv('C:/Users/adesh/Documents/WASH/water_monitoring.csv', stringsAsFactors = F)
# w_other_definitions <- read.csv('C:/Users/adesh/Documents/WASH/water_other_source.csv', stringsAsFactors = F)
#### apply mdg and sdg sanitation categorizations ####
# MDG
# data$mdg <- NA
# for (i in 1:length(water_definitions$x)) {
#   data$mdg[which(data$w_source_drink == water_definitions$x[i])] <- water_definitions$mdg[i]
# }
# 
# data$mdg_other_w <- NA
# for (i in 1:length(water_definitions$x)) {
#   data$mdg_other_w[which(data$w_source_other == w_other_definitions$x[i])] <- w_other_definitions$mdg[i]
# }
# 
# data$mdg[which(data$mdg == "unimproved*")] <- "unimproved"
# data$mdg[which(data$mdg == "improved*")] <- "improved"
# data$mdg[which(data$mdg == "surface*")] <- "surface"
# data$mdg[which(data$mdg == "piped*")] <- "piped"
# 
# data$mdg_other_w[which(data$mdg_other_w == "unimproved*")] <- "unimproved"
# data$mdg_other_w[which(data$mdg_other_w == "improved*")] <- "improved"
# data$mdg_other_w[which(data$mdg_other_w == "surface*")] <- "surface"
# data$mdg_other_w[which(data$mdg_other_w == "piped*")] <- "piped"
# 
# data$mdg[which(data$mdg == "bottled" &
#                            data$mdg_other_w == "improved")] <- "improved"
# data$mdg[which(data$mdg == "bottled" &
#                            data$mdg_other_w == "piped")] <- "improved"
# data$mdg[which(data$mdg == "bottled")] <- "unimproved"
# 
# data$w_piped <- ifelse(data$mdg == "piped", 1, 0)
# data$w_imp <- ifelse(data$mdg == "improved", 1, 0)
# data$w_unimp <- ifelse(data$mdg == "unimproved", 1, 0)
# data$w_surface <- ifelse(data$mdg == "surface", 1, 0)

data$w_piped <- rbinom(4779405, 1, 0.5)
data$w_imp <- rbinom(4779405, 1, 0.5)
data$w_unimp <- rbinom(4779405, 1, 0.5)
data$w_surface <- rbinom(4779405, 1, 0.5)

# Determine which clusters to retain based on data requirements for point and poly data
data <- data %>% group_by(cluster_id) %>% mutate(pt_drop = all(point == 1) & 
                                                   all(!is.na(hh_size)) &
                                                   all(!is.na(pweight)) &
                                                   all(!is.na(w_piped)) &
                                                   all(length(unique(pweight)) == 1))

data <- data %>% group_by(poly_id) %>% mutate(poly_drop = all(point == 0) & 
                                                   all(!is.na(hh_size)) &
                                                   all(!is.na(pweight)) &
                                                   all(!is.na(shapefile)) &
                                                   all(!is.na(location_code)) &
                                                   all(!is.na(w_piped)))

# test <- data %>% group_by(cluster_id) %>% summarize(drop_ct = n_distinct(poly_drop))
# test2 <- data %>% group_by(cluster_id) %>% summarize(drop_ct = n_distinct(pt_drop))

# Subset dataset to only retain acceptable clusters
data <- filter(data, pt_drop|poly_drop)


# Split data into points and polygons
data_pt <- filter(data, pt_drop)
data_poly <- filter(data, poly_drop)

# Aggregate to cluster level for points
data_pt <- data_pt %>% group_by(cluster_id) %>% mutate(pweight_total = sum(pweight*hh_size))
data_pt <- mutate(data_pt, wt_indic = (hh_size*pweight*w_piped)/pweight_total)
data_pt <- data_pt %>% group_by(cluster_id, lat, long,
                                year_start, ihme_loc_id) %>% summarize(mbg_indic = sum(wt_indic), weight = sum(hh_size))
data_pt <- mutate(data_pt, mbg_indic_bin = floor(weight*mbg_indic))

# Aggregate to shapefile x location_id level for polygons
data_poly <- data_poly %>% group_by(poly_id) %>% mutate(pweight_total = sum(pweight*hh_size))
data_poly <- mutate(data_poly, wt_indic = (hh_size*pweight*w_piped)/pweight_total)
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
  
  for (loc in unique(subset$location_code)[1]) {
    # raster_crop <- mask(crop(x = pop_raster, y = shape), shape)
    shape <- shape_master[shape_master$GAUL_CODE == loc,]
    subset_loc <- filter(subset, location_code == loc)
    prop <- unique(subset_loc$mbg_indic)
    samp_pts <- spsample(shape, unique(subset_loc$weight), type = "random") 
    N <- extract(pop_raster, samp_pts)
    samp_pts2 <- as.data.frame(samp_pts@coords)
    names(samp_pts2) <- c("long", "lat")
    samp_pts2$prop <- prop
    samp_pts2$N <- N
    samp_pts2 <- mutate(samp_pts2, mbg_indic_bin = floor(prop * N))
    samp_pts2$N <- floor(samp_pts2$N)
  }
}



# Bind together all data for MBG Input