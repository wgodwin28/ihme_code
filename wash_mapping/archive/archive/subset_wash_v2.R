# Prepare for WaSH Mapping

# Load Packages
library(dplyr)
if (!("all" %in% ls())) {
  load("J:/LIMITED_USE/LU_GEOSPATIAL/geo_matched/wash/2017_04_04.Rdata")
}

if (!("id_ref" %in% ls())) {
  id_ref <- read.csv("J:/WORK/11_geospatial/pandemic_indicator/data/raw/geographies/id_convert_ammended.csv")
}

afro_gaul <- c(4,6,8,29,35,42,43,45,47,49,50,58,59,66,68,70,
  74,76,77,79,89,90,94,95,105,106,142,144,145,150,
  152,155,159,169,170,172,181,182,205,214,217,221,
  226,235,243,248,253,268,270,271,40764,40765,
  227,257,133)

wash <- all

#### WATER ####
# Subset sanitation to necessary variables
water <- dplyr::select(all, nid, year_start, survey_name, ihme_loc_id, strata, psu, pweight, hhweight, shapefile, location_code,
               lat, long, latitude, longitude, urban, hh_size, w_source_drink, w_source_other)

## holdover until data is cleaned by definition ##
# Clean indicator data 
w_def <- read.csv('C:/Users/adesh/Documents/WASH/definitions/w_source_defined.csv', stringsAsFactors = F)
w_other_def <- read.csv('C:/Users/adesh/Documents/WASH/definitions/w_other_defined.csv', stringsAsFactors = F)

water$w_source_sdg <- NA
for (i in unique(water$w_source_drink)) {
  tryCatch({
    water$w_source_sdg[which(water$w_source_drink == i)] <- w_def$sdg[which(w_def$x == i)]
    }, error = function(e){})
}

water$w_other_sdg <- NA
for (i in unique(water$w_source_other)) {
  tryCatch({
    water$w_other_sdg[which(water$w_source_other == i)] <- w_other_def$sdg[which(w_other_def$x == i)]
  }, error = function(e){})
}


water$w_source_sdg[which(water$w_source_sdg == "")] <- NA
water$w_other_sdg[which(water$w_other_sdg == "")] <- NA

water$w_master_sdg <- NA
water$w_master_sdg <- ifelse(water$w_source_sdg == "piped", 3,
                            ifelse(water$w_source_sdg == "improved", 2, 
                                   ifelse(water$w_source_sdg == "unimproved", 1, 
                                          ifelse(water$w_source_sdg == "surface", 0, NA)))) 

water$w_master_sdg[which(water$w_source_sdg == "bottled")] <- 1
water$w_master_sdg[which(water$w_source_sdg == "bottled" &
                          (water$w_other_sdg == "piped"|water$w_other_sdg == "improved")  )] <- 2
water$w_piped <- ifelse(water$w_master_sdg == 3, 1, 
                        ifelse(is.na(water$w_master_sdg), NA, 0))

# water$w_source_drink <- ifelse(is.na(water$w_source_drink), NA, 1)
# water$hh_size <- 1
#####
# Fix redundant lat/long and weight variable issue
water$lat <- ifelse(is.na(water$lat) & !is.na(water$latitude), water$latitude, water$lat)
water$lat <- ifelse(!is.na(water$lat) & !is.na(water$latitude) &
                     (water$lat != water$latitude), water$latitude, water$lat)

water$long <- ifelse(is.na(water$long) & !is.na(water$longitude), water$longitude, water$long)
water$long <- ifelse(!is.na(water$long) & !is.na(water$longitude) &
                      (water$long != water$longitude), water$longitude, water$long)

water$hhweight <- ifelse(is.na(water$hhweight), water$pweight, water$hhweight)

# Subset to relevant geographies
water <- filter(water, ihme_loc_id %in% (id_ref$ISO3[which(id_ref$GAUL %in% afro_gaul)]))

# Remove non-survey data
water <- filter(water, !(survey_name %in% c("IPUMS_CENSUS",'PROJECT_FOLDERS')))

# Remove data without any geography 
water$no_geo <- ifelse((is.na(water$lat)|is.na(water$latitude)) & is.na(water$shapefile), 1, 0)
water <- filter(water, no_geo == 0)

# Identify point and polygons and create poly and cluster IDs
water <- mutate(water, cluster_id = paste(survey_name, ihme_loc_id, 
                                        year_start, psu, sep = "_"))
water <- mutate(water, poly_id = paste(survey_name, ihme_loc_id, 
                                     year_start, shapefile,
                                     location_code, sep = "_"))
water$point <- ifelse(is.na(water$lat)|is.na(water$long), 0, 1)

# Identify lat/long clusters and split data into points and polys
point_ids <- unique(water$cluster_id[which(water$point == 1)])
water_pt <- filter(water, cluster_id %in% point_ids)
water_poly <- filter(water, !(cluster_id %in% point_ids))

# Remove polygons with either shapefile or location_code missing
water_poly$shapefile[which(water_poly$shapefile == "")] <- NA
water_poly$location_code[which(water_poly$shapefile == "")] <- NA
water_poly <- filter(water_poly, !is.na(shapefile)|!is.na(location_code))

# Remove points and polygons with >80% indicator data missing
pt_indi_miss <- water_pt %>% group_by(cluster_id) %>% summarize(indi_miss = (sum(is.na(w_piped))/length(w_piped)))
rm_pt_indi <- pt_indi_miss$cluster_id[which(pt_indi_miss$indi_miss >= 0.8)]
water_pt <- filter(water_pt, !(cluster_id %in% rm_pt_indi))

poly_indi_miss <- water_poly %>% group_by(poly_id) %>% summarize(indi_miss = (sum(is.na(w_piped))/length(w_piped)))
rm_poly_indi <- poly_indi_miss$poly_id[which(poly_indi_miss$indi_miss >= 0.8)]
water_poly <- filter(water_poly, !(poly_id %in% rm_poly_indi))

# Assign the rest of NA pts and polygons the mean for their analytical unit
impute_vals <- water_pt %>% group_by(cluster_id) %>% summarize(impute = mean(w_piped, na.rm = T))
water_pt <- water_pt %>% group_by(cluster_id) %>% mutate(need_imp = any(is.na(w_piped)))
pb = txtProgressBar(min = 0, max = nrow(water_pt), initial = 0, style = 3) 
for (i in 1:nrow(water_pt)) {
  setTxtProgressBar(pb,i)
  if (is.na(water_pt$w_piped[i])) {
    water_pt$w_piped[i] <- impute_vals$impute[which(impute_vals$cluster_id == 
                                                      water_pt$cluster_id[i])]
  }
}

impute_vals <- water_poly %>% group_by(poly_id) %>% summarize(impute = mean(w_piped, na.rm = T))
water_poly <- water_poly %>% group_by(poly_id) %>% mutate(need_imp = any(is.na(w_piped)))
pb = txtProgressBar(min = 0, max = nrow(water_poly), initial = 0, style = 3) 
for (i in 1:nrow(water_poly)) {
  setTxtProgressBar(pb,i)
  if (is.na(water_poly$w_piped[i])) {
    water_poly$w_piped[i] <- impute_vals$impute[which(impute_vals$poly_id == 
                                                      water_poly$poly_id[i])]
  }
}

# Remove points and polygons with hhweight missing or invalid hhweight values
# hhw_miss_pt <- water_pt %>% group_by(cluster_id) %>% summarize(hh_miss = (sum(is.na(hhweight))))
water_pt <- water_pt %>% group_by(cluster_id) %>% mutate(hh_inv = any(hhweight < 0))
# rm_pt_hhw <- hhw_miss_pt$cluster_id[which(hhw_miss_pt$hh_miss > 0)]
# water_pt <- filter(water_pt, !(cluster_id %in% rm_pt_hhw) & !hh_inv)
water_pt <- filter(water_pt, !hh_inv)

hhw_miss_poly <- water_poly %>% group_by(poly_id) %>% summarize(hh_miss = (sum(is.na(hhweight))))
rm_poly_hhw <- hhw_miss_poly$poly_id[which(hhw_miss_poly$hh_miss > 0)]
water_poly <- water_poly %>% group_by(poly_id) %>% mutate(hh_inv = any(hhweight < 0))
water_poly <- filter(water_poly, !(poly_id %in% rm_poly_hhw) & !hh_inv)

# Identify pts and polys that need hh_crosswalking
# remove pts and polys with urban missing or invalid for computing CW ratios
water_pt2 <- water_pt
water_pt2 <- water_pt2 %>% group_by(cluster_id) %>% mutate(urban_miss = any(is.na(urban)))
water_pt2 <- filter(water_pt2, !urban_miss)

water_poly2 <- water_poly
water_poly2 <- water_poly2 %>% group_by(poly_id) %>% mutate(urban_miss = any(is.na(urban)))
water_poly2 <- filter(water_poly2, !urban_miss)


water_pt <- water_pt %>% group_by(cluster_id) %>% mutate(hh_miss = any((is.na(hh_size))))
water_pt2 <- water_pt2 %>% group_by(cluster_id) %>% mutate(hh_miss = any((is.na(hh_size))))
water_pt_u_hhcw <- filter(water_pt2, !hh_miss & urban == 1)
water_pt_u_hhcw$hh_cw <- 1
water_pt_u_hhcw <- water_pt_u_hhcw %>% group_by(cluster_id) %>% mutate(weight_total = sum(hh_size))
water_pt_u_hhcw <- mutate(water_pt_u_hhcw, wt_indic = (hh_size*w_piped)/weight_total)
water_pt_u_hhcw_agg <- water_pt_u_hhcw %>% group_by(year_start, survey_name, ihme_loc_id, lat, long,
                                                    w_piped, cluster_id, nid, hh_cw, weight_total) %>% summarize(water = sum(wt_indic))
  
water_pt_u_hhcw_2 <- water_pt_u_hhcw
water_pt_u_hhcw_2$hh_cw <- 0
water_pt_u_hhcw_2$hh_size <- 1
water_pt_u_hhcw_2 <- water_pt_u_hhcw_2 %>% group_by(cluster_id) %>% mutate(weight_total = sum(hhweight))
water_pt_u_hhcw_2 <- mutate(water_pt_u_hhcw_2, wt_indic = (hh_size*w_piped)/weight_total)
water_pt_u_hhcw_agg2 <- water_pt_u_hhcw_2 %>% group_by(year_start, survey_name, ihme_loc_id, lat, long,
                                                       w_piped, cluster_id, nid, hh_cw, weight_total) %>% summarize(water = sum(wt_indic))

water_pt_u_hhcw_f <- rbind(water_pt_u_hhcw_agg, water_pt_u_hhcw_agg2)
hhcw <- glm(water ~ hh_cw, family = binomial(link = "logit"), data = water_pt_u_hhcw_f, weights = weight_total)
hhcw_pt_u <- exp(hhcw$coefficients[2])

water_pt_r_hhcw <- filter(water_pt2, !hh_miss & urban == 0)
water_pt_r_hhcw$hh_cw <- 1
water_pt_r_hhcw <- water_pt_r_hhcw %>% group_by(cluster_id) %>% mutate(weight_total = sum(hh_size))
water_pt_r_hhcw <- mutate(water_pt_r_hhcw, wt_indic = (hh_size*w_piped)/weight_total)
water_pt_r_hhcw_agg <- water_pt_r_hhcw %>% group_by(year_start, survey_name, ihme_loc_id, lat, long,
                                                    w_piped, cluster_id, nid, hh_cw, weight_total) %>% summarize(water = sum(wt_indic))

water_pt_r_hhcw_2 <- water_pt_r_hhcw
water_pt_r_hhcw_2$hh_cw <- 0
water_pt_r_hhcw_2$hh_size <- 1
water_pt_r_hhcw_2 <- water_pt_r_hhcw_2 %>% group_by(cluster_id) %>% mutate(weight_total = sum(hh_size))
water_pt_r_hhcw_2 <- mutate(water_pt_r_hhcw_2, wt_indic = (hh_size*w_piped)/weight_total)
water_pt_r_hhcw_agg2 <- water_pt_r_hhcw_2 %>% group_by(year_start, survey_name, ihme_loc_id, lat, long,
                                                       w_piped, cluster_id, nid, hh_cw, weight_total) %>% summarize(water = sum(wt_indic))

water_pt_r_hhcw_f <- rbind(water_pt_r_hhcw_agg, water_pt_r_hhcw_agg2)
hhcw <- glm(water ~ hh_cw, family = binomial(link = "logit"), data = water_pt_r_hhcw_f, weights = weight_total)
hhcw_pt_r <- exp(hhcw$coefficients[2])


#####
water_poly <- water_poly %>% group_by(poly_id) %>% mutate(hh_miss = any((is.na(hh_size))))
water_poly2 <- water_poly2 %>% group_by(poly_id) %>% mutate(hh_miss = any((is.na(hh_size))))
water_poly_u_hhcw <- filter(water_poly2, !hh_miss & urban == 1)
water_poly_u_hhcw$hh_cw <- 1
water_poly_u_hhcw <- water_poly_u_hhcw %>% group_by(poly_id) %>% mutate(weight_total = sum(hhweight*hh_size))
water_poly_u_hhcw <- mutate(water_poly_u_hhcw, wt_indic = (hh_size*hhweight*w_piped)/weight_total)
water_poly_u_hhcw_agg <- water_poly_u_hhcw %>% group_by(year_start, survey_name, ihme_loc_id, shapefile, location_code,
                                                        w_piped, poly_id, nid, hh_cw, weight_total) %>% summarize(water = sum(wt_indic))

water_poly_u_hhcw_2 <- water_poly_u_hhcw
water_poly_u_hhcw_2$hh_cw <- 0
water_poly_u_hhcw_2$hh_size <- 1
water_poly_u_hhcw_2 <- water_poly_u_hhcw_2 %>% group_by(poly_id) %>% mutate(weight_total = sum(hhweight*hh_size))
water_poly_u_hhcw_2 <- mutate(water_poly_u_hhcw_2, wt_indic = (hh_size*hhweight*w_piped)/weight_total)
water_poly_u_hhcw_agg2 <- water_poly_u_hhcw_2 %>%  group_by(year_start, survey_name, ihme_loc_id, shapefile, location_code,
                                                            w_piped, poly_id, nid, hh_cw, weight_total) %>% summarize(water = sum(wt_indic))


water_poly_u_hhcw_f <- rbind(water_poly_u_hhcw_agg, water_poly_u_hhcw_agg2)
hhcw <- glm(water ~ hh_cw, family = binomial(link = "logit"), data = water_poly_u_hhcw_f, weights = weight_total)
hhcw_poly_u <- exp(hhcw$coefficients[2])

water_poly_r_hhcw <- filter(water_poly2, !hh_miss & urban == 0)
water_poly_r_hhcw$hh_cw <- 1
water_poly_r_hhcw <- water_poly_r_hhcw %>% group_by(poly_id) %>% mutate(weight_total = sum(hhweight*hh_size))
water_poly_r_hhcw <- mutate(water_poly_r_hhcw, wt_indic = (hh_size*hhweight*w_piped)/weight_total)
water_poly_r_hhcw_agg <- water_poly_r_hhcw %>% group_by(year_start, survey_name, ihme_loc_id, shapefile, location_code,
                                                        w_piped, poly_id, nid, hh_cw, weight_total) %>% summarize(water = sum(wt_indic))

water_poly_r_hhcw_2 <- water_poly_r_hhcw
water_poly_r_hhcw_2$hh_cw <- 0
water_poly_r_hhcw_2$hh_size <- 1
water_poly_r_hhcw_2 <- water_poly_r_hhcw_2 %>% group_by(poly_id) %>% mutate(weight_total = sum(hhweight*hh_size))
water_poly_r_hhcw_2 <- mutate(water_poly_r_hhcw_2, wt_indic = (hh_size*hhweight*w_piped)/weight_total)
water_poly_r_hhcw_agg2 <- water_poly_r_hhcw_2 %>%  group_by(year_start, survey_name, ihme_loc_id, shapefile, location_code,
                                                            w_piped, poly_id, nid, hh_cw, weight_total) %>% summarize(water = sum(wt_indic))


water_poly_r_hhcw_f <- rbind(water_poly_r_hhcw_agg, water_poly_r_hhcw_agg2)
hhcw <- glm(water ~ hh_cw, family = binomial(link = "logit"), data = water_poly_r_hhcw_f, weights = weight_total)
hhcw_poly_r <- exp(hhcw$coefficients[2])

# Aggregate by cluster_id and poly_id 
water_pt_nocw <- filter(water_pt, !hh_miss)
water_pt_nocw <- water_pt_nocw %>% group_by(cluster_id) %>% mutate(weight_total = sum(hhweight*hh_size), hh_total = sum(hh_size))
water_pt_nocw <- mutate(water_pt_nocw, wt_indic = (hh_size*hhweight*w_piped)/weight_total)
water_pt_agg_nocw <- water_pt_nocw %>% group_by(year_start, survey_name, ihme_loc_id, lat, long,
                                                cluster_id, nid, hh_total) %>% summarize(water = sum(wt_indic))

water_pt_cw <- filter(water_pt2, hh_miss)
water_pt_cw$hh_size <- ifelse(water_pt_cw$urban == 1, hhcw_pt_u, hhcw_pt_r)
water_pt_cw <- water_pt_cw %>% group_by(cluster_id) %>% mutate(weight_total = sum(hhweight*hh_size), hh_total = sum(hh_size))
water_pt_cw <- mutate(water_pt_cw, wt_indic = (hh_size*hhweight*w_piped)/weight_total)
water_pt_agg_cw <- water_pt_cw %>% group_by(year_start, survey_name, ihme_loc_id, lat, long,
                                            cluster_id, nid, hh_total) %>% summarize(water = sum(wt_indic))

water_poly_nocw <- filter(water_poly, !hh_miss)
water_poly_nocw <- water_poly_nocw %>% group_by(poly_id) %>% mutate(weight_total = sum(hhweight*hh_size), hh_total = sum(hh_size),
                                                                    neff_adj = (((sum(hhweight))^2)/(sum((hhweight^2))))/(length(hh_size)),
                                                                    n_pts = n_distinct(psu))
water_poly_nocw <- water_poly_nocw %>% group_by(poly_id) %>% mutate(hh_total = hh_total*neff_adj)
water_poly_nocw <- mutate(water_poly_nocw, wt_indic = (hh_size*hhweight*w_piped)/weight_total)
water_poly_agg_nocw <- water_poly_nocw %>% group_by(year_start, survey_name, ihme_loc_id, shapefile, location_code,
                                                    poly_id, nid, hh_total,n_pts) %>% summarize(water = sum(wt_indic))

water_poly_cw <- filter(water_poly2, hh_miss)
water_poly_cw$hh_size <- ifelse(water_poly_cw$urban == 1, hhcw_poly_u, hhcw_poly_r)
water_poly_cw <- water_poly_cw %>% group_by(poly_id) %>% mutate(weight_total = sum(hhweight*hh_size), hh_total = sum(hh_size),
                                                                    neff_adj = (((sum(hhweight))^2)/(sum((hhweight^2))))/(length(hh_size)),
                                                                    n_pts = n_distinct(psu))
water_poly_cw <- water_poly_cw %>% group_by(poly_id) %>% mutate(hh_total = hh_total*neff_adj)
water_poly_cw <- mutate(water_poly_cw, wt_indic = (hh_size*hhweight*w_piped)/weight_total)
water_poly_agg_cw <- water_poly_cw %>% group_by(year_start, survey_name, ihme_loc_id, shapefile, location_code,
                                                    poly_id, nid, hh_total,n_pts) %>% summarize(water = sum(wt_indic))

# Turn polys into points
water_poly_f <- rbind(water_poly_agg_cw, water_poly_agg_nocw)

#### SANITATION ####
# Subset sanitation to necessary variables
sani <- select(all, nid, year_start, survey_name, ihme_loc_id, strata, psu, pweight, hhweight, shapefile, location_code,
                     lat, long, latitude, longitude, urban, hh_size, t_type, shared_san)

## holdover until data is cleaned by definition ##
sani$t_type <- ifelse(is.na(sani$t_type), NA, 1)
sani$hh_size <- 1

# Fix redundant lat/long and weight variable issue
sani$lat <- ifelse(is.na(sani$lat) & !is.na(sani$latitude), sani$latitude, sani$lat)
sani$lat <- ifelse(!is.na(sani$lat) & !is.na(sani$latitude) &
                     (sani$lat != sani$latitude), sani$latitude, sani$lat)

sani$long <- ifelse(is.na(sani$long) & !is.na(sani$longitude), sani$longitude, sani$long)
sani$long <- ifelse(!is.na(sani$long) & !is.na(sani$longitude) &
                      (sani$long != sani$longitude), sani$longitude, sani$long)

sani$hhweight <- ifelse(is.na(sani$hhweight), sani$pweight, sani$hhweight)

# Subset to relevant geographies
sani <- filter(sani, ihme_loc_id %in% (id_ref$ISO3[which(id_ref$GAUL %in% afro_gaul)]))

# Remove non-survey data
sani <- filter(sani, !(survey_name %in% c("IPUMS_CENSUS",'PROJECT_FOLDERS')))

# Remove data without any geography 
sani$no_geo <- ifelse((is.na(sani$lat)|is.na(sani$latitude)) & is.na(sani$shapefile), 1, 0)
sani <- filter(sani, no_geo == 0)

# Identify point and polygons and create poly and cluster IDs
sani <- mutate(sani, cluster_id = paste(survey_name, ihme_loc_id, 
                                        year_start, psu, sep = "_"))
sani <- mutate(sani, poly_id = paste(survey_name, ihme_loc_id, 
                                     year_start, shapefile,
                                     location_code, sep = "_"))
sani$point <- ifelse(is.na(sani$lat)|is.na(sani$long), 0, 1)

# Identify lat/long clusters and split data into points and polys
point_ids <- unique(sani$cluster_id[which(sani$point == 1)])
sani_pt <- filter(sani, cluster_id %in% point_ids)
sani_poly <- filter(sani, !(cluster_id %in% point_ids))

# Remove points and polygons with >80% indicator data missing
pt_indi_miss <- sani_pt %>% group_by(cluster_id) %>% summarize(indi_miss = (sum(is.na(t_type))/length(t_type)))
rm_pt_indi <- pt_indi_miss$cluster_id[which(pt_indi_miss$indi_miss >= 0.8)]
sani_pt <- filter(sani_pt, !(cluster_id %in% rm_pt_indi))

poly_indi_miss <- sani_poly %>% group_by(poly_id) %>% summarize(indi_miss = (sum(is.na(t_type))/length(t_type)))
rm_poly_indi <- poly_indi_miss$poly_id[which(poly_indi_miss$indi_miss >= 0.8)]
sani_poly <- filter(sani_poly, !(poly_id %in% rm_pt_indi))

# Remove points and polygons with hhweight missing
hhw_miss_pt <- sani_pt %>% group_by(cluster_id) %>% summarize(hh_miss = (sum(is.na(hhweight))))
rm_pt_hhw <- hhw_miss_pt$cluster_id[which(hhw_miss_pt$hh_miss > 0)]
sani_pt <- filter(sani_pt, !(cluster_id) %in% rm_pt_hhw)
  
hhw_miss_poly <- sani_poly %>% group_by(poly_id) %>% summarize(hh_miss = (sum(is.na(hhweight))))
rm_poly_hhw <- hhw_miss_poly$poly_id[which(hhw_miss_poly$hh_miss > 0)]
sani_poly <- filter(sani_poly, !(cluster_id) %in% rm_poly_hhw)
  


# Identify pts and polys that need hh_crosswalking

# Identify pts and polys that need shared_san

# Aggregate by cluster_id and poly_id 
sani_pt <- sani_pt %>% group_by(cluster_id) %>% mutate(weight_total = sum(hhweight*hh_size))
sani_pt <- mutate(sani_pt, wt_indic = (hh_size*hhweight*t_type)/weight_total)
sani_pt_agg <- sani_pt %>% group_by(year_start, survey_name, ihme_loc_id, lat, long,
                        t_type, cluster_id, nid) %>% summarize(sani = sum(wt_indic))

sani_poly <- sani_poly %>% group_by(poly_id) %>% mutate(weight_total = sum(hhweight*hh_size))
sani_poly <- mutate(sani_poly, wt_indic = (hh_size*hhweight*t_type)/weight_total)
sani_poly_agg <- sani_poly %>% group_by(year_start, survey_name, ihme_loc_id, shapefile, location_code,
                                    t_type, poly_id, nid) %>% summarize(sani = sum(wt_indic))

#### HYGIENE ####
hygiene <- select(all, nid, year_start, survey_name, ihme_loc_id, strata, psu, pweight, hhweight, shapefile, location_code,
                     lat, long, latitude, longitude, hh_size, hw_station, hw_soap, hw_water)

## holdover until data is cleaned by definition ##
hygiene$w_source_drink <- ifelse(is.na(hygiene$hw_station), NA, 1)
hygiene$hh_size <- 1

# Fix redundant lat/long and weight variable issue
hygiene$lat <- ifelse(is.na(hygiene$lat) & !is.na(hygiene$latitude), hygiene$latitude, hygiene$lat)
hygiene$lat <- ifelse(!is.na(hygiene$lat) & !is.na(hygiene$latitude) &
                      (hygiene$lat != hygiene$latitude), hygiene$latitude, hygiene$lat)

hygiene$long <- ifelse(is.na(hygiene$long) & !is.na(hygiene$longitude), hygiene$longitude, hygiene$long)
hygiene$long <- ifelse(!is.na(hygiene$long) & !is.na(hygiene$longitude) &
                       (hygiene$long != hygiene$longitude), hygiene$longitude, hygiene$long)

hygiene$hhweight <- ifelse(is.na(hygiene$hhweight), hygiene$pweight, hygiene$hhweight)

# Subset to relevant geographies
hygiene <- filter(hygiene, ihme_loc_id %in% (id_ref$ISO3[which(id_ref$GAUL %in% afro_gaul)]))

# Remove non-survey data
hygiene <- filter(hygiene, !(survey_name %in% c("IPUMS_CENSUS",'PROJECT_FOLDERS')))

# Remove data without any geography 
hygiene$no_geo <- ifelse((is.na(hygiene$lat)|is.na(hygiene$latitude)) & is.na(hygiene$shapefile), 1, 0)
hygiene <- filter(hygiene, no_geo == 0)

# Identify point and polygons and create poly and cluster IDs
hygiene <- mutate(hygiene, cluster_id = paste(survey_name, ihme_loc_id, 
                                          year_start, psu, sep = "_"))
hygiene <- mutate(hygiene, poly_id = paste(survey_name, ihme_loc_id, 
                                       year_start, shapefile,
                                       location_code, sep = "_"))
hygiene$point <- ifelse(is.na(hygiene$lat)|is.na(hygiene$long), 0, 1)

# Identify lat/long clusters and split data into points and polys
point_ids <- unique(hygiene$cluster_id[which(hygiene$point == 1)])
hygiene_pt <- filter(hygiene, cluster_id %in% point_ids)
hygiene_poly <- filter(hygiene, !(cluster_id %in% point_ids))

# Remove points and polygons with >80% indicator data missing
pt_indi_miss <- hygiene_pt %>% group_by(cluster_id) %>% summarize(indi_miss = (sum(is.na(hw_station))/length(hw_station)))
rm_pt_indi <- pt_indi_miss$cluster_id[which(pt_indi_miss$indi_miss >= 0.8)]
hygiene_pt <- filter(hygiene_pt, !(cluster_id %in% rm_pt_indi))

poly_indi_miss <- hygiene_poly %>% group_by(poly_id) %>% summarize(indi_miss = (sum(is.na(hw_station))/length(hw_station)))
rm_poly_indi <- poly_indi_miss$poly_id[which(poly_indi_miss$indi_miss >= 0.8)]
hygiene_poly <- filter(hygiene_poly, !(poly_id %in% rm_pt_indi))

# Remove points and polygons with hhweight missing
hhw_miss_pt <- hygiene_pt %>% group_by(cluster_id) %>% summarize(hh_miss = (sum(is.na(hhweight))))
rm_pt_hhw <- hhw_miss_pt$cluster_id[which(hhw_miss_pt$hh_miss > 0)]
hygiene_pt <- filter(hygiene_pt, !(cluster_id) %in% rm_pt_hhw)

hhw_miss_poly <- hygiene_poly %>% group_by(poly_id) %>% summarize(hh_miss = (sum(is.na(hhweight))))
rm_poly_hhw <- hhw_miss_poly$poly_id[which(hhw_miss_poly$hh_miss > 0)]
hygiene_poly <- filter(hygiene_poly, !(cluster_id) %in% rm_poly_hhw)



# Identify pts and polys that need hh_crosswalking

# Identify pts and polys that need shared_san

# Aggregate by cluster_id and poly_id 
hygiene_pt <- hygiene_pt %>% group_by(cluster_id) %>% mutate(weight_total = sum(hhweight*hh_size))
hygiene_pt <- mutate(hygiene_pt, wt_indic = (hh_size*hhweight*hw_station)/weight_total)
hygiene_pt_agg <- hygiene_pt %>% group_by(year_start, survey_name, ihme_loc_id, lat, long,
                                          hw_station, cluster_id, nid) %>% summarize(sani = sum(wt_indic))

hygiene_poly <- hygiene_poly %>% group_by(poly_id) %>% mutate(weight_total = sum(hhweight*hh_size))
hygiene_poly <- mutate(hygiene_poly, wt_indic = (hh_size*hhweight*hw_station)/weight_total)
hygiene_poly_agg <- hygiene_poly %>% group_by(year_start, survey_name, ihme_loc_id, shapefile, location_code,
                                              hw_station, poly_id, nid) %>% summarize(sani = sum(wt_indic))