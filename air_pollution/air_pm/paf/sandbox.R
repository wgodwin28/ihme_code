#----HEADER-------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 05/06/2016
# Project: RF: air_pm
# Purpose: experimenting with exposure/rr values to return paf
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
pacman::p_load(data.table, ggplot2, magrittr)

# set working directories
home.dir <- file.path(j_root, "WORK/05_risk/risks/air_pm/")
setwd(home.dir)
#***********************************************************************************************************************

#----IN/OUT-------------------------------------------------------------------------------------------------------------
#IER curve settings
rr.data.version <- 5
rr.model.version <- "power2_simsd_source"
rr.functional.form <- "power2"
rr.dir <- file.path(home.dir, 'data/rr/output/', paste0(rr.data.version, rr.model.version))

draws.required <- 250
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

#sandbox
ratio <- 1
age.cause.number <- 26 #copd
exposure <- 65

evalRR <- function(draw.number,
                   ...) {

  ratio * fobject$eval(exposure, 
                       all.rr[[age.cause.number]][draw.number, ]) - ratio + 1

}

RR <- sapply(1:draws.required, evalRR) %>% mean 

message(RR)

message("PAF : ", (RR-1)/RR)

#----PREP OZ------------------------------------------------------------------------------------------------------------------------
# generate draws of tmred
# TODO document this (which study?)
tmred <- data.frame(tmred=runif(draws.required, 33.3, 41.9))

# generate draws of rr from study using mean/ci
# TODO document this (which study?)
rr.mean <- 1.029
rr.lower <- 1.010
rr.upper <- 1.048
rr.sd <- (log(rr.upper)-log(rr.lower))/(2*1.96)
rr.draws <- exp(rnorm(draws.required,log(rr.mean),rr.sd))
#----TEST OZONE RR

# generate RR using draws of ozone, RR, and TMRED with formula rr = base.RR ^ ((exp-tmred)/10) because rr is in terms of 10 ppb ozone
RR <- sapply(1:draws.required, 
             function(draw.number) 
               ifelse(exposure > tmred[draw.number,], 
                      rr.draws[draw.number]^((exposure-tmred[draw.number,])/10),
                      1)) %>% mean# if exposure <= TMRED, there is no elevated risk 

message(RR)
message("PAF OZ: ", (RR-1)/RR)
