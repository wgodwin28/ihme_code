###########################################################
### Author: Zane Rankin
### Date: 1/26/2015
### Project: ubCov
### Purpose: Collapse ubcov extraction output for anemia
### DOCUMENTATION: https://hub.ihme.washington.edu/display/UBCOV/Collapse+Documentation
###########################################################
#source("/snfs2/HOME/wgodwin/risk_factors2/wash/02_collapse_model/01_collapse_master.r", echo=T)
###################
### Setting up ####
###################
rm(list=ls())
os <- .Platform$OS.type
if (os == "windows") {
  j <- "J:/"
  h <- "H:/"
} else {
  j <- "/home/j/"
  user <- Sys.info()[["user"]]
  h <- paste0("/snfs2/HOME/", user)
}

## Load Packages
pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
pacman::p_load(data.table, haven, dplyr, survey)
#library(data.table);library(haven);library(dplyr);library(survey)

## Load Functions
ubcov_central <- paste0(j, "/WORK/01_covariates/common/ubcov_central/")
setwd(ubcov_central)
source("modules/collapse/launch.r")

######################################################################################################################

## Settings

topic <- "wash" ## wash or census
config.path <- paste0(j, "WORK/05_risk/risks/wash_water/data/exp/02_analyses/collapse/collapse_config.csv") ## Path to config.csv
parallel <- F ## Run in parallel?
slots <- ifelse(topic == "wash", 1, 50) ## How many slots per job (used in mclapply) | Set to 1 if running on desktop
logs <- paste0(j, "WORK/05_risk/risks/wash_water/data/exp/02_analyses/logs") ## Path to logs
cluster_proj <- 'proj_custom_models'
## Launch collapse

df <- collapse.launch(topic=topic, config.path=config.path, cluster_project=cluster_proj, parallel=parallel, slots=slots, logs=logs)

#write.csv(df, file = paste0(j, "WORK/05_risk/risks/wash_water/data/exp/02_analyses/collapse/tabulation_NSSO.csv"), row.names = F)
#df2 <- copy(df)
#load.settings(config.path)