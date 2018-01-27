library(dplyr)

setwd('J:/WORK/11_geospatial/02_processed data/WASH')

# read in data
ais <- read.csv('MACRO_AIS_wash_geospatial_ALLDATA.csv', stringsAsFactors = F)
dhs <- read.csv('MACRO_DHS_wash_geospatial_ALLDATA.csv', stringsAsFactors = F)
mis <- read.csv('MACRO_MIS_wash_geospatial_ALLDATA.csv', stringsAsFactors = F)
mics <- read.csv('UNICEF_MICS_wash_geospatial_ALLDATA.csv', stringsAsFactors = F)

######## Diagnosing lat/long issues ################
survey_name <- c('dhs','ais','mis','mics')
data <- list(dhs, ais, mis, mics)
for (i in 1:4) {
  long <- data[[i]][!is.na(data[[i]]$longitude),]$longitude
  lat <- data[[i]][!is.na(data[[i]]$latitude),]$latitude
  print(paste('survey:', survey_name[i],
              'lat:', length(lat),
              'long:', length(long)))
  
}

#####################################################


####################################################################################
###################                                   ##############################
###################            WATER                  ##############################
###################                                   ##############################
####################################################################################

# Trim data for access to water
ais_w <- select(ais, latitude, longitude, w_source_drink, w_source_other, year_start,
                survey_name, country, mins_ws, shapefile, admin_1, urban)

dhs_w <- select(dhs, latitude, longitude, w_source_drink, w_source_other, year_start,
                survey_name, country, mins_ws, shapefile, admin_1, urban)

mis_w <- select(mis, latitude, longitude, w_source_drink, w_source_other, year_start,
                survey_name, country, mins_ws, shapefile, admin_1, urban)

mics_w <- select(mics, latitude, longitude, w_source_drink, w_source_other, year_start,
                 survey_name, country, mins_ws, shapefile, admin_1, urban)

w_master <- rbind(ais_w, dhs_w, mis_w, mics_w)

w_master_pt <- filter(w_master, !is.na(longitude))
w_master_pt <- filter(w_master, !is.na(latitude))

# save files to clean variables for drinking water
w_master_pt_drink <- unique(w_master_pt$w_source_drink)
w_master_pt_other <- unique(w_master_pt$w_source_other)

write.csv(w_master_pt_drink, file = 'C:/Users/adesh/Documents/WASH/drink_var.csv')
write.csv(w_master_pt_other, file = 'C:/Users/adesh/Documents/WASH/w_other_var.csv')
write.csv(w_master_pt, file = 'C:/Users/adesh/Documents/WASH/w_master_12_13.csv')

# Aggregate water up to the cluster level
water_clusters <- w_master_pt %>% group_by(latitude, longitude, w_source_drink, w_source_other,
                                          year_start, survey_name, country, urban) %>% summarize(N = n())
water_clusters$psu <- 1

# import water categorization
water_definitions <- read.csv('C:/Users/adesh/Documents/WASH/water_monitoring.csv', stringsAsFactors = F)
w_other_definitions <- read.csv('C:/Users/adesh/Documents/WASH/water_other_source.csv', stringsAsFactors = F)
#### apply mdg and sdg sanitation categorizations ####
# MDG
water_clusters$mdg <- NA
for (i in 1:length(water_definitions$x)) {
  water_clusters$mdg[which(water_clusters$w_source_drink == water_definitions$x[i])] <- water_definitions$mdg[i]
}

water_clusters$mdg_other_w <- NA
for (i in 1:length(water_definitions$x)) {
  water_clusters$mdg_other_w[which(water_clusters$w_source_other == w_other_definitions$x[i])] <- w_other_definitions$mdg[i]
}

# Check which values of w_source_drink haven't been categorized
unique(water_clusters$w_source_drink[which(water_clusters$mdg == "")])

# Temporarily be sure about categories
water_clusters$mdg[which(water_clusters$mdg == "unimproved*")] <- "unimproved"
water_clusters$mdg[which(water_clusters$mdg == "improved*")] <- "improved"
water_clusters$mdg[which(water_clusters$mdg == "surface*")] <- "surface"
water_clusters$mdg[which(water_clusters$mdg == "piped*")] <- "piped"

water_clusters$mdg_other_w[which(water_clusters$mdg_other_w == "unimproved*")] <- "unimproved"
water_clusters$mdg_other_w[which(water_clusters$mdg_other_w == "improved*")] <- "improved"
water_clusters$mdg_other_w[which(water_clusters$mdg_other_w == "surface*")] <- "surface"
water_clusters$mdg_other_w[which(water_clusters$mdg_other_w == "piped*")] <- "piped"

water_clusters$mdg[which(water_clusters$mdg == "bottled" &
                         water_clusters$mdg_other_w == "improved")] <- "improved"
water_clusters$mdg[which(water_clusters$mdg == "bottled" &
                           water_clusters$mdg_other_w == "piped")] <- "improved"
water_clusters$mdg[which(water_clusters$mdg == "bottled")] <- "unimproved"
# Drop uncategorized observations
water_clusters <- filter(water_clusters, mdg != "")

#write temp csv to show data coverage
# write.csv(water_clusters, "C:/Users/adesh/Documents/WASH/water_cov.csv")
# w_pt_countries <- count(water_clusters, survey_name, country, year_start)
# write.csv(w_pt_countries, "C:/Users/adesh/Documents/WASH/water_survey_cov.csv")

# Split data for binomial models
water_clusters_piped <- water_clusters
water_clusters_piped$w_piped <- ifelse(water_clusters$mdg == "piped", 1, 0)
water_clusters_piped <- select(water_clusters_piped, -N)
water_clusters_piped <- water_clusters_piped %>% group_by(latitude, longitude, year_start,
                                                          survey_name, country, psu, w_piped, urban) %>%
                        summarize(N = n())
write.csv(water_clusters_piped, 'C:/Users/adesh/Documents/WASH/w_pipe.csv')

water_clusters_imp <- water_clusters
water_clusters_imp$w_imp <- ifelse(water_clusters$mdg == "improved", 1, 0)
water_clusters_imp <- select(water_clusters_imp, -N)
water_clusters_imp <- water_clusters_imp %>% group_by(latitude, longitude, year_start,
                                                          survey_name, country, psu, w_imp) %>%
  summarize(N = n())
write.csv(water_clusters_imp, 'C:/Users/adesh/Documents/WASH/w_imp.csv')

water_clusters_unimp <- water_clusters
water_clusters_unimp$w_unimp <- ifelse(water_clusters$mdg == "unimproved", 1, 0)
water_clusters_unimp <- select(water_clusters_unimp, -N)
water_clusters_unimp <- water_clusters_unimp %>% group_by(latitude, longitude, year_start,
                                                          survey_name, country, psu, w_unimp) %>%
  summarize(N = n())
write.csv(water_clusters_unimp, 'C:/Users/adesh/Documents/WASH/w_unimp.csv')

water_clusters_surface <- water_clusters
water_clusters_surface$w_surface <- ifelse(water_clusters$mdg == "surface", 1, 0)
water_clusters_surface <- select(water_clusters_surface, -N)
water_clusters_surface <- water_clusters_surface %>% group_by(latitude, longitude, year_start,
                                                          survey_name, country, psu, w_surface) %>%
  summarize(N = n())
write.csv(water_clusters_surface, 'C:/Users/adesh/Documents/WASH/w_surface.csv')
################### Point data Coverage #############################################
# 
# w_xy <- select(w_master_pt, latitude, longitude, year_start)
# w_xy <- distinct(w_xy)
# 
# w_xy_1 <- filter(w_xy, year_start <= 2000)
# w_xy_2 <- filter(w_xy, year_start > 2000 & year_start <= 2005)
# w_xy_3 <- filter(w_xy, year_start > 2005 & year_start <= 2010)
# w_xy_4 <- filter(w_xy, year_start > 2010)
# 
# 
# write.csv(w_xy, file = 'C:/Users/adesh/Documents/WASH/data_cov.csv')
# write.csv(w_xy, file = 'C:/Users/adesh/Documents/WASH/data_cov_00.csv')
# write.csv(w_xy, file = 'C:/Users/adesh/Documents/WASH/data_cov_05.csv')
# write.csv(w_xy, file = 'C:/Users/adesh/Documents/WASH/data_cov_10.csv')
# write.csv(w_xy, file = 'C:/Users/adesh/Documents/WASH/data_cov_15.csv')
#
####################################################################################
###################                                   ##############################
###################            SANITATION             ##############################
###################                                   ##############################
####################################################################################

# Trim data for access to sanitation
ais_s <- select(ais, latitude, longitude, t_type, shared_san, year_start,
                survey_name, country, shapefile)

dhs_s <- select(dhs, latitude, longitude, t_type, shared_san, year_start,
                survey_name, country, shapefile)
dhs_s <- rename(dhs_s, year_start = year_start)

mis_s <- select(mis, latitude, longitude, t_type, shared_san, year_start,
                survey_name, country, shapefile)

mics_s <- select(mics, latitude, longitude, t_type, shared_san, year_start,
                 survey_name, country, shapefile)



s_master <- rbind(ais_s, dhs_s, mis_s, mics_s)

s_master_pt <- filter(s_master, !is.na(longitude))
s_master_pt <- filter(s_master, !is.na(latitude))

# save files to clean variables for drinking water
s_master_pt_toilet <- unique(s_master_pt$t_type)
 
# write.csv(s_master_pt_toilet, file = 'C:/Users/adesh/Documents/WASH/toilet_var.csv')
# write.csv(s_master_pt, file = 'C:/Users/adesh/Documents/WASH/s_master_12_13.csv')

# Aggregate sanitation up to the cluster level
sani_clusters <- s_master_pt %>% group_by(latitude, longitude, t_type, shared_san,
                 year_start, survey_name, country) %>% summarize(N = n())
sani_clusters$psu <- 1

# import sanitation categorization
sani_definitions <- read.csv('C:/Users/adesh/Documents/WASH/sani_monitoring.csv', stringsAsFactors = F)

#### apply mdg and sdg sanitation categorizations ####
# MDG
sani_clusters$mdg <- NA
for (i in 1:length(sani_definitions$x)) {
  sani_clusters$mdg[which(sani_clusters$t_type == sani_definitions$x[i])] <- sani_definitions$mdg[i]
}

# Check which values of t_type haven't been categorized
# unique(sani_clusters$t_type[which(sani_clusters$mdg == "")])

# Temporarily be sure about categories
sani_clusters$mdg[which(sani_clusters$mdg == "unimproved*")] <- "unimproved"
sani_clusters$mdg[which(sani_clusters$mdg == "improved*")] <- "improved"

# Recategorize shared improved into its own category
sani_clusters$shared_san[which(sani_clusters$shared_san == "missing")] <- NA
sani_clusters$shared_san <- as.numeric(sani_clusters$shared_san)
sani_clusters$mdg[which(sani_clusters$shared_san == 1 &
                        sani_clusters$mdg == "improved")] <- "shared"
sani_clusters$mdg[which(is.na(sani_clusters$shared_san) &
                          sani_clusters$mdg == "improved")] <- ""

# Drop uncategorized observations
sani_clusters <- filter(sani_clusters, mdg != "")

#write temp csv to show data coverage
write.csv(sani_clusters, "C:/Users/adesh/Documents/WASH/water_cov.csv")
s_pt_countries <- count(sani_clusters, survey_name, country, year_start)
write.csv(s_pt_countries, "C:/Users/adesh/Documents/WASH/water_survey_cov.csv")

# Split data for binomial models
sani_clusters_imp <- sani_clusters
sani_clusters_imp$sani_imp <- ifelse(sani_clusters$mdg == "improved", 1, 0)
sani_clusters_imp <- select(sani_clusters_imp, -N)
sani_clusters_imp <- sani_clusters_imp %>% group_by(latitude, longitude, year_start, survey_name,
                           country, psu, sani_imp) %>% summarize(N = n())
write.csv(sani_clusters_imp, 'C:/Users/adesh/Documents/WASH/sani_imp.csv')

sani_clusters_unimp <- sani_clusters
sani_clusters_unimp$sani_unimp <- ifelse(sani_clusters$mdg == "unimproved", 1, 0)
sani_clusters_unimp <- select(sani_clusters_unimp, -N)
sani_clusters_unimp <- sani_clusters_unimp %>% group_by(latitude, longitude, year_start, survey_name,
                                                    country, psu, sani_unimp) %>% summarize(N = n())
write.csv(sani_clusters_unimp, 'C:/Users/adesh/Documents/WASH/sani_unimp.csv')

sani_clusters_shd <- sani_clusters
sani_clusters_shd$sani_shd <- ifelse(sani_clusters$mdg == "shared", 1, 0)
sani_clusters_shd <- select(sani_clusters_shd, -N)
sani_clusters_shd <- sani_clusters_shd %>% group_by(latitude, longitude, year_start, survey_name,
                                                    country, psu, sani_shd) %>% summarize(N = n())
write.csv(sani_clusters_shd, 'C:/Users/adesh/Documents/WASH/sani_shd.csv')

sani_clusters_od <- sani_clusters
sani_clusters_od$sani_od <- ifelse(sani_clusters$mdg == "open defecation", 1, 0)
sani_clusters_od <- select(sani_clusters_od, -N)
sani_clusters_od <- sani_clusters_od %>% group_by(latitude, longitude, year_start, survey_name,
                                                    country, psu, sani_od) %>% summarize(N = n())
write.csv(sani_clusters_od, 'C:/Users/adesh/Documents/WASH/sani_od.csv')

####################################################################################
###################                                   ##############################
###################             HYGIENE               ##############################
###################                                   ##############################
####################################################################################

###################       Miscellaneous functions     ##############################

# Create data coverage plots for 4 time periods defined in Central MBG for point data
sani_clusters <- ungroup(sani_clusters)
sani_cov <- sani_clusters %>% group_by(latitude, longitude, country,
                                       year_start) %>% summarize(points = n())

sani_cov$year2 <- NA
sani_cov$year2[which(sani_cov$year_start <= 2000)] <- 1997
sani_cov$year2[which(sani_cov$year_start > 2000 &
                       sani_cov$year_start <= 2005)] <- 2002
sani_cov$year2[which(sani_cov$year_start > 2005 &
                       sani_cov$year_start <= 2010)] <- 2007
sani_cov$year2[which(sani_cov$year_start > 2010 &
                       sani_cov$year_start <= 2015)] <- 2012
sani_cov$year2[which(sani_cov$year_start > 2015)] <- 2017

sani_cov2 <- sani_clusters %>% group_by(country, year_start, survey_name) %>% summarize(points = n())


library(ggplot2)

ggplot(data = sani_cov, aes(x = year2, y = country)) + geom_point() + ggtitle("sani cov")


water_clusters <- ungroup(water_clusters)
water_cov <- water_clusters %>% group_by(latitude, longitude, country,
                                         year_start) %>% summarize(points = n())

water_cov$year2 <- NA
water_cov$year2[which(water_cov$year_start <= 2000)] <- 1997
water_cov$year2[which(water_cov$year_start > 2000 &
                        water_cov$year_start <= 2005)] <- 2002
water_cov$year2[which(water_cov$year_start > 2005 &
                        water_cov$year_start <= 2010)] <- 2007
water_cov$year2[which(water_cov$year_start > 2010 &
                        water_cov$year_start <= 2015)] <- 2012
water_cov$year2[which(water_cov$year_start > 2015)] <- 2017

water_cov2 <- water_clusters %>% group_by(country, year_start, survey_name) %>% summarize(points = n())

library(ggplot2)

ggplot(data = water_cov, aes(x = year2, y = country)) + geom_point() + ggtitle("water cov")

