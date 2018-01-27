  #----HEADER-------------------------------------------------------------------------------------------------------------
  # Author: JF
  # Date: 04/27/2016
  # Project: RF: air_pm
  # Purpose: Create comparison plots for the IER curve
  # source("/homes/jfrostad/_code/risks/air_pm/rr/graph.R", echo=T)
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
  
  } else { 
    
    j_root <- "J:"
    h_root <- "H:"
  
  }
  
  # define parameters
  graph.version <- "power2_simsd_collab"
  rr.functional.forms <- c("power2_simsd_source")
  rr.data.version <- c("5")
  test_exposure <- c(seq(1,300,1), seq(350,30000,50))
  draws.required <- 1000
  
  # load packages, install if missing
  pacman::p_load(data.table, ggplot2, grid, gridExtra, magrittr, parallel, reshape2, rstan, stringr)
  
  # set working directories
  home.dir <- file.path(j_root, "WORK/05_risk/risks/air_pm/")
  setwd(home.dir)
  #***********************************************************************************************************************
   
  #----IN/OUT-------------------------------------------------------------------------------------------------------------
  ##in##
  data.dir <- file.path(home.dir, 'data/rr/prepped/')
    old.preds <- file.path(data.dir, "ier_table_gbd2013_vs_gbd2010.csv") %>% fread
  raw.data.dir <- file.path(home.dir, 'data/rr/raw/')
  output.dir <- file.path(home.dir, 'data/rr/output/')
  
  ##out##
  graphs.dir <- file.path(home.dir, 'diagnostics/rr')
  #***********************************************************************************************************************
   
  #----FUNCTIONS----------------------------------------------------------------------------------------------------------  
  ##function lib##
  #IER functions#
  ier.function.dir <- file.path(h_root, '_code/risks/air_pm/rr/_lib')  
  #this pulls the functional forms used to evaluate the IER and create predictions
  file.path(ier.function.dir, "functional_forms.R") %>% source
  
  #AiR PM functions#
  air.function.dir <- file.path(h_root, '_code/risks/air_pm/_lib')
  # this pulls the miscellaneous helper functions for air pollution
  file.path(air.function.dir, "misc.R") %>% source
  
  #general functions#
  central.function.dir <- file.path(h_root, "_code/_lib/functions/")
  # this pulls the general misc helper functions
  file.path(central.function.dir, "misc.R") %>% source
  
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
  
  # ratio evaluators: these functions are used to evaluate IER input datapoints using a ratio of zden to znum
  # there are 3 functions, one for each version of functional form (2010 and 2013 have the same version but there is a unit shift)
  
  power2RatioEval <- function(draw.number,
                              model,
                              z.num,
                              z.den) {
    
    (power2$eval(z.num,
                 all.rr[[age.cause.number]][[model]][draw.number, ])
     /
       power2$eval(z.den,
                   all.rr[[age.cause.number]][[model]][draw.number, ]))
    
  }

  #***********************************************************************************************************************
   
  #----PREP---------------------------------------------------------------------------------------------------------------
  # use function to pull in the age cause list
  # default is all causes all ages, we only want the lite age group for these graphs
  age.cause <- ageCauseLister(full.age.range = F)
  
  prepRR <- function(age.cause.number) {
    
    cause.code <- age.cause[age.cause.number, 1]
    age.code <- age.cause[age.cause.number, 2]
    
    forms <- list()
    
    for (form in rr.functional.forms) {
        
      # parameters that define these curves are used to generate age/cause specific RRs for a given exposure level
      rr.parameters <- file.path(output.dir, paste0(rr.data.version, form))
      fitted.parameters <- fread(paste0(rr.parameters, "/params_", cause.code, "_", age.code, ".csv"))
      
      setnames(fitted.parameters, "V1", "draws")
      
  
      forms[[form]] <- fitted.parameters
  
    }
    
    return(forms)
    
  }
  
  RR.draw.colnames <- c(paste0("RR_", 1:draws.required))
  
  createPred <- function(age.cause.number) {
  
    cause.code <- age.cause[age.cause.number, 1]
    age.code <- age.cause[age.cause.number, 2]
    
    cat("working on", age.code, "-", cause.code, "\n"); flush.console()
    
    preds <- list()
    
    for (form in rr.functional.forms) {
      
      cat("prepping", form, "\n"); flush.console()
      
      predictions <- data.table(exposure = test_exposure, 
                                cause_code = cause.code,
                                age = age.code,
                                version = form)
      
      if (form == "power2_simsd_source") {
        
        
        # Generate the RRs using the evaluation function
        predictions[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                                      mc.cores = 1,
                                                      function(draw.number) {
                                                        
                                                        power2$eval(exposure,
                                                                    all.rr[[age.cause.number]][[form]][draw.number, ])
                                                        
                                                      }
                                                      
        )] # Use function object, the exposure, and the RR parameters to calculate PAF
        
      }
      
      if (form == "simplified") {
        
        # Generate the RRs using the evaluation function
        predictions[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                                      mc.cores = 1,
                                                      function(draw.number) {
                                                        
                                                        simplified$eval(exposure,
                                                                     all.rr[[age.cause.number]][[form]][draw.number, ])
                                                        
                                                      }
                                                      
        )] # Use function object, the exposure, and the RR parameters to calculate PAF
        
      }
      
      if (form == "loglin") {
        
        # Generate the RRs using the evaluation function
        predictions[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                                      mc.cores = 1,
                                                      function(draw.number) {
                                                        
                                                        loglin$eval(exposure,
                                                                        all.rr[[age.cause.number]][[form]][draw.number, ])
                                                        
                                                      }
                                                      
        )] # Use function object, the exposure, and the RR parameters to calculate PAF
        
      }
      
      preds[[form]] <- predictions
    
    }
    
    return(preds %>% rbindlist)
  
  }
  
  all.rr <- lapply(1:nrow(age.cause), prepRR)
  
  all.pred <- lapply(1:nrow(age.cause), createPred) %>% rbindlist
  
  id.variables <- c("exposure", "age", "cause_code", "version")
  
  all.pred[,RR_lower := quantile(.SD ,c(.025)), .SDcols=RR.draw.colnames, by=id.variables]
  all.pred[,RR_mean := rowMeans(.SD), .SDcols=RR.draw.colnames, by=id.variables]
  all.pred[,RR_upper := quantile(.SD ,c(.975)), .SDcols=RR.draw.colnames, by=id.variables]
  
  #Order columns to your liking
  all.pred <- setcolorder(all.pred, c(id.variables,
                                      "RR_lower", 
                                      "RR_mean", 
                                      "RR_upper", 
                                      RR.draw.colnames))
  
  # Save summary version of PAF output for experts 
  all.pred.summary <- all.pred[, c(id.variables,
                                   "RR_lower",
                                   "RR_mean",
                                   "RR_upper"), 
                               with=F]
  
  all.pred.summary[, cause_id := cause_code ]
  
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
  all.pred.summary <- findAndReplace(all.pred.summary,
                                     old.causes,
                                     replacement.causes,
                                     "cause_code",
                                     "cause")
  
  
  all.pred.summary <- rbind(all.pred.summary, old.preds[, -c('V1'), with=F])
  #********************************************************************************************************************************
  
  #----GEN PLOTS----------------------------------------------------------------------------------------------------------------------
  # Build the various plots that will go into your quad figure
  
  pdf(file.path(graphs.dir, paste0('ier_comparison_', graph.version, '.pdf')), width=16, height=8)
  
  for (age.cause.number in 1:nrow(age.cause)) {
    
    cause.code <- age.cause[age.cause.number, 1]
    age.code <- age.cause[age.cause.number, 2]
    
    cat("working on", age.code, "-", cause.code, "\n"); flush.console()
    
    cause.title <- ifelse(cause.code == "cvd_ihd" | cause.code == "cvd_stroke",
                          paste0(all.pred.summary[cause_id == cause.code, cause][1], ", Age: ", all.pred.summary[cause_id == cause.code & age==age.code, age][1]),
                          paste0(all.pred.summary[cause_id == cause.code, cause][1], ", All Ages"))
    
    plot <- plotCurves(data.line=all.pred.summary[cause_id == cause.code & age==age.code & exposure < 125,],
                       x.line="exposure",
                       y.line="RR_mean",
                       y.lower="RR_lower",
                       y.upper="RR_upper",
                       type.line="version",
                       title.string= paste0(cause.title, " - OAP Range"),
                       x.lab.string="PM2.5",
                       y.lab.string="RR")
    
    print(plot)
    
    plot <- plotCurves(data.line=all.pred.summary[cause_id == cause.code & age==age.code & exposure < 1000,],
                       x.line="exposure",
                       y.line="RR_mean",
                       y.lower="RR_lower",
                       y.upper="RR_upper",
                       type.line="version",
                       title.string= paste0(cause.title, ": OAP/HAP Range"),
                       x.lab.string="PM2.5",
                       y.lab.string="RR")
    
    print(plot)
    
    plot <- plotCurves(data.line=all.pred.summary[cause_id == cause.code & age==age.code & exposure < 30000,],
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
pdf(file.path(graphs.dir, paste0('ier_scatter_comparisons', graph.version, '.pdf')))

for (age.cause.number in 1:nrow(age.cause)) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.code <- age.cause[age.cause.number, 2]
  
  cat("working on", age.code, "-", cause.code, "\n"); flush.console()
  
  # load data
  file.path(data.dir, rr.data.version, paste0(cause.code,'_',age.code,'.RData')) %>% load(envir = globalenv())
  
  draw.data <- data.table(draw.data)
  
  # add index
  draw.data[, index := seq_len(.N)]
  
  # remove outliers from observed RR data to make the graphs more legible
  #   rr.upper <- quantile(draw.data$rr,.75,na.rm=TRUE)
  #   size.lower <-quantile((1/draw.data$logrrsd),.25,na.rm=TRUE)
  #   if(cause.code != "lri") draw.data <- draw.data[(rr < rr.upper & (1/logrrsd) > size.lower),]

  
  # Generate the RRs using the evaluation function
  draw.data[, c(RR.draw.colnames) := mclapply(1:draws.required,
                                              mc.cores = 1,
                                              power2RatioEval,
                                              model="power2_simsd_source",
                                              z.num=conc,
                                              z.den=conc_den)] # Use function object, the exposure, and the RR parameters to calculate PAF
  
  draw.data[, "power2" := rowMeans(.SD), .SDcols=RR.draw.colnames, by="index"]

  # remove the draws of RR, no longer necessary
  draw.data[, c(RR.draw.colnames) := NULL]
  
  molten <- melt(draw.data, id.vars = c("nid", "conc", "conc_den", "log_rr", "log_se", "weight", "source", "cause", "study", 'age_median', 'tmrel', "index"))
  
  p1 <- ggplot(molten, aes(x = exp(log_rr), y = value, size = weight, color = source)) + 
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
  
  p2 <- ggplot(molten[source != "ActSmok"], aes(x = exp(log_rr), y = value, size = weight, color = source)) + 
    facet_wrap(~variable) +
    geom_point() +
    geom_abline(slope=1) +
    scale_size_continuous(guide=FALSE) +
    scale_x_continuous(limits=c(1, molten[source != "ActSmok"]$value %>% max %>% ceiling)) +
    scale_y_continuous(limits=c(1, molten[source != "ActSmok"]$value %>% max %>% ceiling)) +
    labs(title = paste0("Cause: ", cause.code, " - Age: ", age.code),
         x = "Published RR",
         y = "Predicted RR") +
    theme_bw()
  
  print(p1)
  
  print(p2)
  
  stats <- copy(draw.data)
  stats[,"power2_resid" := (power2 - exp(log_rr))^2]
  
  stats[,c("power2_diff") := lapply(.SD, sum), 
        by = source, .SDcols = c("power2_resid")]
  
  # create also a weighted version to take into account data uncertainty (weights = 1/logrrsd^2)
  stats[, c("power2_diff_w") := lapply(.SD[, c("power2_resid"), with=F], 
                                                          function(x) sum(x*weight)/sum(weight)), by = source]
  
  if (age.cause.number == 1) {
    
    all.stats <- stats
    
  }
  else {
    
    all.stats <- rbind(all.stats, stats)
    
  }
  
}

dev.off()

setkeyv(all.stats, c('source', 'cause'))
small.stats <- unique(all.stats)

write.csv(all.stats, paste0(output.dir, "/", graph.version, "_residuals.csv"))
write.csv(small.stats, paste0(output.dir, "/", graph.version, "_residuals_stats.csv"))


