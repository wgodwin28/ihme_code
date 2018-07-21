#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: WG
# Date: 02/16/2018
# Purpose: Run save results on PAFs for temperature
# source("/homes/wgodwin/temperature/paf/save/save_results_master.R", echo=T)
#********************************************************************************************************************************

#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  
  j <- "/home/j/" 
  h <- "/homes/wgodwin/"
  
} else { 
  
  j <- "J:"
  h <- "H:"
  
}

#Set paths
code.dir <- paste0(h, 'temperature/paf/save/')
sr.script <- paste0(code.dir, "save_results_child.R")
r.shell <- file.path(h, "risk_factors2/air_pollution/air_hap/rr/_lib/R_shell.sh")

#Set project and error log paths
project <- "-P proj_paf "
sge.output.dir <- "-o /share/temp/sgeoutput/wgodwin/output/ -e /share/temp/sgeoutput/wgodwin/errors/ "
version <- 20
dir <- paste0("/share/epi/risk/temp/temperature/paf/", version)
cores.provided <- 40
best <- T
description <- "PAFs with BRA RR curves for most causes"
years <- c("1990", "2005", "2017")

#Loop through heat and cold PAFs
for(i in 0:1){
  me_id <- ifelse(i == 0, 20262, 20263)
  sr.dir <- paste0(dir, "/save_results/", i)
  args <- paste(i, sr.dir, me_id, best, description)
  jname <- paste0("save_results_", version, "_heat_", i)
  sys.sub <- paste0("qsub ", project, sge.output.dir, " -N ", jname, " -pe multi_slot ", cores.provided)
  system(paste(sys.sub, r.shell, sr.script, args))
}
