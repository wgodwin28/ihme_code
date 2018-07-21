#----DEPENDENCIES-----------------------------------------------------------------------------------------------------------------
#Purpose: script of functions used to calculate temperature PAFs
##Contains:
  #1. prep.rr - function to read in betas and var/covar matrix of RR model and generate draws to RR prediction later
  #2. calculatePAFs- function that uses draws of exposure and rr parameters to calculate exposure spline variables, pixel level RR, and finally population attributable fraction
  #3. formatAndSummPAF - function that formats and creates draw summary of the PAF output
  #4. est.spline.var - calculates spline variables given vector to put spline through and vector of knot placements

# load packages, install if missing
pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
pacman::p_load(data.table, parallel, plyr, reshape2, mvtnorm, zoo)


##RR curves prep
prep.rr <- function(path, acause, suff){
  var_merge <- fread(paste0(j, "WORK/05_risk/risks/temperature/data/rr/rr_analysis/model_output/var_merge.csv"))
  beta <- fread(paste0(path, "betas/n_", acause, suff))
  beta[, order := 1:.N]
  beta2 <- merge(beta, var_merge, by = "var")
  beta2 <- beta2[order(order)]
  var_names <- unique(beta2$var_clean)
  #var_num <- length(grep("v", colnames(beta))) - 1
  var_num <- 23
  beta <- beta[1:var_num]
  b <- beta$b1
  var <- as.matrix(beta[,paste0("v", 1:var_num), with = F])
  rr.params <- rmvnorm(n=1000, mean=b, sigma = var) %>% as.data.table
  names(rr.params) <- var_names
  rr.params[, draw := 1:.N]
  return(rr.params)
}

# prep.rr <- function(cause, path, version){
#   rr.params <- fread(paste0(path, "betas_", cause, "_", version, ".csv"))
#   rr.params[, draw := 1:.N]
#   return(rr.params)
# }
# # function that generates the RRs using the above parameter outputs-LOOK AT CODE BELOW FOR EXAMPLE OF HOW TO SPECIFY SPLINE
# rr.functions <- paste0("/snfs2/HOME/wgodwin/temperature/paf/lib/functional_forms_test.R")
###############################################################################################################################
calculatePAFs <- function(exposure.object,
                          rr.curves,
                          #metric.type,
                          function.draws=draws.required,
                          ehi_ref,
                          mmt_ref,
                          function.cores=1,
                          config_path,
                          rr_max=F,
                          knots.dt){
  start <- Sys.time()
  # Prep out datasets
  PAF.object <- as.data.frame(matrix(as.integer(NA), nrow=1, ncol=function.draws+2))#just make one row while running on all-age, one cause for now
  RR.object <- exposure.object[, c("lat", # this should match the dimensions of your exposure object, i also included iso3/year/pop/raw exposure
                                   "long", # in case i later want to output this dataset, the above listed vars make it more useful
                                   "location_id",
                                   "date",
                                   "pop",
                                   "tmean",
                                   "mmt",
                                   "ehi",
                                   "heat_effect"),
                               with=F]
  
  #set column names to be indexed and calculated
  #sdi <- exposure.object$sdi
  
    #temp variables
    mmt.colnames <- c(paste0("mmt_",1:function.draws))
    dev.colnames <- c(paste0("dev_",1:function.draws))
    
    #Excess colnames for joint, heat, and cold RRs
    excess.joint.colnames <- c(paste0("excess_joint_",1:function.draws))
    excess.heat.colnames <- c(paste0("excess_heat_",1:function.draws))
    excess.cold.colnames <- c(paste0("excess_cold_",1:function.draws))
    
    #Total RR colnames for joint, heat, and cold RRs
    RR.joint.colnames <- c(paste0("RR_joint_", 1:function.draws))
    RR.heat.colnames <- c(paste0("RR_heat_", 1:function.draws))
    RR.cold.colnames <- c(paste0("RR_cold_", 1:function.draws))
    by_vars <- c("location_id", "long", "lat", "pop")
  
  #Bring in config path to identify specs of the model
  #config <- fread(config_path)[cause == cause & model_version == rr.functional.form]
  
  #Spline variable generation
    #MMT spline variables
    #mmt_knots <- unlist(strsplit(config$knot_vec_mmt, ",")) %>% as.numeric
    mmt_knots <- as.numeric(knots.dt[,na.omit(mmt)])
    mmt_var_num <- length(mmt_knots) - 1
    mmt_spline_vars <- mclapply(1:function.draws, mc.cores = function.cores, function(draw){
        spline_vars <- est.spline.var(knot.vec = mmt_knots, var.vec = exposure.object[, get(paste0("mmt_", draw))]) %>% as.data.table
        setnames(spline_vars, c(paste0("V", 1:mmt_var_num)), c(paste0("mmt_var_", 1:mmt_var_num, "_", draw)))
        return(spline_vars)
      }) 
    mmt_spline_vars <- do.call(cbind, mmt_spline_vars) %>% as.data.table    

    #EHI spline variables
    #ehi_knots <- unlist(strsplit(config$knot_vec_ehi, ",")) %>% as.numeric
    ehi_knots <- as.numeric(knots.dt[,na.omit(ehi)])
    ehi_var_num <- length(ehi_knots) - 1
    ehi_spline_vars <- mclapply(1:function.draws, mc.cores = function.cores, function(draw){
      spline_vars <- est.spline.var(knot.vec = ehi_knots, var.vec = exposure.object[, get(paste0("ehi_", draw))]) %>% as.data.table
      setnames(spline_vars, c(paste0("V", 1:ehi_var_num)), c(paste0("ehi_var_", 1:ehi_var_num, "_", draw)))
      return(spline_vars)
    })
    ehi_spline_vars <- do.call(cbind, ehi_spline_vars) %>% as.data.table
    #exposure.object <- cbind(exposure.object, mmt_spline_vars, ehi_spline_vars)
    #rm(ehi_spline_vars, mmt_spline_vars)
    message("spline mclapply success")
    exposure.object <- exposure.object[, .(sdi)]
    
  ###########generate spline variables for reference rate as well by creating the var.vec to be all 0 for mmt-tmrel and ehi#########################
  rows <- nrow(exposure.object)
  ref_mmt_vec <- rep(mmt_ref, rows)
  #ref_mmt_vec <- exposure.object$mmt_tmrel
  ref_ehi_vec <- rep(ehi_ref, rows)

  #reference monthly mean spline variables
  mmt_spline_vars_ref <- est.spline.var(knot.vec = mmt_knots, var.vec = ref_mmt_vec) %>% as.data.table
  setnames(mmt_spline_vars_ref, c(paste0("V", 1:mmt_var_num)), c(paste0("ref_mmt_var_", 1:mmt_var_num)))
  
  #reference temperature deviation spline variables
  ehi_spline_vars_ref <- est.spline.var(knot.vec = ehi_knots, var.vec = ref_ehi_vec) %>% as.data.table
  setnames(ehi_spline_vars_ref, c(paste0("V", 1:ehi_var_num)), c(paste0("ref_ehi_var_", 1:ehi_var_num)))
  #exposure.object <- cbind(exposure.object, mmt_spline_vars_ref, ehi_spline_vars_ref)
  #rm(ehi_spline_vars_ref, mmt_spline_vars_ref)
  
  start.fun <- Sys.time()
    RR.object[, c(RR.joint.colnames) := mclapply(1:function.draws,
                                              mc.cores = function.cores,
                                              function(draw.number) {
                                                risk_rate <- fobject$eval(mmt_spline_vars[, get(paste0("mmt_var_1_", draw.number))],
                                                                          mmt_spline_vars[, get(paste0("mmt_var_2_", draw.number))],
                                                                          mmt_spline_vars[, get(paste0("mmt_var_3_", draw.number))],
                                                                          ehi_spline_vars[, get(paste0("ehi_var_1_", draw.number))],
                                                                          ehi_spline_vars[, get(paste0("ehi_var_2_", draw.number))],
                                                                          exposure.object$sdi,
                                                                          rr.curves[draw.number,])
                                                ref_rate <- fobject$eval(mmt_spline_vars_ref$ref_mmt_var_1,
                                                                         mmt_spline_vars_ref$ref_mmt_var_2,
                                                                         mmt_spline_vars_ref$ref_mmt_var_3,
                                                                         ehi_spline_vars_ref$ref_ehi_var_1,
                                                                         ehi_spline_vars_ref$ref_ehi_var_2,
                                                                         exposure.object$sdi,
                                                                         rr.curves[draw.number,])
                                                return(as.numeric(exp(risk_rate)/exp(ref_rate)))
                                              })]
    
  rm(exposure.object, mmt_spline_vars, ehi_spline_vars, mmt_spline_vars_ref, ehi_spline_vars_ref)
  message("main mclapply success")
  end.fun <- Sys.time()
  message(end.fun - start.fun)
  print(end.fun - start.fun)
  
  #Duplicate out the draws for cold effect RRs
  RR.object[, (RR.heat.colnames) := lapply(.SD, function(x){x}), .SDcols = RR.joint.colnames]
  RR.object[, (RR.cold.colnames) := lapply(.SD, function(x){x}), .SDcols = RR.joint.colnames]

  #Replace any instances of RRs where mmt-tmrel is in the wrong direction (replace RR to 1 for heat RRs if mmt-tmrel is negative)
  RR.object[heat_effect == 0, c(RR.heat.colnames) := 1]
  RR.object[heat_effect == 1, c(RR.cold.colnames) := 1]

    #Find RRmax for SEVs
    if(rr_max){
      #Get the mean RR across days 
      RR.temp <- RR.object[, lapply(.SD, mean, na.rm = T), .SDcols = c(RR.heat.colnames, RR.cold.colnames), by = by_vars]
      pop.all <- RR.temp[,sum(pop)]
      
      #Get pop-weighted mean across pixels for heat and cold
      RR.heat.temp <- RR.temp[, lapply(1:function.draws, function(draw){sum(RR.temp[,RR.heat.colnames[draw], with=FALSE] * RR.temp[,pop])/sum(RR.temp[,pop])})]
      RR.cold.temp <- RR.temp[, lapply(1:function.draws, function(draw){sum(RR.temp[,RR.cold.colnames[draw], with=FALSE] * RR.temp[,pop])/sum(RR.temp[,pop])})]
      
      #Bind heat and cold together and format variable names
      RR.temp <- rbind(RR.heat.temp, RR.cold.temp)
      setnames(RR.temp, c(paste0("V", 1:function.draws)), c(paste0("rr_", 1:function.draws)))
      
      #Add on metadata variables
      RR.temp[1, heat := 1]
      RR.temp[2, heat := 0]
      RR.temp[, year_id := year]
      RR.temp[, location_id := loc]
      
      #Retain total population for population weighting later and calculate means
      RR.temp[, pop := pop.all]
      RR.temp <- cbind(RR.temp[,.(heat,pop)], collapse_point(RR.temp, draws_name = "rr_", keep_draws = T))
    }
  
  #Calculate excess risk
  RR.object[, (excess.joint.colnames) := lapply(.SD, function(x){x-1}), .SDcols = RR.joint.colnames]
  RR.object[, (excess.heat.colnames) := lapply(.SD, function(x){x-1}), .SDcols = RR.heat.colnames]
  RR.object[, (excess.cold.colnames) := lapply(.SD, function(x){x-1}), .SDcols = RR.cold.colnames]

  #Sum RRs across days to get annual excess risk and total risk for each pixel
  RR.object <- RR.object[, lapply(.SD, sum), .SDcols = c(RR.joint.colnames, RR.heat.colnames, RR.cold.colnames, excess.joint.colnames, excess.heat.colnames, excess.cold.colnames), by = by_vars]

  #generate PAFs at the annual level using the grid-level RRs and population
  pop.chunk <- RR.object[, sum(pop)]
    #Joint PAFs
    PAF.object.joint <- mclapply(1:function.draws,
                                mc.cores = function.cores,
                                function(draw.number) {
                                  paf <- (sum(RR.object[,excess.joint.colnames[draw.number], with=FALSE] * RR.object[,pop]) 
                                          /
                                            sum(RR.object[,RR.joint.colnames[draw.number], with=FALSE]* RR.object[,pop]))
                                  
                                  return(as.numeric(paf))
                                })
    PAF.object.joint <- do.call(cbind, PAF.object.joint) %>% as.data.table
    PAF.object.joint[, heat := 2]
    PAF.object.joint[, pop := pop.chunk]
    message("big mclapply success")
    
    #Heat PAFs
    PAF.object.heat <- mclapply(1:function.draws,
                           mc.cores = function.cores,
                           function(draw.number) {
                             paf <- (sum(RR.object[,excess.heat.colnames[draw.number], with=FALSE] * RR.object[,pop]) 
                              /
                              sum(RR.object[,RR.heat.colnames[draw.number], with=FALSE]* RR.object[,pop]))
                             
                             return(as.numeric(paf))
                           })
    PAF.object.heat <- do.call(cbind, PAF.object.heat) %>% as.data.table
    PAF.object.heat[, heat := 1]
    PAF.object.heat[, pop := pop.chunk]
    
    ##Cold PAFs
    PAF.object.cold <- mclapply(1:function.draws,
                                mc.cores = function.cores,
                                function(draw.number) {
                                  paf <- (sum(RR.object[,excess.cold.colnames[draw.number], with=FALSE] * RR.object[,pop]) 
                                          /
                                            sum(RR.object[,RR.cold.colnames[draw.number], with=FALSE] * RR.object[,pop]))
                                  
                                  return(as.numeric(paf))
                                })
    PAF.object.cold <- do.call(cbind, PAF.object.cold) %>% as.data.table
    PAF.object.cold[, heat := 0]
    PAF.object.cold[, pop := pop.chunk]
    PAF.object <- rbind(PAF.object.joint, PAF.object.heat, PAF.object.cold)
    message("home free")
    end <- Sys.time()
    message(end - start)
    
  #Clean and return object
  rm(RR.object)
  return(list(PAF.object, RR.temp))
}

############################################################################################################################
formatAndSummPAF <- function(PAF.output, 
                             #metric.type,
                             ...) {
  
  ##purpose##
  #this function is used as a wrapper for some general formatting steps that need to be taken for both mortality and morbidity calculations
  #these steps include:
  #1: naming columns
  #2: summarization; need to generate means and CIs for review
  #3: order columns and final formatting of the summary file
  #4: expanding the dataset to match proper GBD age groups for each cause that does not have an age-specific PAF
  # further details on these steps can be found below
  
  ##inputs##
  #PAF.output = a list of PAFs calculated for each age/cause variation, this file is raw draws of the distribution and needs some final prepping/summarization
  #metric type (yll/yld) = selects the kind of analysis done for PAF.output. this is either yll (mortality) or yld (morbidity).
  
  ##outputs##
  #output.list = this is a list object that has two dataframes in it. the first is 1000 draws of the distribution, the second is a lite file with just mean/CI
  
  #PAF.output <- do.call(rbind.data.frame, PAF.output) # the previous function created a list of lists
  # this command coerces that list to a simple dataframe
  
  #pafs must be saved in this stupid way (0-999 instead of 1-1000)
  PAF.draw.colnames <- c(paste0("paf_", 0:(draws.required-1)))
  
  #names(PAF.output) <- c(PAF.draw.colnames, "cause", "age")
  names(PAF.output) <- c("heat", PAF.draw.colnames)
  
  # generate mean and CI for summary figures
  PAF.output <- as.data.table(PAF.output)
  PAF.output <- cbind(PAF.output, collapse_point(PAF.output, draws_name = "paf"))
  
  # create variable to store type
  #PAF.output[, type := metric.type]
  
  #Order columns to your liking
  PAF.output.draws <- PAF.output[, c(PAF.draw.colnames, "heat"), with = F]
  
  # Save summary version of PAF output for experts 
  PAF.output.summary <- PAF.output[, c("lower",
                                       "mean",
                                       "upper",
                                       "heat"), 
                                   with=F]
  
  output.list <- setNames(list(PAF.output.draws, PAF.output.summary),  c("draws", "summary"))
  
  return(output.list)
  
}
######################################Spline variable equation############################
est.spline.var <- function(knot.vec, var.vec){
  #get length of knot vector
  n <- length(knot.vec)
  V1 <- var.vec
  many.vars <- matrix(nrow = length(var.vec), ncol = n-2)
  
  #loop through remaining n-1 knots to calculate each spline variable
  for(i in seq(1, n-2)){
    #first element
    e1 <- (V1 - knot.vec[i])^3
    e1 <- ifelse(e1 > 0, e1, 0)
    
    #second element
    e2 <- (V1 - knot.vec[n-1])^3
    e2 <- ifelse(e2 > 0, e2, 0)

    #third element
    e3 <- (V1 - knot.vec[n])^3
    e3 <- ifelse(e3 > 0, e3, 0)
    
    #spline formula
    spline.var <- ((e1 - ((knot.vec[n] - knot.vec[n-1])^-1) * ((e2 * (knot.vec[n] - knot.vec[i])) - (e3 * (knot.vec[n-1] - knot.vec[i]))))
      /(knot.vec[n] - knot.vec[1])^2)
    
    many.vars[1:length(var.vec),i] <- spline.var
  }
  return(cbind(V1, many.vars))
}
