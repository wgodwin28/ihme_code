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
  cores <- 10
} else { 
  j_root <- "J:"
  h_root <- "H:"
  cores <- 1
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

data.dir <- file.path("data", project, "mean_replicated")
function.lib <- file.path("code", project, paste0("/example_graphs/_lib/functions"))
rr.dir <- file.path("output", project)
graphs.dir <- file.path("graphs", project, "air_pm_manuscript")

# clean environment with all necessary objects for the analysis
out.environment <- file.path(data.dir, "clean.Rdata")

# define parameters
prep.rrs <- TRUE
rr.functional.form <- "power2"
rr.data.versions <- c("mean_replicated")
rr.versions <- c("gbd_2013", "gbd_2010_website")
#rr.versions <- c("stan", "gbd2010", "no_AS")

# load functions
# function that generates the RRs using the above parameter outputs
rr.functions <- file.path(function.lib, "functional_forms_updated.r")
source(rr.functions, chdir = T)
fobject <- get(rr.functional.form)

# Bring in misc functions
source(file.path(function.lib, "misc_functions.R"))

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

# ratio evaluators: these functions are used to evaluate IER input datapoints using a ratio of zden to znum
# there are 2 functions, one for each version of GBD

gbd2013RatioEval <- function(draw.number,
                             z.num,
                             z.den) {
  
                      (fobject$eval(z.num,
                                    rr.curves[[paste0(cause.code, "_", age.code, "_gbd_2013")]][draw.number, ])
                       /
                         fobject$eval(z.den,
                                      rr.curves[[paste0(cause.code, "_", age.code, "_gbd_2013")]][draw.number, ]))
                      
                    }

gbd2010RatioEval <- function(draw.number, 
                             z.num, 
                             z.den) {
  
                      (fobject$eval.2010(z.num,
                                         rr.curves[[paste0(cause.code, "_", age.code, "_gbd_2010_website")]][draw.number, ])
                       /
                         fobject$eval.2010(z.den,
                                           rr.curves[[paste0(cause.code, "_", age.code, "_gbd_2010_website")]][draw.number, ]))
                      
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
  
  # first prep the gbd2010 parameters file from the website, it has a different format (Rick prefers this one)
  gbd_2010_website_file <- file.path(rr.dir, "gbd_2010_website", "IHME_CRCurve_parameters GBD2010.csv") %>% fread()
  #change the varnames
  gbd_2010_website_file[, draw := sim]
  gbd_2010_website_file[, gamma := delta]
  gbd_2010_website_file[, draw := sim]
  gbd_2010_website_file[, tmred := zcf]
  #change the age coding
  gbd_2010_website_file[age=="All Age" | age=="AllAge", age := 99]
  
  #subset to the vars of interest
  gbd_2010_website_file <- gbd_2010_website_file[, c("draw", "cause", "age", "alpha", "beta", "gamma", "tmred"), with=F]
  
  #replace the cause names to match gbd2013
  #use custom function, first defining the names you want to switch
  old.causes <- c('IHD',
                  'STROKE',
                  'COPD',
                  'LC',
                  'ALRI')   
  replacement.causes <- c('cvd_ihd',
                          'cvd_stroke',
                          'resp_copd',
                          'neo_lung',
                          'lri')  
  
  # then pass to your custom function
  gbd_2010_website_file <- findAndReplace(gbd_2010_website_file,
                                          old.causes,
                                          replacement.causes,
                                          "cause",
                                          "cause")

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
      
      if (rr.version == "gbd_2010_website") {
        
        #subset the prepped file to the correct age/cause
        fitted.parameters = gbd_2010_website_file[cause == cause.code & age == age.code,] 

      }
      
      else {
        
        # parameters that define these curves are used to generate age/cause specific RRs for a given exposure level
        rr.parameters <- file.path(rr.dir, rr.version, paste0("rr_curve_", rr.functional.form))
        fitted.parameters <- fread(paste0(rr.parameters, "_", cause.code, "_a", age.code, ".csv"))
        
        fitted.parameters[, draw := V1]
        
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
      
    for (rr.version in rr.versions) {
      
      
      cat("prepping", rr.version, "\n"); flush.console()
    
      predictions <- data.table(exposure = test_exposure, 
                                cause_code = cause.code,
                                age = age.code,
                                version = rr.version)
        
        if (rr.version == "gbd_2010_website") {
          
          
          # Generate the RRs using the evaluation function
          predictions[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                                        mc.cores = 1,
                                                        function(draw.number) {
                                                          
                                                          fobject$eval.2010(exposure,
                                                                            rr.curves[[paste0(cause.code, "_", age.code, "_", rr.version)]][draw.number, ])
                                                          
                                                        }
                                                        
          )] # Use function object, the exposure, and the RR parameters to calculate PAF

        }
        
        else {
          
          # Generate the RRs using the evaluation function
          predictions[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                                        mc.cores = 1,
                                                        function(draw.number) {
                                                          
                                                          fobject$eval(exposure,
                                                                       rr.curves[[paste0(cause.code, "_", age.code, "_", rr.version)]][draw.number, ])
                                                          
                                                        }
                                                        
          )] # Use function object, the exposure, and the RR parameters to calculate PAF

        }
        
      
      if (age.cause.number == 1 & rr.version == "gbd_2013") { # if in the first loop, create the object to store all kinds of prediction
        
        all.predictions <- predictions
        
      } else { # otherwise just append the latest predictions onto the all prediction object
        
        all.predictions <- rbindlist(list(all.predictions, predictions)) 
      
      }
      
    }
  
  }
  
    id.variables <- c("exposure", "age", "cause_code", "version")
    
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
    
    all.predictions.summary[, cause_id := cause_code ]
    
    # expand cvd_stroke to include relevant subcauses in order to prep for merge to YLDs, using your custom find/replace function
    # first supply the values you want to find/replace as vectors
    old.causes <- c('cvd_ihd',
                    'cvd_stroke',
                    'resp_copd',
                    'neo_lung',
                    'lri')   
    replacement.causes <- c('Cardiovascular IHD', 
                            "Cardiovascular Stroke",
                            "Respiratory COPD",
                            "Lung Cancer",
                            "ALRI")
    
    # then pass to your custom function
    all.predictions.summary <- findAndReplace(all.predictions.summary,
                                              old.causes,
                                              replacement.causes,
                                              "cause_code",
                                              "cause")
    
    
    all.predictions.summary[version == "gbd_2010_website", version := "gbd_2010"]
    
    # save this section so you dont need to rerun here
    save(list=ls(), file=out.environment)
    write.csv(all.predictions.summary, paste0(graphs.dir, "/ier_risk_table_all_cause_site.csv"))
  
} else {
    
  load(out.environment)
    
}
#********************************************************************************************************************************
 
#----GEN PLOTS----------------------------------------------------------------------------------------------------------------------
# Build the various plots that will go into your quad figure

pdf(file.path(graphs.dir, paste0("ier_comparison.pdf")), width=16, height=8)

for (age.cause.number in 1:nrow(age.cause)) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  cat("working on", age.code, "-", cause.code, "\n"); flush.console()
  
  cause.title <- ifelse(cause.code == "cvd_ihd" | cause.code == "cvd_stroke",
                        paste0(all.predictions.summary[cause_id == cause.code, cause][1], ", Age: ", all.predictions.summary[cause_id == cause.code, age][1]),
                        paste0(all.predictions.summary[cause_id == cause.code, cause][1], ", All Ages"))

  plot <- plotCurves(data.line=all.predictions.summary[cause_id == cause.code & exposure < 125,],
                     x.line="exposure",
                     y.line="RR_mean",
                     y.lower="RR_lower",
                     y.upper="RR_upper",
                     type.line="version",
                     title.string= paste0(cause.title, " - OAP Range"),
                     x.lab.string="PM2.5",
                     y.lab.string="RR")
  
  print(plot)
  
  plot <- plotCurves(data.line=all.predictions.summary[cause_id == cause.code & exposure < 1000,],
                     x.line="exposure",
                     y.line="RR_mean",
                     y.lower="RR_lower",
                     y.upper="RR_upper",
                     type.line="version",
                     title.string= paste0(cause.title, ": OAP/HAP Range"),
                     x.lab.string="PM2.5",
                     y.lab.string="RR")
  
  print(plot)
  
  plot <- plotCurves(data.line=all.predictions.summary[cause_id == cause.code & exposure < 30000,],
                     x.line="exposure",
                     y.line="RR_mean",
                     y.lower="RR_lower",
                     y.upper="RR_upper",
                     type.line="version",
                     title.string= paste0(cause.title, ": Full Range"),
                     x.lab.string="PM2.5",
                     y.lab.string="RR")
  
  print(plot)
  
}

dev.off()

#********************************************************************************************************************************
 
#----SCATTER PLOTS---------------------------------------------------------------------------------------------------------------
pdf(file.path(graphs.dir, paste0('ier_scatter_comparisons.pdf')))

for (age.cause.number in 1:nrow(age.cause)) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  cat("working on", age.code, "-", cause.code, "\n"); flush.console()
  
  # load data
  file.path(data.dir, paste0(cause.code,'_',age.code,'.RData')) %>% load(envir = globalenv())
  
  draw.data <- data.table(draw.data)
  
  # add index
  draw.data[, index := seq_len(.N)]
  
  # remove outliers from observed RR data to make the graphs more legible
#   rr.upper <- quantile(draw.data$rr,.75,na.rm=TRUE)
#   size.lower <-quantile((1/draw.data$logrrsd),.25,na.rm=TRUE)
#   if(cause.code != "lri") draw.data <- draw.data[(rr < rr.upper & (1/logrrsd) > size.lower),]
  
  #fix TMREL
  draw.data[z.den==8.12757, z.den := 7.1]

  # it seems that taking the mean parameters and estimating returns a different answer than using 1000 draws of params then taking the mean...talk to mehrdad
  # Generate the RRs using the evaluation function
  draw.data[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                              mc.cores = 1,
                                              gbd2010RatioEval,
                                              z.num=z.num,
                                              z.den=z.den)] # Use function object, the exposure, and the RR parameters to calculate PAF
  draw.data[, "gbd2010" := rowMeans(.SD), .SDcols=RR.draw.colnames, by="index"]
  
  # Generate the RRs using the evaluation function
  draw.data[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                              mc.cores = 1,
                                              gbd2013RatioEval,
                                              z.num=z.num,
                                              z.den=z.den)] # Use function object, the exposure, and the RR parameters to calculate PAF
  
  draw.data[, "gbd2013" := rowMeans(.SD), .SDcols=RR.draw.colnames, by="index"]
  
  # remove the draws of RR, no longer necessary
  draw.data[, c(RR.draw.colnames) := NULL]
  
  molten <- melt(draw.data, id.vars = c("tmred", "z.num", "z.den", "rr", "weights", "zsource", "cause", "logrr", "logrrsd", "study", "index"))
  
  p1 <- ggplot(molten, aes(x = rr, y = value, size = weights, color = zsource)) + 
    facet_wrap(~variable) +
    geom_point() +
    geom_abline(slope=1) +
    scale_size_continuous(guide=FALSE) +
    scale_x_continuous(limits=c(1, molten$value %>% max %>% ceiling)) +
    scale_y_continuous(limits=c(1, molten$value %>% max %>% ceiling)) +
    labs(title = paste0("Cause: ", cause.code, " - Age: ", age.code),
         x = "Published RR",
         y = "Predicted RR") +
    theme_bw()
  
  p2 <- ggplot(molten[zsource != "ActSmok"], aes(x = rr, y = value, size = weights, color = zsource)) + 
    facet_wrap(~variable) +
    geom_point() +
    geom_abline(slope=1) +
    scale_size_continuous(guide=FALSE) +
    scale_x_continuous(limits=c(1, molten[zsource != "ActSmok"]$value %>% max %>% ceiling)) +
    scale_y_continuous(limits=c(1, molten[zsource != "ActSmok"]$value %>% max %>% ceiling)) +
    labs(title = paste0("Cause: ", cause.code, " - Age: ", age.code),
         x = "Published RR",
         y = "Predicted RR") +
    theme_bw()
  
  print(p1)
  
  print(p2)
  
  stats <- copy(draw.data)
  stats[,"gbd2013_resid" := (gbd2013 - rr)^2]
  stats[,"gbd2010_resid" := (gbd2010 - rr)^2]
  
  stats[,c("gbd2013_diff", "gbd2010_diff") := lapply(.SD, sum), 
        by = zsource, .SDcols = c("gbd2013_resid", "gbd2010_resid")]

  # create also a weighted version to take into account data uncertainty (weights = 1/logrrsd^2)
  stats[, c("gbd2013_diff_w", "gbd2010_diff_w") := lapply(.SD[, c("gbd2013_resid", "gbd2010_resid"), with=F], 
                 function(x) sum(x*weights)/sum(weights)), by = zsource]

  if (age.cause.number == 1) {
    
    all.stats <- stats
    
  }
  else {
    
    all.stats <- rbind(all.stats, stats)
    
  }
  
}

dev.off()

setkeyv(all.stats, c('zsource', 'cause'))
small.stats <- unique(all.stats)

write.csv(all.stats, paste0(graphs.dir, "/residuals.csv"))
write.csv(small.stats, paste0(graphs.dir, "/residual_stats.csv"))
  
#********************************************************************************************************************************
 
#----SCRAP-----------------------------------------------------------------------------------------------------------------------

#   # remove outliers from observed RR data to make the graphs more legible
#   rr.upper <- quantile(all.data$rr,.75,na.rm=TRUE)
#   size.lower <-quantile((1/all.data$logrrsd),.25,na.rm=TRUE)
#   draw.data.outliered <- copy(all.data)
#   if(cause.code != "lri") draw.data.outliered <- draw.data.outliered[(draw.data.outliered$rr < rr.upper & (1/draw.data.outliered$logrrsd) > size.lower),]
#   
#   plot <- plotCurves(data.line=all.predictions[version != "no_AS",],
#                      x.line="exposure",
#                      y.line="RR_mean",
#                      y.lower="RR_lower",
#                      y.upper="RR_upper",
#                      type.line="version",
#                      data.point=draw.data.outliered,
#                      x.point="z.num",
#                      y.point="rr",
#                      weight.point="weights",
#                      type.point="zsource", 
#                      title.string=paste0("IER Comparison - cause.code: ", cause.code, " / age: ", age.code),
#                      x.lab.string="PM2.5",
#                      y.lab.string="RR")
#   
#   plot.trunc <- plotCurves(data.line=all.predictions[version != "no_AS" & exposure < 600,],
#                            x.line="exposure",
#                            y.line="RR_mean",
#                            y.lower="RR_lower",
#                            y.upper="RR_upper",
#                            type.line="version",
#                            data.point=draw.data.outliered[z.num < 600,],
#                            x.point="z.num",
#                            y.point="rr",
#                            weight.point="weights",
#                            type.point="zsource", 
#                            title.string=paste0("IER Comparison - cause: ", cause.code, " / age: ", age.code),
#                            x.lab.string="PM2.5",
#                            y.lab.string="RR")
#   
#   plot.log <- plot + scale_x_log10()
#   plot.trunc.log <- plot.trunc + scale_x_log10()
#   
#   pdf(all.predictions.summary, paste0(graphs, "/ier_risk_table_",cause.code,"_",age.code,".csv"))
#   
#   pdf(file.path(graphs, paste0("/ier_curves_",cause.code,"_",age.code,".pdf")), width=11, height=8) #toggle if 2013 only
#   print(plot)
#   print(plot.log)
#   print(plot.trunc)
#   print(plot.trunc.log)
#   dev.off()
#   
# }
#   
#********************************************************************************************************************************