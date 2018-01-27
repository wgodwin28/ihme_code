#----HEADER-------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 05/06/2016
# Project: RF: air_pm
# Purpose: save RRs for set endpoints to include in an appendix table
# Source: source("/homes/jfrostad/_code/risks/air_pm/rr/endpoint_table.R")
#***********************************************************************************************************************

#----CONFIG-------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# disable scientific notation
options(scipen = 999)

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  
  j_root <- "/home/j" 
  h_root <- "/homes/jfrostad"
  arg <- commandArgs()[-(1:3)]  # First args are for unix use only

} else { 
  
  j_root <- "J:/"
  h_root <- "H:/"
  
}

# load packages, install if missing
pacman::p_load(data.table, ggplot2, magrittr, parallel)

# set working directories
home.dir <- file.path(j_root, "WORK/05_risk/risks/air_pm/")
setwd(home.dir)

#versioning
output.version <- 1 #first version for submission, uses RR datav7 and power2simd_source
#***********************************************************************************************************************

#----IN/OUT-------------------------------------------------------------------------------------------------------------
#IER curve settings
rr.data.version <- 7
rr.model.version <- "power2_simsd_source"
rr.functional.form <- "power2"
rr.dir <- file.path(home.dir, 'data/rr/output/', paste0(rr.data.version, rr.model.version))

cores.provided <- 2

draws.required <- 500

#exposure
exposure <- c(seq(0,30,5), seq(45, 150, 15), seq(200, 600, 100))


#output max RRs for sev
out.dir <- file.path(home.dir, "products/rr_table", output.version)
  dir.create(out.dir, recursive = T)
#*****************************************************************************************************************  

#----FUNCTIONS----------------------------------------------------------------------------------------------------------  
##function lib##
#PAF functions#
paf.function.dir <- file.path(h_root, '_code/risks/air_pm/paf/_lib')  
file.path(paf.function.dir, "paf_helpers.R") %>% source

#RR functions#
rr.function.dir <- file.path(h_root, '_code/risks/air_pm/rr/_lib') 
file.path(rr.function.dir, "functional_forms.R") %>% source
fobject <- get(rr.functional.form)  

#AiR PM functions#
air.function.dir <- file.path(h_root, '_code/risks/air_pm/_lib')
# this pulls the miscellaneous helper functions for air pollution
file.path(air.function.dir, "misc.R") %>% source()

#general functions#
central.function.dir <- file.path(h_root, "_code/_lib/functions/")
# this pulls the general misc helper functions
file.path(central.function.dir, "misc.R") %>% source()
# this pulls the current locations list
file.path(central.function.dir, "get_locations.R") %>% source()
#***********************************************************************************************************************

#----PREP DATA----------------------------------------------------------------------------------------------------------  
# Make a list of all cause-age pairs that we have.
age.cause <- ageCauseLister(full.age.range = T) 
# Prep the RR curves into a single object, so that we can loop through different years without hitting the files extra times.
all.rr <- lapply(1:nrow(age.cause), prepRR, rr.dir=rr.dir)

#currently only calculating the max RR using the mortality ratio
ratio <- 1

#create a vector of column names to store RR estimates
rr.colnames <- paste0("rr_", 1:draws.required)

ageWrapper <- function(age.cause.number) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.start <- age.cause[age.cause.number, 2]
  
  print(paste0("Cause:", cause.code, " - Age:", age.start))
  
  # Prep out datasets
  rr.table <- data.table(cause=cause.code, age=as.numeric(age.start), exposure=exposure)
  setkeyv(rr.table, c('cause', 'age', 'exposure'))

  evalRR <- function(draw.number,
                     exp,
                     ...) {
    
    #message(draw.number)
    
    ratio * fobject$eval(exp, all.rr[[age.cause.number]][draw.number, ]) - ratio + 1
    
  }
        
  #calculate the RR for each grid using the IER curve for this a/c
  rr.table[,(rr.colnames) := lapply(1:draws.required, evalRR, exp=exposure)]
  
  rr.table[, rr_lower := quantile(.SD, c(.025)), .SDcols=rr.colnames, by=c('cause', 'age', 'exposure')]
  rr.table[, rr_mean := rowMeans(.SD), .SDcols=rr.colnames]
  rr.table[, rr_upper := quantile(.SD, c(.975)), .SDcols=rr.colnames, by=c('cause', 'age', 'exposure')]

  rr.table <- rr.table[, -rr.colnames, with=F]

  return(rr.table)

}

output <- mclapply(1:nrow(age.cause), ageWrapper, mc.cores=1) %>% rbindlist

write.csv(output, file.path(out.dir, "ier_appendix_table.csv"))


