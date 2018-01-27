sa_cntry <- c('venezuela','brazil','colombia','ecuador','peru','bolivia','paraguay')

urban_sa <- list()
for (i in sa_cntry) {
  urban_sa[[length(urban_sa)+1]] <- master_dataset3[grep(i, master_dataset3$country, ignore.case = T),]
}

urban_sa_data <- do.call(rbind, urban_sa)
urban_sa_data <- as.data.frame(urban_sa_data, stringsAsFactors = F)
names(urban_sa_data) <- c('year','country','survey',"w_pipe_u_adj", "w_imp_u_adj", "w_unimp_u_adj", "w_surface_u_adj",
                           "w_pipe_r_adj", "w_imp_r_adj", "w_unimp_r_adj", "w_surface_r_adj", "used_imp_u", 
                           "used_pipe_u", "used_surface_u", "used_imp_r", "used_pipe_r", "used_surface_r", "file","subset")

urban_sa_data$gaul <- 0
urban_sa_data$gaul[grep("venezuela", urban_sa_data$country, ignore.case = T)] <- 263
urban_sa_data$gaul[grep("Bolivia", urban_sa_data$country, ignore.case = T)] <- 33
urban_sa_data$gaul[grep("Colombia", urban_sa_data$country, ignore.case = T)] <- 57
  urban_sa_data$gaul[grep("brazil", urban_sa_data$country, ignore.case = T)] <- 37
  urban_sa_data$gaul[grep("peru", urban_sa_data$country, ignore.case = T)] <- 195
  urban_sa_data$gaul[grep("ecuador", urban_sa_data$country, ignore.case = T)] <- 73
  urban_sa_data$gaul[grep("paraguay", urban_sa_data$country, ignore.case = T)] <- 194
  
rural_sa <- list()
for (i in sa_cntry) {
  rural_sa[[length(rural_sa)+1]] <- master_dataset4[grep(i, master_dataset4$country, ignore.case = T),]
}

rural_sa_data <- do.call(rbind, rural_sa)
rural_sa_data <- as.data.frame(rural_sa_data, stringsAsFactors = F)
names(rural_sa_data) <- c('year','country','survey',"w_pipe_u_adj", "w_imp_u_adj", "w_unimp_u_adj", "w_surface_u_adj",
                          "w_pipe_r_adj", "w_imp_r_adj", "w_unimp_r_adj", "w_surface_r_adj", "used_imp_u", 
                          "used_pipe_u", "used_surface_u", "used_imp_r", "used_pipe_r", "used_surface_r", "file","subset")
rural_sa_data$gaul <- 0
rural_sa_data$gaul[grep("venezuela", rural_sa_data$country, ignore.case = T)] <- 263
rural_sa_data$gaul[grep("Bolivia", rural_sa_data$country, ignore.case = T)] <- 33
rural_sa_data$gaul[grep("Colombia", rural_sa_data$country, ignore.case = T)] <- 57
rural_sa_data$gaul[grep("brazil", rural_sa_data$country, ignore.case = T)] <- 37
rural_sa_data$gaul[grep("peru", rural_sa_data$country, ignore.case = T)] <- 195
rural_sa_data$gaul[grep("ecuador", rural_sa_data$country, ignore.case = T)] <- 73
rural_sa_data$gaul[grep("paraguay", rural_sa_data$country, ignore.case = T)] <- 194

water_avg_pt1 <- water_clusters_piped %>% group_by(urban, year_start, country, survey_name) %>% summarize(avg_N = median(N), pts = n())
water_avg_pt2 <- water_avg_pt1 %>% group_by(urban) %>% summarize(avg_N = median(avg_N), avg_pts = median(pts))

w_pipe_sa <- water_clusters_piped[which(water_clusters_piped$country %in% c('BOL','BRA','PER','ECU','COL','VEN','PRY')),]
c('BOL','BRA','PER','ECU','COL','VEN','PRY') %in% water_clusters_piped$country 

load("C:/Users/adesh/Documents/WASH/ad1_ur_lights_shp.RData")

gaul_codes <- c(195, 33, 194, 37, 73, 263, 57)

cntry_pts <- list()
for (i in gaul_codes) {
cntry_yrs <- unique(urban_sa_data$year[which(urban_sa_data$gaul == i)])
cntry_yr_pts <- list()

  for (j in cntry_yrs) {
    cntry_svy_yrs <- unique(urban_sa_data$survey[which(urban_sa_data$gaul == i & 
                                                         urban_sa_data$year == j)])
    
    for (k in cntry_svy_yrs) {
    
    urban_shp <- test4[which(test4$ADM0_CODE.1 == i & test4$layer == "urban"),]
    
    pt_test <- spsample(urban_shp, n = 264, type = "random")
    pt_test <- as.data.frame(pt_test)

    pt_test$gaul <- i
    pt_test$yr <- j
    pt_test$cntry <- urban_sa_data$country[which(urban_sa_data$gaul == i)][1]
    pt_test$N <- 100
    pt_test$urban <- 1
    pt_test$survey <- k
    # pt_test$w_pipe <- round(rural_sa_data$w_pipe_u_adj[which(rural_sa_data$survey == k &
    #                                                            rural_sa_data$year == j &
    #                                                            rural_sa_data$gaul == i)])
    
    cntry_yr_pts[[length(cntry_yr_pts)+1]] <- pt_test
    }
  }
    cntry_pts[[length(cntry_pts)+1]] <- do.call(rbind, cntry_yr_pts)
}

sa_resample_pts_u <- do.call(rbind, cntry_pts)


cntry_pts <- list()
for (i in gaul_codes) {
  cntry_yrs <- unique(rural_sa_data$year[which(rural_sa_data$gaul == i)])
  cntry_yr_pts <- list()
  
  for (j in cntry_yrs) {
    cntry_svy_yrs <- unique(urban_sa_data$survey[which(rural_sa_data$gaul == i & 
                                                         rural_sa_data$year == j)])
    
    for (k in cntry_svy_yrs) {
      
    urban_shp <- test4[which(test4$ADM0_CODE.1 == i & test4$layer == "rural_lights"),]
    
    pt_test <- spsample(urban_shp, n = 327, type = "random")
    pt_test <- as.data.frame(pt_test)
    
    pt_test$gaul <- i
    pt_test$yr <- j
    pt_test$cntry <- rural_sa_data$country[which(rural_sa_data$gaul == i)][1]
    pt_test$N <- 100
    pt_test$urban <- 0
    pt_test$survey <- k
    # pt_test$w_pipe <- round(rural_sa_data$w_pipe_u_adj[which(rural_sa_data$survey == k &
    #                                                      rural_sa_data$year == j &
    #                                                    rural_sa_data$gaul == i)])
    
    
    cntry_yr_pts[[length(cntry_yr_pts)+1]] <- pt_test
    }
  }
  cntry_pts[[length(cntry_pts)+1]] <- do.call(rbind, cntry_yr_pts)
}

sa_resample_pts_r <- do.call(rbind, cntry_pts)

sa_resample_pts <- do.call(rbind, list(sa_resample_pts_r, sa_resample_pts_u))

write.csv(sa_resample_pts, "C:/Users/adesh/Documents/WASH/sa_resample_pts.csv")