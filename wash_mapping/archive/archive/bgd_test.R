library(dplyr)
library(data.table)

data <- read.csv('J:/WORK/11_geospatial/02_processed data/WASH/extractions_1_19_17/WaSH.csv', stringsAsFactors = F)
data <- water_clusters_piped
data <- mutate(data, unique_cluster = paste(ihme_loc_id, year_start, survey_name, strata, psu))

data_gps <- filter(data, !is.na(lat))
data_gps <- filter(data_gps, !is.na(long))
gps_no_hh <- unique(data_gps$unique_cluster[which(is.na(data_gps$hh_size))])
data_gps_hh <- data_gps[which(!(data_gps$unique_cluster %in% gps_no_hh)),]
data_gps_hh_wins <- data_gps_hh %>% group_by(ihme_loc_id, year_start, 
                                             survey_name, strata, w_piped, psu, urban, lat, long) %>% summarize(n = sum(hh_size))
data_gps_hh_wins <- filter(data_gps_hh_wins, w_piped  == 1)
data_gps_hh <- data_gps_hh %>% group_by(ihme_loc_id, year_start, 
                                        survey_name, strata, psu, urban, lat, long) %>% summarize(weight = sum(hh_size))
data_gps_hh_test <- left_join(data_gps_hh, data_gps_hh_wins, by = c("ihme_loc_id", "year_start", 
                                                                    "survey_name", "strata", "psu", "urban", "lat", "long"))
data_gps_hh_test$n[which(is.na(data_gps_hh_test$n))] <- 0

pts_00 <- filter(data_gps_hh_test, year_start <= 2000) 
pts_05 <- filter(data_gps_hh_test, year_start > 2000 & year_start <= 2005)
pts_10 <- filter(data_gps_hh_test, year_start > 2005 & year_start <= 2010)
pts_15 <- filter(data_gps_hh_test, year_start > 2010)

write.csv(pts_00, 'C:/Users/adesh/Documents/pts_00.csv')
write.csv(pts_05, 'C:/Users/adesh/Documents/pts_05.csv')
write.csv(pts_10, 'C:/Users/adesh/Documents/pts_10.csv')
write.csv(pts_15, 'C:/Users/adesh/Documents/pts_15.csv')

data_svyshp <- filter(data, is.na(lat))
data_svyshp <- filter(data_svyshp, is.na(long))
data_svyshp <- filter(data_svyshp, !is.na(pweight))
data_svyshp <- filter(data_svyshp, !is.na(hh_size))
data_svyshp <- filter(data_svyshp, !is.na(shapefile))
data_svyshp <- filter(data_svyshp, !is.na(location_code))
data_svyshp <- data_svyshp %>% group_by(ihme_loc_id, year_start, 
                                        survey_name, strata, psu, urban, w_piped) %>% summarize(n = sum(hh_size))

bgd_pts <- filter(data_gps_hh_test, ihme_loc_id == "BGD")

bgd_pts_00 <- filter(bgd_pts, year_start <= 2000) 
bgd_pts_05 <- filter(bgd_pts, year_start > 2000 & year_start <= 2005)
bgd_pts_10 <- filter(bgd_pts, year_start > 2005 & year_start <= 2010)
bgd_pts_15 <- filter(bgd_pts, year_start > 2010)

bgd_resamp <- filter(data_svyshp, ihme_loc_id == "BGD")

for (i in unique(bgd_resamp$shapefile)) {
  for (j in c(2000,2005,2010,2015)) {
    setwd(paste0("J:/WORK/11_geospatial/05_survey shapefile library/shapefile_urban/",j))
    name <- paste0(i, ".shp")
    shp <- shapefile(name)
    assign(paste(i, j, sep = "_"), shp)
  }
}


pt_list <- list()
for (i in unique(bgd_resamp$unique_cluster)) {
  
  temp <- filter(bgd_resamp, unique_cluster == i)
  if (unique(temp$shapefile) != "admin2013_2") {
  est <- (sum(temp$w_pipe*temp$hh_size*temp$pweight))/sum(temp$pweight)
  year <- ifelse(temp$year_start <= 2000, 2000,
                 ifelse(temp$year_start > 2000 & temp$year_start <= 2005, 2005,
                        ifelse(temp$year_start > 2005 & temp$year_start <= 2010, 2010, 2015)))
  shp <- get(paste(unique(temp$shapefile), year, sep = "_"))
  shp <- shp[shp$gaulcode == unique(temp$location_code) &
               shp$layer == unique(temp$urban),]
  samp_pts <- spsample(shp, length(temp$urban), type = random)
  samp_pts <- as.data.frame(samp_pts)
  samp_pts$est <- est
  samp_pts$n <- mean((temp$hh_size))
  samp_pts$year <- year
  samp_pts$country <- "BGD"
  pt_list[[length(pt_list) + 1]] <- samp_pts
  }
}

ifelse(temp$year_start <= 2000, 2000,
  ifelse(temp$year_start > 2000 & temp$year_start <= 2005, 2005,
         ifelse(temp$year_start > 2005 & temp$year_start <= 2010, 2010, 2015)))

