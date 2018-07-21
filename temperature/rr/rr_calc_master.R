#Purpose: Master script to launch code that runs RR regression by age, cause
#source('/snfs2/HOME/wgodwin/temperature/risk/rr_calc_master.R', echo = T)
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  j <- "/home/j/" 
  h <- "/homes/wgodwin/"
} else {
  j <- "J:/"
  h <- "H:/"
}

#load libraries
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
pacman::p_load(data.table, parallel, magrittr, raster, stringr, RMySQL, snow, ncdf4, feather, rgdal, pglm, haven)

#cluster settings
r.shell <- file.path(h, "risk_factors2/air_pollution/air_hap/rr/_lib/R_shell.sh")
project <- "proj_custom_models"
cores.provided <- 8
sge.output.dir <- "-o /share/temp/sgeoutput/wgodwin/output/ -e /share/temp/sgeoutput/wgodwin/errors/ "

#Job settings
causes <- "n_cvd_ihd"
age <- "all"
rr.model <- "cubspline.sdi"
version <- 1 #First run through

#Cause loop
for (cause in causes) {
  # Launch jobs
  jname <- paste0("rr_calc_", cause)
  sys.sub <- paste0("qsub ", project, sge.output.dir, " -N ", jname, " -pe multi_slot ", cores.provided*2, " -l mem_free=", cores.provided*4, "G")
  args <- paste(cause,
                rr.model,
                cores.provided,
                version,
                age)
  
  #launch
  system(paste(sys.sub, r.shell, calc.script, args))
}