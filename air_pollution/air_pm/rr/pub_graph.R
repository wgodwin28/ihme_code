# ---HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 12/23/2015
# Updated: 10/27/2016 - Updated for the 2015 curves/publication
# Purpose: Create IER curve figures requested by Rick for the air PM paper
#********************************************************************************************************************************

# ---CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  j_root <- "/home/j" 
  h_root <- "/home/h"
} else { 
  j_root <- "J:"
  h_root <- "H:"
}

# load packages
pacman::p_load(data.table, ggplot2, grid, gridExtra, lattice, parallel, RColorBrewer, reshape2)

# set directories
home.dir <- file.path(j_root, "WORK/05_risk/risks/air_pm/")
  setwd(home.dir)

# define parameters
prep.rrs <- F
rr.data.version <- "7" #rr data version
rr.model.version <- "power2_simsd_source" #rr model version
rr.functional.form <- "power2" #rr functional form
draws.required <- 1000
#***********************************************************************************************************************

# ---IN/OUT-------------------------------------------------------------------------------------------------------------
##in##
rr.dir <- file.path(home.dir, 'data/rr/output/', paste0(rr.data.version, rr.model.version))
tmrel.dir <- file.path(home.dir, 'data/tmrel/')

##out##
graphs.dir <- file.path(home.dir, "products/rr_graphs/")
#***********************************************************************************************************************  

# ---FUNCTIONS----------------------------------------------------------------------------------------------------------  
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
file.path(air.function.dir, "misc.R") %>% source

#general functions#
central.function.dir <- file.path(h_root, "_code/_lib/functions/")
# this pulls the general misc helper functions
file.path(central.function.dir, "misc.R") %>% source
# this pulls the current locations list
file.path(central.function.dir, "get_locations.R") %>% source

# function to create predictions based on a vector of numbers
predictCurves <- function(age.cause.number,
                          rr.curves=all.rr,
                          test.exposure=c(seq(1,300,1), seq(350,30000,50)),
                          ...) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  cat("working on", age.code, "-", cause.code, "\n"); flush.console()
  
  predictions <- data.table(exposure = test.exposure, 
                            cause_code = cause.code,
                            age = age.code)
  
  # Generate the RRs using the evaluation function
  predictions[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                                mc.cores = 1,
                                                function(draw.number) {
                                                  
                                                  fobject$eval(exposure,
                                                               rr.curves[[age.cause.number]][draw.number, ])
                                                  
                                                }
                                                
  )] # Use function object, the exposure, and the RR parameters to calculate PAF
  
}

# curve graphing function
plotCurves <- function(data.line,
                       x.line,
                       y.line,
                       y.lower,
                       y.upper,
                       type.line,
                       x.max.value,
                       title.string,
                       x.lab.string,
                       y.lab.string) {
  
  ggplot(data = data.line) +
    geom_line(aes_string(x=x.line,
                         y=y.line),
              color="green4", 
              linetype = "solid",
              size=1) +
    geom_ribbon(aes_string(x = x.line,
                           ymin=y.lower, 
                           ymax=y.upper),
                fill="chartreuse4",
                alpha=0.4) +
    facet_wrap(~label.factor) +
    scale_size_continuous(guide=F,
                          range=c(2,6)) +  
    labs(title = title.string,
         x = x.lab.string,
         y = y.lab.string) +
    theme_minimal()
  
}
#***********************************************************************************************************************

# ---PREP DATA----------------------------------------------------------------------------------------------------------  
# Make a list of all cause-age pairs that we have.
age.cause <- ageCauseLister(full.age.range = F) 

# Prep the RR curves into a single object, so that we can loop through different years without hitting the files
all.rr <- lapply(1:nrow(age.cause), prepRR, rr.dir=rr.dir)
#***********************************************************************************************************************
 
# ---RR PREP------------------------------------------------------------------------------------------------------------
if (prep.rrs==T) {

  test_exposure <- c(seq(1,300,1))
  RR.draw.colnames <- c(paste0("RR_", 1:draws.required))
  
  all.predictions <- lapply(1:nrow(age.cause), predictCurves) %>% rbindlist
   
  #create summary variables  
  id.variables <- c("exposure", "age", "cause_code")
  all.predictions[,RR_lower := quantile(.SD ,c(.025)), .SDcols=RR.draw.colnames, by=id.variables]
  all.predictions[,RR_mean := rowMeans(.SD), .SDcols=RR.draw.colnames, by=id.variables]
  all.predictions[,RR_upper := quantile(.SD ,c(.975)), .SDcols=RR.draw.colnames, by=id.variables]
  
  #Order columns to your liking
  all.predictions <- setcolorder(all.predictions, c(id.variables,
                                                    "RR_lower", 
                                                    "RR_mean", 
                                                    "RR_upper", 
                                                    RR.draw.colnames))
  
  # Save summary version of PAF output for experts 
  all.predictions.summary <- all.predictions[, c(id.variables,
                                                 "RR_lower",
                                                 "RR_mean",
                                                 "RR_upper"), 
                                             with=F]
  
  # expand cvd_stroke to include relevant subcauses in order to prep for merge to YLDs, using your custom find/replace function
  # first supply the values you want to find/replace as vectors
  old.causes <- c('cvd_ihd',
                  'cvd_stroke',
                  'resp_copd',
                  'neo_lung',
                  'lri')   
  
  replacement.causes <- c('Cardiovascular IHD', 
                          "Cardiovascular Stroke",
                          "COPD",
                          "Cancer",
                          "ALRI")
  
  # then pass to your custom function
  all.predictions.summary <- findAndReplace(all.predictions.summary,
                                            old.causes,
                                            replacement.causes,
                                            "cause_code",
                                            "cause")
  
  # save this section so you dont need to rerun here
  write.csv(all.predictions.summary, paste0(graphs.dir, "/ier_risk_table_all_cause.csv"))
    
} else {
    
    all.predictions.summary <- fread(paste0(graphs.dir, "/ier_risk_table_all_cause.csv"))
    
}
#********************************************************************************************************************************
 
# ---GEN PLOTS----------------------------------------------------------------------------------------------------------------------
# Generate a plot with a panel for each of the relevant cause/ages
exposure.cutoff <- 125 # use the ambient exposure cutoff

#first need to change the labels a bit
all.predictions.summary[cause=="Cancer", cause := "Lung Cancer"]
all.predictions.summary[cause=="COPD", cause := "Respiratory COPD"]
all.predictions.summary[, age_string := paste0("Age: ", age)]
all.predictions.summary[age==99, age_string := "All Ages"]
all.predictions.summary[, label := paste0(cause, " - ", age_string)]
all.predictions.summary[, label.factor := factor(label, 
                                                 levels=c(paste0('Cardiovascular IHD - Age: ', c(25, 50, 80)),
                                                          paste0('Cardiovascular Stroke - Age: ', c(25, 50, 80)),
                                                          "ALRI - All Ages",
                                                          "Lung Cancer - All Ages",
                                                          "Respiratory COPD - All Ages"))]

plot1 <- plotCurves(data.line=all.predictions.summary[exposure < exposure.cutoff,],
                   x.line="exposure",
                   y.line="RR_mean",
                   y.lower="RR_lower",
                   y.upper="RR_upper",
                   type.line="age",
                   title.string=paste0("IER Curves by Cause and Age"),
                   x.lab.string="PM2.5",
                   y.lab.string="RR")
#********************************************************************************************************************************
 
# ---PRINT PLOTS----------------------------------------------------------------------------------------------------------------------
# save the plot to a pdf
pdf(file.path(graphs.dir, paste0("ier_all_cause_ambient_facet.pdf")), width=16, height=8)
  
  print(plot1)
  
dev.off()
#********************************************************************************************************************************