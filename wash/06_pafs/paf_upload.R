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

#job id 191325702

# set functions args
rei <- 84 #wash_water-83, wash_sanitation-84, wash_hygiene-238, air_hap-87
#years <- c(1990, 1995, 2000, 2005, 2007, 2010, 2017)
years <- seq(1990, 2017)
draws <- 1000
round_id <- 5
save_results <- T
resume <- F
cluster_project <- "proj_paf"

#source in function
source("/share/code/risk/paf/launch_paf.R")
launch_paf(rei_id = rei, year_id = years, save_results = save_results, cluster_proj = cluster_project, resume = resume)
