# clear memory
rm(list=ls())

# runtime configuration
  if (Sys.info()["sysname"] == "Linux") {
    
    j_root <- "/home/j" 
    h_root <- "/homes/wgodwin"
  } else { 
    
    j_root <- "J:"
    h_root <- "H:"
    
  }

# Set formatting objects
  date <- format(Sys.Date(), "%m%d%y")
  in_root <- paste0(j_root, "/WORK/05_risk/risks/air_hap/02_rr/02_output/01_pm_mapping/lit_db/lm_input/")
  out_root <- paste0(j_root, "/WORK/05_risk/risks/air_hap/02_rr/02_output/01_pm_mapping/lit_db/lm_output/")
  source(paste0(j_root, "/temp/central_comp/libraries/current/r/get_location_metadata.R"))
  source(paste0(j_root, "/temp/central_comp/libraries/current/r/get_covariate_estimates.R"))
  source(paste0(j_root, "/temp/central_comp/libraries/current/r/get_ids.R"))
  
# Package Setup
  pack_lib = '/snfs2/HOME/wgodwin/R'
  .libPaths(pack_lib)
  library(data.table)
  library(DT)
  library(plyr)
  library(knitr)
  library(MuMIn)
  library(lme4)
  library(nlme)
  library(arm)
  library(RLRsim)
  library(magrittr)
  library(ggplot2)

#Prep square for predicting out later
  ubcov.function.dir <- file.path(j_root, 'WORK/01_covariates/common/ubcov_central/functions')
  source(file.path(ubcov.function.dir, "utilitybelt/db_tools.r"))
  square <- make_square(319, # update with appropriate location heirarchy
                        1990, 2017,
                        0, 0,
                        covariates="sdi")

#Import updated dataset
  dt <- fread(paste0(in_root, "lmer_input_04202017_india.csv"))

#Format and log transform
  #dt <- dt[measure_std==1 & mean_geom==0 & !(is.na(pm_mean))]
  #dt <- dt[mean_geom==0 & !(is.na(pm_mean))]
  dt[, COuntry := substr(ihme_loc_id,1,3)]
  dt[, log_pm := log(pm_mean)]

#convert stove type from wide to long
  dt <- reshape(dt, 
                   varying = c("traditional", "ics", "gasstove"), 
                   v.names = "stove_yes",
                   timevar = "stovetype", 
                   times = c("traditional", "ics", "gasstove"), 
                   direction = "long")
  
  dt <- dt[stove_yes==1]
  
  dt <- reshape(dt,
                  varying = c("wood", "gas","kerosene","dung","coal","charcoal","crop_residue","biomass"), 
                  v.names = "fuel_yes",
                  timevar = "fueltype", 
                  times = c("wood", "gas","kerosene","dung","coal","charcoal","crop_residue","biomass"),
                  new.row.names=1:(8*nrow(dt)),
                  direction = "long")
  
  dt <- dt[fuel_yes==1]

#Merge on location hierarchy
  #LocationHier <- get_location_metadata(location_set_id = 22) %>% as.data.table()
  LocationHier <- fread(paste0(in_root, "loc_hierarchy.csv"))
  dt <- merge(dt,LocationHier, by=c("location_id","super_region_id","region_id",
                                                       "ihme_loc_id"))

#Make some necessary exclusions
  #dt <- dt[kit==1 & personal_exp==0 & fueltype!="charcoal"]
  dt <- dt[fueltype!="charcoal"]
  dt[, fueltype := as.factor(fueltype)]
  dt[, fueltype := relevel(fueltype, ref='gas')]
  dt <- dt[title != "Relationship between pulmonary function and indoor air pollution from coal combustion among adult residents in an inner-city area of southwest China"]
  dt <- dt[title != "Indoor Air Pollution and Respiratory Illness in Children from Rural India: A Pilot Study"]

# Merge on sdi and generate solid fuel model
  sdi <- get_covariate_estimates(covariate_id = 881)
  dt_sdi <- merge(dt, sdi, by = c("location_id", "year_id"), all.x = T)
  dt_sdi <- dt_sdi[, sdi := mean_value]
  dt_sdi <- dt_sdi[fueltype != c("gas", "kerosene"), solid_fuel := 1]
  dt_sdi <- dt_sdi[solid_fuel != 1, solid_fuel := 0]

# Create vars for monitor location (personal, kitchen, living room) and measure standard
  dt_sdi <- dt_sdi[personal_exp == 1, monitor_loc := "personal"]
  dt_sdi <- dt_sdi[kit == 1 & personal_exp == 0, monitor_loc := "kitchen"]
  dt_sdi <- dt_sdi[kit == 0 & personal_exp == 0, monitor_loc := "living"]
  dt_sdi <- dt_sdi[measure_std==1, measure_std_new := 0]
  dt_sdi <- dt_sdi[measure_std==0, measure_std_new := 1]
  
# Per Matt's suggestion, create new measure std variable that includes cooking/non-cooking designation for non-standard measurements
  dt_sdi[measure_std_new == 0, measure_std_cat := "standard"]
  dt_sdi[measure_std_new == 1 & cooking == 0, measure_std_cat := "no_cooking"]
  dt_sdi[measure_std_new == 1 & cooking == 1, measure_std_cat := "cooking"]
  summary(lm(log_pm ~ sdi + monitor_loc + measure_std_cat, data = dt_sdi))# Model with Matt's suggestion of changing measure std to cooking/non-cooking/standard
  dt_sdi$measure_std_cat <- as.factor(dt_sdi$measure_std_cat)
  dt_sdi[, measure_std_cat := relevel(measure_std_cat, ref='standard')]

#Run model
  #SDI
  mod_test <- lm(log_pm ~ sdi + measure_std_new + region_name:monitor_loc, data = dt_sdi)
  summary(mod_test)
  mod_sdi <- lm(log_pm ~ sdi + monitor_loc + measure_std_new, data = dt_sdi) # Current best model
  square <- square[, measure_std_new := 0]
  #square <- square[, measure_std_cat := "standard"]
  square <- square[, monitor_loc := "personal"]
  preds <- c("mean", "standard_error")
  out <- square[, (preds) := predict(mod_sdi, square[.BY], allow.new.levels=T, se.fit= T), by=c('location_id', 'year_id')]
  out <- out[, predict_pm := exp(mean)]

  #SDI and solid fuel use
    #preds <- c("mean", "standard_error")
    #mod_solid <- lm(log_pm ~ sdi + monitor_loc + measure_std_new + solid_fuel, data = dt_sdi)
    #out <- dt_sdi[, (preds) := predict(mod_solid, dt_sdi[.BY], allow.new.levels=T, se.fit), by=c('location_id', 'year_id')]
    #out <- out[, predict_pm := exp(mean)]
  
# Merge on with location metadata to get ihme_loc_id for map viz
  locations <- get_location_metadata(location_set_id = 22)
  loc_id_dt <- locations[, .(location_id, ihme_loc_id)]
  out <- merge(out, loc_id_dt, by= "location_id", all.x=T)
  write.csv(out, file = paste0(out_root, "lm_map", date,  ".csv"), row.names = F)

#Generate draws from mean and standard error
  draws.required <- 1000
  draw.colnames <- c(paste0("draw_", 1:draws.required))
  out[, index := seq_len(.N)]
  out[, draw.colnames := rnorm(draws.required, mean=mean, sd=standard_error) %>%
       exp %>%
       as.list,
     by="index", with=F]
  write.csv(out, file = paste0(out_root, "lm_pred_", date, ".csv"), row.names = F)
  
##############################################################################################  
###############################Compare draws with last year's#################################
##############################################################################################
  
  dt_2016 <- fread(paste0(j_root, "/WORK/05_risk/risks/air_hap/02_rr/02_output/01_pm_mapping/lit_db/lm_output/gbd_2016/lm_map061617.csv"))
  dt_2016 <- dt_2016[, mean_2016 := exp(mean)]
  dt_2016 <- dt_2016[, c("location_id", "mean_2016")]
  dt_2017 <- fread(paste0(out_root, "lm_map", date, ".csv"))
  dt_2017 <- dt_2017[, mean_2017 := exp(mean)]
  dt_2017 <- dt_2017[year_id == 2017, c("location_id", "year_id", "mean_2017")]
  both <- merge(dt_2017, dt_2016, by="location_id")
  both <- merge(both, locations, by="location_id", all.x=T)
  plot(both$mean_2016, both$mean_2015, main = "PM 2.5 Predictions", 
                                             xlab= "2016 Predictions",
                                             ylab = "2015 Predictions")
  p <- ggplot(both, aes(mean_2016, mean_2015))
  ggplot(both, aes(mean_2016, mean_2015)) + geom_point(size= 1) + geom_text(aes(label=ihme_loc_id), size = 2, vjust=2) + coord_cartesian(xlim=c(0,500), ylim=c(0, 500))

#################
#####Old code####
#################
    #mod_sdi_re <- lmer(log_pm ~ sdi + kit_new + measure_std_new + personal_exp_new + (1 | region_name), data = dt_sdi)
    
    #mod_sdi_fuel <- lm(log_pm ~ sdi + solid_fuel + kit_new + measure_std_new + personal_exp_new, data = dt_sdi)
    
    
    # mod <- lmer(log_pm~fueltype + kit + measure_std + personal_exp + rural + (1 | super_region_name), data=dt)
    # 
    # mod <- lmer(log_pm~fueltype + rural + (1 | super_region_name), data=dt)
    # 
    # 
    # sa_dt <- sa_dt[title != "Daily average exposures to respirable particulate matter from combustion of biomass fuels in rural households of Southern India"]
    # sa_dt <- sa_dt[title != "Exposure assessment for respirable particulates assoicated with household fuel use in rural districts of Andhra pradesh, india"]
    # sa_dt <- sa_dt[title != "Exposures from cooking with biofuels: pollution monitoring and analysis for rural Tamil Nadu, India"]
    # sa_dt <- sa_dt[title != "Indoor Air Pollution and Respiratory Illness in Children from Rural India: A Pilot Study"]
    # sa_dt <- sa_dt[title != "chronic inhalation of biomass smoke is associated with DNA damage in airway cells:involvement of particulate pollutants and benzene"]
    # 
    # sa_ind_dt <- sa_ind_dt[title != "Indoor Air Pollution and Respiratory Illness in Children from Rural India: A Pilot Study"]
    # 
    # d_sa <- density(sa_dt$pm_mean)        
    # plot(d_sa)
    # 
    # d_sa_ind <- density(sa_ind_dt$pm_mean)
    # plot(d_sa_ind)
