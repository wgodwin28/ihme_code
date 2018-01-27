#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 12/23/2015
# Purpose: Create IER curve figures requested by Rick for the air PM paper
#********************************************************************************************************************************

#----CONFIG----------------------------------------------------------------------------------------------------------------------
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
require(data.table)
require(dplyr)
require(grid)
require(gridExtra)
require(lattice)
require(ggplot2)
require(parallel)
require(RColorBrewer)
require(reshape2)

# set directories
home.dir <- "C:/Users/jfrostad/Desktop/RISK_LOCAL/2013/air_pm/"
  setwd(home.dir)
  
project <- "ier_curve"

data.dir <- paste0("data/", project, "/mean_replicated/")
function.lib <- paste0("code/", project, "/_lib/functions/")
rr.dir <- paste0("output/", project, "/")
graphs.dir <- paste0("graphs/", project, "/air_pm_manuscript/")

# define parameters
prep.rrs <- T
rr.functional.form <- "power2"
rr.data.versions <- c("mean_replicated")
rr.versions <- c("gbd_2013")
#rr.versions <- c("stan", "gbd2010", "no_AS")

# load functions
# function that generates the RRs using the above parameter outputs
rr.functions <- paste0(function.lib, "functional_forms_updated.r")
source(rr.functions, chdir = T)
fobject <- get(rr.functional.form)

# Bring in misc functions
source(paste0(function.lib, "/misc_functions.R"))

# define age lists
# Make a list of all cause-age pairs that we have.
ageCauseLister <- function(cause.code = c("cvd_ihd", "cvd_stroke", "neo_lung", "resp_copd", "lri"),
                           full.age.range = T) {
  
  age.cause <- NULL
  
  for (cause.code in c("cvd_ihd", "cvd_stroke", "neo_lung", "resp_copd", "lri")) {
  
    if (cause.code %in% c("cvd_ihd", "cvd_stroke")) {
      
      # CVD and Stroke have age specific results
      ages <- c(25, 50, 80) 
      all.ages <- seq(25, 80, by=5) # CVD and Stroke have age specific results
      
    } else {
      
      # LRI, COPD and Lung Cancer all have a single age RR (though they reference different ages...)
      ages <- c(99) 
      all.ages <- c(99)
    }
    
    if (full.age.range == T) ages <- all.ages
    
    for (age.code in ages) {
      
      age.cause <- rbind(age.cause, c(cause.code, age.code))
      
    }
  }

  return(age.cause)

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
                         y=y.line,
                         color=type.line), 
              linetype = "longdash",
              size=1) +
    geom_ribbon(aes_string(x = x.line,
                           ymin=y.lower, 
                           ymax=y.upper,
                           fill = type.line),
                alpha=0.4) +
    scale_colour_brewer(palette = "Set1") +
    scale_fill_brewer(palette = "Set1") +
    scale_shape_manual(values=c(1,2,5,6),
                       name="exposure type") +      
    scale_size_continuous(guide=F,
                          range=c(2,6)) +  
    labs(title = title.string,
         x = x.lab.string,
         y = y.lab.string) +
    theme_bw()
  
}
#*********************************************************************************************************************************
 
#----RR PREP----------------------------------------------------------------------------------------------------------------------
if (prep.rrs == TRUE) {

  # use function to pull in the age cause list
  # default is all causes all ages, we only want the lite age group for these graphs
  age.cause <- ageCauseLister(full.age.range = F)
  
  # prep objects to hold the RRs
  rr.curves <- list()
  rr.curves.mean <- list()
  
  # loop through and calculate the mean parameters for graphing
  for (age.cause.number in 1:nrow(age.cause)) {
    
    cause.code <- age.cause[age.cause.number, 1]
    age.code <- age.cause[age.cause.number, 2]
    
    for (rr.version in rr.versions) {
      
      # parameters that define these curves are used to generate age/cause specific RRs for a given exposure level
      rr.parameters <- paste0(rr.dir, rr.version, "/rr_curve_", rr.functional.form)
      fitted.parameters <- fread(paste0(rr.parameters, "_", cause.code, "_a", age.code, ".csv"))
      fitted.parameters.mean <- copy(fitted.parameters)
      
      if (rr.version != "gbd2010") {
        
        fitted.parameters[, draw := V1]
      }
      
      else {
        fitted.parameters <- fitted.parameters[draw != "Point Estimate",]
        
      }
      
      fitted.parameters[, alpha.mean := mean(alpha)]
      fitted.parameters[, beta.mean := mean(beta)]
      fitted.parameters[, gamma.mean := mean(gamma)]
      fitted.parameters[, tmred.mean := mean(tmred)]
      fitted.parameters.mean <- copy(fitted.parameters[draw == 1, c("alpha.mean", "beta.mean", "gamma.mean", "tmred.mean"), with=F])
      
      rr.curves[[paste0(cause.code, "_", age.code, "_", rr.version)]] <- fitted.parameters
      rr.curves.mean[[paste0(cause.code, "_", age.code, "_", rr.version)]] <- fitted.parameters.mean
      
    }
    
  }
  
  for (age.cause.number in 1:nrow(age.cause)) {
    
    cause.code <- age.cause[age.cause.number, 1]
    age.code <- age.cause[age.cause.number, 2]
    
    cat("working on", age.code, "-", cause.code, "\n"); flush.console()
    
    test_exposure <- c(seq(1,300,1), seq(350,30000,50))
    draws.required <- 1000
    RR.draw.colnames <- c(paste0("RR_", 1:draws.required))
      
      predictions <- data.table(exposure = test_exposure, 
                                cause_code = cause.code,
                                age = age.code)
      
      # Generate the RRs using the evaluation function
      predictions[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                                    mc.cores = 1,
                                                    function(draw.number) {
                                                      
                                                      fobject$eval(exposure,
                                                                   rr.curves[[paste0(cause.code, "_", age.code, "_", rr.version)]][draw.number, ])
                                                      
                                                    }
                                                    
      )] # Use function object, the exposure, and the RR parameters to calculate PAF
      
      if (age.cause.number == 1) { # if in the first loop, create the object to store all kinds of prediction
        
        all.predictions <- predictions
        
      } else { # otherwise just append the latest predictions onto the all prediction object
        
        all.predictions <- rbindlist(list(all.predictions, predictions)) 
      
      }
  
  }
  
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
 
#----GEN PLOTS----------------------------------------------------------------------------------------------------------------------
# Build the various plots that will go into your quad figure

plot1 <- plotCurves(data.line=all.predictions.summary[cause == "Cardiovascular IHD" & exposure < 125,],
                   x.line="exposure",
                   y.line="RR_mean",
                   y.lower="RR_lower",
                   y.upper="RR_upper",
                   type.line="age",
                   title.string=paste0("Cardiovascular IHD"),
                   x.lab.string="PM2.5",
                   y.lab.string="RR")

plot2 <- plotCurves(data.line=all.predictions.summary[cause == "Cardiovascular Stroke" & exposure < 125,],
                    x.line="exposure",
                    y.line="RR_mean",
                    y.lower="RR_lower",
                    y.upper="RR_upper",
                    type.line="age",
                    title.string=paste0("Cardiovascular Stroke"),
                    x.lab.string="PM2.5",
                    y.lab.string="RR")

plot3 <- plotCurves(data.line=all.predictions.summary[(cause == "COPD" | cause == "Cancer") & exposure < 125,],
                    x.line="exposure",
                    y.line="RR_mean",
                    y.lower="RR_lower",
                    y.upper="RR_upper",
                    type.line="cause",
                    title.string=paste0("Lung Diseases"),
                    x.lab.string="PM2.5",
                    y.lab.string="RR")

plot4 <- plotCurves(data.line=all.predictions.summary[cause == "ALRI" & exposure < 125,],
                    x.line="exposure",
                    y.line="RR_mean",
                    y.lower="RR_lower",
                    y.upper="RR_upper",
                    type.line="cause",
                    title.string=paste0("Lower Respiratory Disease"),
                    x.lab.string="PM2.5",
                    y.lab.string="RR")

plot1.trunc <- plot1 + scale_y_continuous(limits = c(1.0, 2.2))
plot2.trunc <- plot2 + scale_y_continuous(limits = c(1.0, 2.2))
plot3.trunc <- plot3 + scale_y_continuous(limits = c(1.0, 2.2))
plot4.trunc <- plot4 + scale_y_continuous(limits = c(1.0, 2.2))
#********************************************************************************************************************************
 
#----COMBINE PLOTS----------------------------------------------------------------------------------------------------------------------
# now combine them all pretty like
pdf(file.path(graphs.dir, paste0("ier_all_cause.pdf")), width=16, height=8)
  grid.newpage()
  pushViewport(viewport(layout = grid.layout(4, 4)))
  vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
  grid.text(paste0("IER Curves by Cause/Age"), 
            vp = vplayout(1,1:4),
            gp = gpar(fontsize = 18, fontface = "bold"))
  print(plot1, vp = vplayout(1:2, 1:2))  # key is to define vplayout
  print(plot2, vp = vplayout(3:4, 1:2))  # key is to define vplayout
  print(plot3, vp = vplayout(1:2, 3:4))  # key is to define vplayout
  print(plot4, vp = vplayout(3:4, 3:4))  # key is to define vplayout
dev.off()

# now create a version with the y limits truncated to 1-2 for comparability
pdf(file.path(graphs.dir, paste0("ier_all_cause_trunc.pdf")), width=16, height=8)
  grid.newpage()
  pushViewport(viewport(layout = grid.layout(4, 4)))
  vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
  grid.text(paste0("IER Curves by Cause/Age"), 
            vp = vplayout(1,1:4),
            gp = gpar(fontsize = 18, fontface = "bold"))
  print(plot1.trunc, vp = vplayout(1:2, 1:2))  # key is to define vplayout
  print(plot2.trunc, vp = vplayout(3:4, 1:2))  # key is to define vplayout
  print(plot3.trunc, vp = vplayout(1:2, 3:4))  # key is to define vplayout
  print(plot4.trunc, vp = vplayout(3:4, 3:4))  # key is to define vplayout
dev.off()
#********************************************************************************************************************************