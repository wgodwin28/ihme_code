#Purpose: Launcher script for running models by cause and municipality

# LOAD THE PACKAGES
rm(list=ls())
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
library(dlnm) ; library(mvmeta) ; library(splines) ; library(tsModel) ; library(data.table) # ; library(lubridate)

#Set j and toggle
j <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
location <- "mex"
country <- "Mexico"
bycause <- F
bylocation <- T

#Set directories
cod.dir <- paste0(j, "temp/wgodwin/temperature/cod/", location, "/causes/")
map.dir <- paste0(j, "temp/wgodwin/temperature/cod/", location, "/")
diag.dir <- paste0(j, "temp/wgodwin/temperature/gasparrini_dlnm/diagnostics/", location, "/")

#Cause vector
causes <- c("cvd", "diarrhea","resp", "resp_copd", "resp_asthma", 
            "lri", "ntd_dengue", "zoonotic", "resp_allergic",
            "malaria", "mental", "skin", "inj", "sids", "ntd_guinea",
            "cvd_ihd", "ntd_foodborne", "varicella")

#Set paths
if(bycause){
  paths <- list.files(paste0(cod.dir, "causes"), full.names = T)
  #paths <- lapply(causes, function(x){grep(x, paths, value = T)})
  paths <- grep(".csv", paths, value = T)
  
  # METADATA FOR causes and paths
  cause.meta <- data.table(
    cause = sort(causes),
    path = sort(paths)
  )
}else{
  causes <- "cvd_ihd"
  path <- paste0(cod.dir, "cvd_ihd_cod_temp.csv")
}

#Read in and save muni_ids in a vector
admin2 <- fread(paste0(map.dir, "admin2_map.csv"))
states <- admin2[, unique(location_id)]
cause.meta <- fread(paste0(diag.dir, "cause.meta.csv"))

#Versioning
version <- 1 # first run, with subset of causes
version <- 2
version <- 3 #run with neg binomial instead of quasi-possion
version <- 4 #offset implementation, plus sdi in model
version <- 5 #running by muni and doing meta-analysis...
version <- 6 #deleted sdi as predictor from formula

##Set qsub objects
cores <- 1
rshell <- "/homes/wgodwin/risk_factors2/air_pollution/air_hap/rr/_lib/R_shell.sh"
project <- "-P proj_custom_models"
rscript <- "/homes/wgodwin/temperature/risk/dlnm/01.firststage_bylocation_child.R"
sge.output.dir <- "-o /share/temp/sgeoutput/wgodwin/output/ -e /share/temp/sgeoutput/wgodwin/errors/"
diag.dir <- paste0(diag.dir, "/", version)
dir.create(diag.dir)
ehi <- T
distr_lag <- F

#Launch-looping over cause and municipality
for(acause in causes){
  for(state in states) {
    if(bycause){path <- cause.meta[cause == acause, path]}
    args <- paste(path, acause, diag.dir, location, country, state, ehi)
    jname.arg <- paste0("-N temp_",state, "_", acause, "_", version)
    mem.arg <- paste0("-l mem_free=", cores*2, "G")
    slot.arg <- paste0("-pe multi_slot ", cores)
    sys.sub <- paste("qsub", project, sge.output.dir, jname.arg, mem.arg, slot.arg)
    system(paste(sys.sub, rshell, rscript, args))
  }
}