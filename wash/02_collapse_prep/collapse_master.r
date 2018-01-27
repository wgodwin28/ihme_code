###########################################################
### Author: Zane Rankin
### Date: 1/26/2015
### Project: ubCov
### Purpose: Collapse ubcov extraction output for anemia
### DOCUMENTATION: https://hub.ihme.washington.edu/display/UBCOV/Collapse+Documentation
###########################################################
#source("/home/j/temp/wgodwin/wash_exposure/collapse_template2.r", echo=T)
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
#pacman::p_load(data.table, haven, dplyr, survey)
library(data.table);library(haven);library(dplyr);library(survey)

## Load Functions
ubcov_central <- paste0(j, "/WORK/01_covariates/common/ubcov_central/")
setwd(ubcov_central)
source("modules/collapse/launch.r")

######################################################################################################################

## Settings

topic <- "wash" ## Subset config.csv
config.path <- paste0(j, "temp/wgodwin/wash_exposure/config.csv") ## Path to config.csv
parallel <- F ## Run in parallel?
slots <- 1 ## How many slots per job (used in mclapply) | Set to 1 if running on desktop
logs <- paste0(j, "temp/wgodwin/wash_exposure/logs") ## Path to logs
cluster_proj <- 'proj_custom_models'
## Launch collapse

df <- collapse.launch(topic=topic, config.path=config.path, cluster_project=cluster_proj, parallel=parallel, slots=slots, logs=logs)

write.csv(df, file = paste0(j, "/temp/wgodwin/wash_exposure/03_upload/tabulation_NSSO.csv"), row.names = F)
#df2 <- copy(df)
#load.settings(config.path)