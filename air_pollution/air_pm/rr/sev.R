#----HEADER-------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 05/06/2016
# Project: RF: air_pm
# Purpose: save maxRR for each age/cause to calculate the SEV
# Source: source("/homes/jfrostad/_code/risks/air_pm/rr/sev.R")
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
output.version <- 5 #first version run of the maxRRs for sev, should match output v5 for PAF
output.version <- 11 #version of SEV with updated exposure and updated IER data, should match submission version of PAF
#***********************************************************************************************************************

#----IN/OUT-------------------------------------------------------------------------------------------------------------
#IER curve settings
rr.data.version <- 7
rr.model.version <- "power2_simsd_source"
rr.functional.form <- "power2"
rr.dir <- file.path(home.dir, 'data/rr/output/', paste0(rr.data.version, rr.model.version))

cores.provided <- 50

draws.required <- 500

#exposure
grid.version <- 16
exp.dir <-  file.path("/share/gbd/WORK/05_risk/02_models/02_results/air_pm/exp/gridded", grid.version)
#exposure <- file.path(exp.dir, "all.csv") %>% fread #no longer saving gridded exp in csvs
file.path(exp.dir, "all_grids.Rdata") %>% load(envir = globalenv())


#output max RRs for sev
out.dir <- file.path(home.dir, "products/sev", output.version)
  dir.create(out.dir)
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

#exposure for max RR was calculated using the full gridded dataset, dropping all pixels with <100 population 
#exposure <- 123.8658 #p99 for the full gridded dataset, all pixels pop>100
#exposure <- 2052.55 #max hap exposure (for nicaraguan women)

#we decided to calculate the max RR using only grids with > 100 population
# cut out the unpopulated regions to control for high pm in desert dust storms
exposure.pop <- pollution[!is.na(pop) & pop>100]
setkeyv(exposure.pop, c('lat','long','year'))

ageWrapper <- function(age.cause.number) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.start <- age.cause[age.cause.number, 2]
  
  print(paste0("Cause:", cause.code, " - Age:", age.start))
  
  # Prep out datasets
  sev <- as.data.table(matrix(as.integer(NA), nrow=1, ncol=4)) 

  # Set up variables
  sev[, 1 := cause.code]
  sev[, 2 := as.numeric(age.start)] 
  
  yearWrapper <- function(this.year) {
    
    message("working on ", this.year)
      #subset exp to this year
      this.exp <- exposure.pop[year==this.year]
      #create index that is each row (each row represent a grid)
      this.exp[,index:= seq_len(.N)]
      setkey(this.exp, index)
      
      #divide into a list where each piece is a chunk of the dt (10 ~equal pieces in total)
      chunks <- split(this.exp, as.numeric(as.factor(this.exp$index)) %% 10)

      #break DT into 1000 grid chunks in order to parallelize this calculation
      chunkWrapper <- function(name, this.chunk) {
        
        #message(name)
        
        evalRR <- function(draw.number,
                           exp,
                           ...) {
          
          #message(draw.number)
          
          ratio * fobject$eval(exp, all.rr[[age.cause.number]][draw.number, ]) - ratio + 1
          
        }
        
        #calculate the RR for each grid using the IER curve for this a/c
        this.chunk[,(rr.colnames) := lapply(1:draws.required, evalRR, exp=median)]
        this.chunk[,rr := rowMeans(.SD), .SDcols=rr.colnames]
        return(this.chunk[, -(rr.colnames), with=F])
        
        #TODO talk to laura about why this way is so slow..
#         #calculate the RR for each grid using the IER curve for this a/c
#         Rprof()
#         this.chunk[, rr := vapply(1:draws.required, evalRR, numeric(1), exp=median) %>% fastMean, by=index]
#         Rprof(append=TRUE)
#         summaryRprof()
        
      }
      
    year.results <- mcmapply(chunkWrapper, names(chunks), chunks, mc.cores=10, SIMPLIFY=FALSE) %>% rbindlist
    
    return(year.results)
      
  }
  
  all.results <- mclapply(as.numeric(exposure.pop$year) %>% unique, yearWrapper, mc.cores=4) %>% rbindlist

  # Calculate maxRR and max PM2.5 using p99
  sev[, 3 := quantile(all.results$rr, probs=c(.99))]
  sev[, 4 := quantile(all.results$median, probs=c(.99))]
  
  setnames(sev, c("cause", "age","rr_p99","pm_p99"))
  
  return(sev)

}

output <- mclapply(1:nrow(age.cause), ageWrapper, mc.cores=1) %>% rbindlist

write.csv(output, file.path(out.dir, "sev_max_rr.csv"))


