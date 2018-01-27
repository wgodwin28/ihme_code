#####################################################################################
### GM_run.R - Code to run predictions for the Ground Monitor observations. This  ###
### code will first read in the GM data and get INLA to predict at the ground     ###
### monitors. It also extracts the mode of the random effects in the models so    ###
### that to speed up the computation.                                             ###
#####################################################################################
### Inputs: PredData_GM.RData - Ground monitor data for modelling                 ###
###                                                                               ###
### Output: GM_out.RData - Predictions for 2014 Ground Monitors                   ###
###         theta.RData - Vector of Modes to speed up the INLA run for prediction ###
#####################################################################################

# Clearing Workspace from previous load
rm(list=ls())

# Loading INLA package
require(INLA)

# Loading data
load('PredData_GM.RData')

#####################
### Model formula ###
#####################
formula <- logPM25 ~ 1 + logSAT + logPOP + DUST + SANOC + ELEVDIFFALTD +
  approximate_location + pm25_calc + unspecified_type +
  logSAT*pm25_calc +
  logSAT*unspecified_type +
  logSAT*approximate_location +
  f(idgridcell,model="iid") +
  f(country_code_1,model="iid")+ f(reporting_region_name_1, model="iid") + f(Super_region_name_1, model="iid") + 
  f(country_code_2,logSAT,model="iid")+ f(reporting_region_name_2,logSAT,model="iid") + f(Super_region_name_2,logSAT,model="iid") + 
  f(country_code_3,logPOP,model="besag",graph="world.adj") + f(reporting_region_name_3,logPOP,model="iid") + f(Super_region_name_3,logPOP,model="iid") 
  
#########################################
### Initial Run - Without predictions ###
#########################################
# Running Model
result  <- inla(formula, family="gaussian",
                data=modelling_df,
                control.compute=list(dic=TRUE))

# Extracting modes to run next 
theta <- result$mode$theta

# Extracting Predictions
tmp <- result$summary.linear.predictor[,c('mean','sd','0.025quant','0.5quant','0.975quant')]
names(tmp) <- c('mean','sd','lower','median','upper')
modelling_df <- cbind(modelling_df,tmp)

#####################
### Saving Output ###
#####################
# Saving output
save(theta,file='theta.RData')
save(modelling_df,file='GM_out.RData')

# Clearing Workspace at the end
rm(list=ls())