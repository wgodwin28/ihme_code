#data <- filter(data, pt_drop|poly_drop)
data1 <- data
data_base <- data1
data_base$hh_size2 <- data_base$hh_size
# Create a list of base and comp data
data_base$hh_dummy <- 1
data_comp <- data_base
data_comp$hh_dummy <- 0
data_comp$hh_size <- 1
data_cw <- list(data_base, data_comp)
hh_dummy_vec <- c(1,0)

# Create 
urban_pt_cw <- list()
urban_poly_cw <- list()
for (j in 0:1) {

  data_cw2_pt <- list()
  data_cw2_poly <- list()
  
  for (i in 1:2) {
    data <- data_cw[[i]]
  
    # Split data into points and polygons
    data_pt <- filter(data, pt_drop & urban == j)
    data_poly <- filter(data, poly_drop & urban == j)

    # Aggregate to cluster level for points
    data_pt <- data_pt %>% group_by(cluster_id) %>% mutate(pweight_total = sum(pweight*hh_size))
    data_pt <- mutate(data_pt, wt_indic = (hh_size*pweight*w_piped)/pweight_total)
    data_pt <- data_pt %>% group_by(cluster_id, lat, long,
                                  year_start, ihme_loc_id) %>% summarize(mbg_indic = sum(wt_indic), weight = sum(hh_size), n2 = sum(hh_size2))
    data_pt <- mutate(data_pt, mbg_indic_bin = floor(weight*mbg_indic))
    data_pt <- rename(data_pt, country = ihme_loc_id)
    data_pt <- rename(data_pt, year = year_start)
    data_pt <- rename(data_pt, prop = mbg_indic)
    data_pt <- rename(data_pt, N = weight)
    data_pt <- as.data.frame(data_pt)
    data_pt <- dplyr::select(data_pt, country, year, prop, N, mbg_indic_bin, lat, long, cluster_id, n2)
    data_pt$point <- 1
  
  # Aggregate to shapefile x location_id level for polygons
  data_poly <- data_poly %>% group_by(poly_id) %>% mutate(pweight_total = sum(pweight*hh_size))
  data_poly <- mutate(data_poly, wt_indic = (hh_size*pweight*w_piped)/pweight_total)
  data_poly <- data_poly %>% group_by(poly_id, shapefile, location_code, ihme_loc_id,
                                      year_start) %>% summarize(mbg_indic = sum(wt_indic), weight = length(unique(cluster_id)), n2 = sum(hh_size2))
  data_poly$latitude <- NA
  data_poly$longitude <- NA
  data_poly$cluster_id <- 1:nrow(data_poly)
  data_poly$N <- data_poly$weight
  data_poly <- mutate(data_poly, mbg_indic_bin = floor(n2*mbg_indic))
  
  # Bind together poly and pt data into one dataset
  data_pt <- dplyr::select(data_pt, country, year, prop, N, n2)
  data_pt <- mutate(data_pt, hh_dummy = hh_dummy_vec[i])
  
  data_poly <- ungroup(data_poly)
  data_poly <- dplyr::select(data_poly, ihme_loc_id, year_start, mbg_indic, N, n2)
  names(data_poly) <- c("country",'year','prop','N','n2')
  data_poly <- mutate(data_poly, hh_dummy = hh_dummy_vec[i])
  
  #model_data_pt <- rbind(data_pt, data_poly)
  data_cw2_pt[[i]] <- data_pt
  data_cw2_poly[[i]] <- data_poly
  }
  urban_pt_cw[[j+1]] <- data_cw2_pt
  urban_poly_cw[[j+1]] <- data_cw2_poly
}

for (j in 1:2) {
  vec_list2 <- list()
  for (i in 1:nrow(data_cw2_pt[[j]])) {
    vec_list <- list()
    ones <- floor(data_pt$n2[i]*data_pt$prop[i])
    zeroes <- data_pt$n2[i] - ones
    vec_list[[i]] <- c(rep(1,ones),rep(0,zeroes))  
  
  }
}

outcome <- unlist(vec_list)
rbind(data.frame(outcome = unlist(vec_list), cov = 1),data.frame(outcome = unlist(vec_list), cov = 0))


cw_model_data_pt <- do.call(rbind, data_cw2_pt)
cw_model_pt <- glm(prop ~ hh_dummy, data = cw_model_data_pt)
cw_model_pt$coefficients

cw_model_data_poly <- do.call(rbind, data_cw2_poly)
cw_model_poly <- glm(prop ~ hh_dummy, data = cw_model_data_poly)
cw_model_poly$coefficients