#Purpose: Script to run paf calculation function
#source('/snfs2/HOME/wgodwin/risk_factors2/wash/06_pafs/paf_upload.R', echo = T)

#Clear enviro
rm(list=ls())

#Set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

# set functions args
rei <- 83 #wash_water-83, wash_sanitation-84, wash_hygiene-238, air_hap-87
years <- c(1990, 1995, 2000, 2005, 2010, 2017)
draws <- 1000
round_id <- 5
save_results <- T
resume <- F
cluster_project <- "proj_custom_models"

#source in function
source("/home/j/WORK/05_risk/central/code/paf/launch_paf.R")
launch_paf(rei_id = rei, year_id = years, save_results = save_results)
