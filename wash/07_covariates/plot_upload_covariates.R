## Function to plot covariates at a given location ##
## Creates a set of faceted plots for each age_group_id
## for the covariate values specified at a given location
## If multiple covariates specified, then they show as
## different colors.
## If multiple locations specified, they show as different
## plots. 
## Requires: covariate_id, location_id. 
## Will Godwin, adapted from Chris Troeger, ctroeger@uw.ed

plot_covariates <- function(covariate_id, location_id, outpath){
  if (Sys.info()["sysname"] == "Linux"){
    j <- "/home/j"
  } else {
    j <- "J:"
  } 
  library(ggplot2)
  source(paste0(j,"/temp/central_comp/libraries/current/r/get_covariate_estimates.R"))
  locs <- fread(paste0(j,"/temp/ctroeger/Misc/ihme_loc_metadata_2017.csv"))
  covs <- fread(paste0(j,"/temp/ctroeger/Misc/covariate_ids.csv"))
  
  cdf <- data.table()
  for(i in unique(covariate_id)){
    csub <- get_covariate_estimates(covariate_id=i, location_id=location_id)
    cdf <- rbind(cdf, csub)
  }
  cdf <- fread("/home/j/WORK/05_risk/risks/wash_sanitation/products/sev/1/ready_for_upload_san.csv")
  cdf <- merge(cdf, locs[,.(location_name, location_id)], by = "location_id", all.x = T)
  #cdf <- cdf[sex_id == 2,]
  location_name <- unique(cdf$location_name)
  subcovs <- subset(covs, covariate_id %in% covariate_id)
  
  pdf(outpath)
  for(l in location_name){
    p <- ggplot(data=cdf[location_name==l,], aes(x=year_id, y=mean)) +
      geom_line() + 
      #geom_ribbon(alpha=0.5) + 
      scale_y_continuous("Covariate") + 
      scale_x_continuous("Year") + 
      scale_color_discrete("Covariate") + 
      guides(fill=FALSE) + 
      theme_bw() +
      #facet_wrap(~age_group_id) + 
      ggtitle(paste0("Covariate values in ",l))
    print(paste0("Graphed ", l))
    print(p)
  }
  dev.off()
}

## Example ##
outpath <- "/home/j/WORK/05_risk/risks/wash_sanitation/products/sev/baseline_fill_2017.pdf"
locs <- fread(paste0(j,"/temp/ctroeger/Misc/ihme_loc_metadata_2017.csv"))
locations <- locs[level>3 & parent_id ==180, unique(location_id)]
plot_covariates(covariate_id=863, location_id = locations, outpath = path)

##########################################################
## Creates a set of faceted plots for each age_group_id
## for the covariate values specified at a given location
## for the most recent GBD rounds (2015, 2016, and 2017).
## If multiple locations specified, they show as different
## plots. 
## Requires: covariate_id, location_id. 
## Only one covariate_id allowed in a single function call but 
## can accept multiple location_id s. 
## Chris Troeger, ctroeger@uw.ed
compare_covariates <- function(covariate_id, location_id) {
  if (Sys.info()["sysname"] == "Linux"){
    j <- "/home/j"
  } else {
    j <- "J:"
  } 
  library(ggplot2)
  source(paste0(j,"/temp/central_comp/libraries/current/r/get_covariate_estimates.R"))
  locs <- read.csv(paste0(j,"/temp/ctroeger/Misc/ihme_loc_metadata_2017.csv"))
  covs <- read.csv(paste0(j,"/temp/ctroeger/Misc/covariate_ids.csv"))
  
  cdf <-  get_covariate_estimates(covariate_id=covariate_id, location_id=location_id)
  cdf$round <- "2017"
  cdf_prev <-  get_covariate_estimates(covariate_id=covariate_id, location_id=location_id, gbd_round_id=4)
  cdf_prev$round <- "2016"
  cdf_vold <-  get_covariate_estimates(covariate_id=covariate_id, location_id=location_id, gbd_round_id=3)
  cdf_vold$round <- "2015"
  
  cdf <- rbind(cdf, cdf_prev, cdf_vold)
  cdf <- subset(cdf, sex_id == 2 | sex_id == 3)
  location_name <- unique(cdf$location_name)
  cov_name <- unique(cdf$covariate_name_short)
  
  for(l in location_name){
    p <- ggplot(data=subset(cdf, location_name==l), aes(x=year_id, y=mean_value, ymin=lower_value, ymax=upper_value, 
                              col=round, fill=round)) +
      geom_line() + geom_ribbon(alpha=0.5) + 
      scale_y_continuous("Covariate") + scale_x_continuous("Year") + 
      scale_color_discrete("GBD Round") + guides(fill=FALSE) + theme_bw() +
      facet_wrap(~age_group_id) + 
      ggtitle(paste0("Covariate ", cov_name, " in ",l))
    print(p)
  }
}

## Example ##
#compare_covariates(covariate_id=866, location_id=214)

#Upload covariates
water <- fread("/home/j/temp/wgodwin/save_results/covariates/ready_for_upload_san2.csv")
water <- water[, .(age_group_id, location_id, mean, sex_id, year_id)]
water[, lower_value := mean]
water[, upper_value := mean]
setnames(water, "mean", "mean_value")
write.csv(water, "/home/j/temp/wgodwin/save_results/covariates/ready_for_upload_san.csv", row.names = F)
source("/home/j/temp/central_comp/libraries/current/r/save_results_covariate.R")
save_results_covariate("/home/j/temp/wgodwin/save_results/covariates",
                       "ready_for_upload_water.csv",
                       covariate_id = 863, 
                       mark_best = T,
                       description = "New subnationals duplicated with national for GBD 2017")
##Water sev= 863, sanitation sev = 866
