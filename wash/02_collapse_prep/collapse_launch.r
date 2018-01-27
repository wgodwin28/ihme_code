
###########################################################
### Author: Zane Rankin
### Date: 1/26/2015
### Project: ubCov
### Purpose: Collapse ubcov extraction output for anemia
### DOCUMENTATION: https://hub.ihme.washington.edu/display/UBCOV/Collapse+Documentation
###########################################################

###################
### Setting up ####
###################

rm(list=ls())

#Load libraries using pacman 
library(pacman)
p_load(data.table, readstata13, haven, dplyr, survey, binom, RMySQL, xlsx)



## Set root filepaths
# input_root <- "J:/temp/wgodwin/wash_exposure/00_hap"
input_root <- "J:/temp/wgodwin/wash_exposure/01_shared_san"
#output_root <- "J:/temp/wgodwin/wash_exposure/03_upload/01_hap"
output_root <- "J:/temp/wgodwin/wash_exposure/03_upload"

## Indicator(s) of interest
vars <- "hap_expose"
vars <- c("improved_water", "piped_mod", "improved_san", "sewer",
          "hap_expose", "handwashing", "wash_water_itreat_piped", 
          "wash_water_itreat_imp", "wash_water_itreat_unimp",
          "wash_water_tr_piped", "wash_water_tr_imp", "wash_water_tr_unimp")
strat_vars <- c("nid", "ihme_loc_id", "year_start", "year_end")

#Give a sensible name
output_name <- paste("ubcov_tabulation", Sys.info()["user"], Sys.Date(), sep = "_")

######################################################################################################################
#Load functions
ubcov_central_repo <- ifelse(Sys.info()["user"] == "wgodwin", "H:/ubcov_central", "J:/WORK/01_covariates/common/ubcov_central")
#ubcov_central_repo <- "J:/WORK/01_covariates/common/ubcov_central"
#ubcov_central_repo <- "J:/temp/syadgir/collapse_code"
source(paste0(ubcov_central_repo, "/functions/collapse/collapse.R"))
source(paste0(ubcov_central_repo, "/functions/collapse/format_epi.R"))
source(paste0(ubcov_central_repo, "/functions/collapse/collapse_master.R"))

###########SIMON'S TROUBLESHOOT#############
input_root <- "J:/WORK/05_risk/risks/metab_bmi/data/exp/new_ubcov/24Jan2017/AUS"
output_root <- "J:/temp/wgodwin/wash_exposure/03_upload/02_trouble"
vars <- c("bmi","overweight")

#vars <- c("current_drinker", "abstainer")
runtime <- system.time(
out <- collapse_ubcov(
    
  #REQUIRED 
  vars = vars,
  stratify_by = c("nid", "ihme_loc_id", "year_start", "year_end", "sex", "age_group_id"),
  drop_lonely=T,
  keep_metadata = T,
  #stratify_by=c("nid", "ihme_loc_id", "year_start", "year_end", "sex"),
  #OPTIONAL 
  #cut_custom_age=T,
  #cut_ages=c(seq(0,100,5), 130),
  missing_age= "drop",
  #allow_missing_vars = TRUE,
  test_file = "AUS_DIABETES_OBESITY_AND_LIFESTYLE_STUDY_person_AUS_1999_826.dta"
    
  )
)
###############################################

############MY COLLAPSE###############
vars <- c("improved_san", "sewer",
          "hap_expose")
runtime <- system.time(
  #Call function 
  out <- collapse_ubcov(
    
    #REQUIRED 
    vars = vars, allow_missing_vars = T, stratify_by <- strat_vars, drop_lonely = T,

    #OPTIONAL 
    output_name = output_name
    #test_file = "KEN/MACRO_MIS_2015.dta"
  )
)

upload <- out$upload
warnings <- out$warnings

print(paste("PLEASE CHECK BOTH YOUR UPLOAD AND WARNINGS FILES in R or saved csvs in ", output_root))

warnings








