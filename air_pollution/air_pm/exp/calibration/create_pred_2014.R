#####################################################################################
### create_pred_2014.R - Code to run predictions for the world in 2014. It is     ###
### advised that you filter down the main grid to smaller areas as the calculation###
### in INLA require a vast amount of memory.                                      ###
#####################################################################################
### Inputs: PredData_GM.RData - Ground monitor data for modelling                 ###
###         Grid_Background_Data_2014.RData - 2014 Grid with background data for  ###
###                 predictions                                                   ###
###         theta.RData - Vector of Modes to speed up the INLA run from GM run    ###
###                                                                               ###
### Output: pred_2014.RData - Predictions for 2014                                ###
#####################################################################################

# Clearing Workspace from previous load
rm(list=ls())

# Loading INLA package
require(INLA)

# Loading data
load('PredData_GM.RData')
load('Grid_Background_Data_2014.RData')
load('theta.RData')

#####################
### Model formula ###
#####################
formula <- logPM25 ~ 1 + logSAT + logPOP + DUST + SANOC + ELEVDIFFALTD +
  approximate_location + pm25_calc + unspecified_type +
  logSAT*pm25_calc +
  logSAT*unspecified_type +
  logSAT*approximate_location +
  f(idgridcell,model="iid") +
  f(country_code_1,model="iid")+ f(reporting_region_name_1, model="iid") + f(reporting_region_name_1, model="iid") + 
  f(country_code_2,logSAT,model="iid")+ f(reporting_region_name_2,logSAT,model="iid") + f(reporting_region_name_2,logSAT, model="iid") + 
  f(country_code_3,logPOP,model="besag",graph="world.adj") + f(reporting_region_name_3,logPOP,model="iid") + f(Super_region_name_3,logPOP, model="iid") 

############################################################
### Creating dataset with necessary predictions appended ###
############################################################
modelling_df <- rbind(modelling_df,grid_2014)

############################
### Creating predictions ###
############################
# Running INLA
result  <- inla(formula, family="gaussian",
                data=modelling_df,
                control.mode=list(theta=theta,restart=FALSE),
                control.compute=list(dic=TRUE))

# Extracting Predictions from INLA run 
tmp <- result$summary.linear.predictor[,c('mean','sd','0.025quant','0.5quant','0.975quant')]
names(tmp) <- c('mean','sd','lower','median','upper')

# Appending onto original data
modelling_df <- cbind(modelling_df,tmp)

#####################
### Saving Output ###
#####################
# Saving output
save(modelling_df,file='pred_2014.RData')

# Clearing Workspace at the end
rm(list=ls())