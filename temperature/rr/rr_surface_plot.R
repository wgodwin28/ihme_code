#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: WG
# Date: 04/30/2018
# Purpose: Generate risk surfaces to diagnose what goes into PAF calculator
# source("/homes/wgodwin/temperature/paf/calc/master.R", echo=T)
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
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
# load packages, install if missing
#pacman::p_load(data.table, magrittr)
require(data.table)
require(magrittr)
require(mapproj)
require(ggplot2)

####################################################################################################
####################################################################################################
  #Set toggles and cause list
  beta.dir <- paste0(j, "temp/Jeff/temperature/combinedAnalysis/")
  causes <- c("cvd_ihd", "ckd", "diabetes", "cvd_stroke", "resp_copd", "inj_drowning", "nutrition_pem", "lri", "uri", "tb", "resp_asthma")
  causes <- c("cvd_ihd", "ckd", "diabetes", "lri")
  causes <- c("cvd_stroke", "resp_copd", "inj_drowning", "nutrition_pem")
  causes <- c("uri", "tb", "resp_asthma")
  function.draws <- 1000
  rr.functional.form <- "cubspline.sdi.mmt3"
  function.cores <- 6
  suffix <- "_mmtDif_prPop_braMexNzl.csv" # "_mmtDif_prPop_braMexNzl_knots25_season.csv"
  
  #PAF functions#
  paf.function.dir <- paste0(h, 'temperature/paf/lib/')  
  paste0(paf.function.dir, "paf_helpers.R") %>% source
  source("/share/code/coverage/functions/collapse_point.R")
  
  #RR functions#
  rr.function.dir <- paste0(h, 'temperature/paf/lib/')  
  paste0(rr.function.dir, "functional_forms.R") %>% source
  fobject <- get(rr.functional.form)
  
  #Loop through causes
  pdf(paste0(j, "WORK/05_risk/risks/temperature/diagnostics/paf/risk_surfaces3.pdf"))
  all.dt <- data.table()
  for(cause in causes){
    rr.curves <- prep.rr(path = beta.dir, acause = cause, suff = suffix)
    ###CREATE RISK SURFACES####
    #Create template for predictions with every unique combo
    mmt_seq <- seq(-10, 2, 2)
    dev_seq <- seq(-5,5,2.5)
    template <- expand.grid(mmt = mmt_seq, ehi_accl = dev_seq, sdi = c(.4,.6,.8)) %>% as.data.table
    
    #Generate template spline variables
    #Mean monthly temperature
    mmt_knots <- c(-9,-4,0,.65)
    mmt_var_num <- length(mmt_knots) - 1
    mmt_spline_vars <- mclapply(1:function.draws, mc.cores = function.cores, function(draw){
      spline_vars <- est.spline.var(knot.vec = mmt_knots, var.vec = template$mmt) %>% as.data.table
      setnames(spline_vars, c(paste0("V", 1:mmt_var_num)), c(paste0("mmt_var_", 1:mmt_var_num, "_", draw)))
      return(spline_vars)
    }) 
    mmt_spline_vars <- do.call(cbind, mmt_spline_vars) %>% as.data.table  
    
    #Deviations from mmt
    ehi_knots <- c(-5,0,5)
    ehi_var_num <- length(ehi_knots) - 1
    ehi_spline_vars <- mclapply(1:function.draws, mc.cores = function.cores, function(draw){
      spline_vars <- est.spline.var(knot.vec = ehi_knots, var.vec = template$ehi_accl) %>% as.data.table
      setnames(spline_vars, c(paste0("V", 1:ehi_var_num)), c(paste0("ehi_var_", 1:ehi_var_num, "_", draw)))
      return(spline_vars)
    })
    ehi_spline_vars <- do.call(cbind, ehi_spline_vars) %>% as.data.table
    template <- cbind(template, mmt_spline_vars, ehi_spline_vars)
    
    #reference spline vars
    rows <- nrow(template)
    ref_mmt_vec <- rep(0, rows)
    ref_ehi_vec <- rep(0, rows)
    
    #reference monthly mean spline variables
    mmt_spline_vars_ref <- est.spline.var(knot.vec = mmt_knots, var.vec = ref_mmt_vec) %>% as.data.table
    setnames(mmt_spline_vars_ref, c(paste0("V", 1:mmt_var_num)), c(paste0("ref_mmt_var_", 1:mmt_var_num)))
    
    #reference temperature deviation spline variables
    ehi_spline_vars_ref <- est.spline.var(knot.vec = ehi_knots, var.vec = ref_ehi_vec) %>% as.data.table
    setnames(ehi_spline_vars_ref, c(paste0("V", 1:ehi_var_num)), c(paste0("ref_ehi_var_", 1:ehi_var_num)))
    
    #Predict out for each unique mmt, deviation combination
    draw.colnames <- c(paste0("pred_", 1:function.draws))
    ref.colnames <- c(paste0("ref_", 1:function.draws))
    template[, c(draw.colnames) := mclapply(1:function.draws,
                                            mc.cores = function.cores,
                                            function(draw.number) {
                                              risk_rate <- fobject$eval(template[, get(paste0("mmt_var_1_", draw.number))],
                                                                        template[, get(paste0("mmt_var_2_", draw.number))],
                                                                        template[, get(paste0("mmt_var_3_", draw.number))],
                                                                        template[, get(paste0("ehi_var_1_", draw.number))],
                                                                        template[, get(paste0("ehi_var_2_", draw.number))],
                                                                        template[, sdi],
                                                                        rr.curves[draw.number,])
                                              ref_rate <- fobject$eval(mmt_spline_vars_ref$ref_mmt_var_1,
                                                                       mmt_spline_vars_ref$ref_mmt_var_2,
                                                                       mmt_spline_vars_ref$ref_mmt_var_3,
                                                                       ehi_spline_vars_ref$ref_ehi_var_1,
                                                                       ehi_spline_vars_ref$ref_ehi_var_2,
                                                                       template[, sdi],
                                                                       rr.curves[draw.number,])
                                              return(as.numeric(exp(risk_rate)/exp(ref_rate)))
                                            })]
    
    template <- template[,c("mmt", "ehi_accl", "sdi", draw.colnames), with = F]
    
    #template[, c(ref.colnames) := lapply(.SD, mean), .SDcols = c(draw.colnames), by = "sdi"]
    #template[, c(draw.colnames) := lapply(1:function.draws, function(x){exp(get(paste0("pred_", x)) - get(paste0("ref_", x)))})]
    plot.dt <- cbind(template[,.(mmt, ehi_accl, sdi)], collapse_point(template, draws_name = "pred"))
    plot.dt[, mean.all := paste0(round(mean, 3), " (", round(lower, 3), "-", round(upper, 3), ")")]
    plot.dt <- dcast(plot.dt, mmt ~ sdi + ehi_accl, value.var = "mean.all") %>% as.data.table
    plot.dt[, acause := cause]
    all.dt <- rbind(all.dt, plot.dt)
    print(paste0("plotting ", cause))
  }
    
    ###################################################################
    ###############################ggplot##############################
    ###################################################################
    #plot mortality by mmt, across different levels of ehi
    # t <- plot.dt[ehi_accl == 0,]
    # g <- ggplot(data = t, aes(x = mmt, y = mean)) +
    # geom_line(aes(y=mean))+
    # labs(x="MMT Difference by SDI",
    #      y="MMR at AI = 0",
    #      title = cause) +
    # geom_ribbon(aes(ymin=lower, ymax=upper, linetype=NA), fill="lightgreen", alpha=0.2)+
    # facet_wrap(~sdi)
    # print(g)
    # 
    # #plot mortality by ehi, across different levels of mmt
    # t <- plot.dt[mmt == -10 | mmt == -4 | mmt == 2,]
    # t <- t[sdi == .1 | sdi == .5 | sdi == .9,]
    # t <- t[ehi_accl>= -5 & ehi_accl <= 5]
    # g <- ggplot(data = t, aes(x = ehi_accl, y = mean)) +
    # geom_line(aes(y=mean))+
    # labs(x="Deviation from Mean Monthly Temperature",
    #      y="MRR",
    #      title = cause) +
    # geom_ribbon(aes(ymin=lower, ymax=upper, linetype=NA), fill="lightgreen", alpha=0.2)+
    # theme_bw()+
    # facet_wrap(~sdi+mmt)
    # print(g)
    
    #plot mortality by ehi, across different levels of mmt
    t <- plot.dt[mmt == -10 | mmt == -4 | mmt == 2,]
    t <- t[ehi_accl>= -5 & ehi_accl <= 5]
    g <- ggplot(data = t, aes(x = ehi_accl, y = mean,  color = as.factor(sdi))) +
      geom_line(aes(y=mean))+
      labs(x="Deviation from Mean Monthly Temperature",
           y="MRR",
           title = cause) +
      geom_ribbon(aes(ymin=lower, ymax=upper, linetype=NA), fill="lightgreen", alpha=0.2)+
      theme_bw()+
      facet_wrap(~mmt)
    print(g)
    
    # #plot mortality by ehi, across different levels of mmt
    # t <- plot.dt[mmt == -10 | mmt == -4 | mmt == 2,]
    # t <- t[sdi == .1 | sdi == .5 | sdi == .9,]
    # t <- t[ehi_accl>= -5 & ehi_accl <= 5]
    # g <- ggplot(data = t, aes(x = ehi_accl, y = mean, color = as.factor(sdi))) +
    #   geom_line(aes(y=mean))+
    #   labs(x="Deviation from Mean Monthly Temperature",
    #        y="MRR",
    #        title = cause) +
    #   geom_ribbon(aes(ymin=lower, ymax=upper, linetype=NA), fill="lightgreen", alpha=0.2)+
    #   theme_bw()+
    #   facet_wrap(~mmt)
    # print(g)
  }
  dev.off()
  