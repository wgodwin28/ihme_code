###########################################################
### Author: Patrick Liu3
### Date: 1/26/2015
### Project: ubCov
### Purpose: Script to run prior model
###########################################################

###################
### Setting up ####
###################
rm(list=ls())
library(plyr)
library(foreign)
library(splines)
library(boot)
library(data.table)
library(stats)
library(lme4)

## OS locals

  rm(list=objects())
      os <- .Platform$OS.type
      if (os == "windows") {
        jpath <- "J:/"
      } else {
        jpath <- "/home/j/"
      }


###################################################################
# Model Toggles
####################################################################

args <- commandArgs(trailingOnly = TRUE)
me_name 	   <- args[1]
data_id 	   <- args[2]
model_id	   <- args[3]
central_root <- args[4]
run_root 	   <- args[5]
model_root   <- args[6]
output_root  <- args[7]

## Debug
me_name 	 <- "wash_water_imp"
data_id 	 <- 55
model_id 	 <- 72
run_id    <- 13
central_root <- "H:/git/ubCov_central/_modules/04_model"
run_root 	 <- "/clustertmp/ubcov/04_model/mean_sbp/1/2/9"
run_root 	 <- "J:/temp/wgodwin/gpr_input/run4"



## Bring in model_db
param <- fread("H:/ubcov/04_model/_db/wash_water_imp/model_db.csv")
prior_model <- param$prior_model[param$run_id == run_id]
data_transform <- param$data_transform[param$run_id == run_id]
model_type <- param$model_type[param$run_id == run_id]

#####################################################################
### Prepping Data 
#####################################################################

## Set df
df <- fread(paste0(run_root, "/wash_water_imp7.csv"))

## Set cross-validation 
df[train==0, holdout := data]
df[train==0, data := NA]


#####################################################################
### Baseline Model 
#####################################################################

## Prepare empty frame for model fit statistics
mod_summary <- NULL

## If prior trying to pass prior
if (prior_model != "none") {
  
  ## LMER4
  if (model_type == "lmer") {
    for (sex in unique(df$sex_id)) {
      ## Run model
      mod <- lmer(as.formula(paste0(prior_model, " + (1|location_id) + (1|region_name) + (1|super_region_name)")), data=df[df$sex_id==sex,], na.action=na.omit)
      mod2 <- lmer(as.formula(paste0(prior_model, "+ (1|region_name)")), data=df[df$sex_id==sex,], na.action=na.omit)
      ## Predict
      df[sex_id == sex, prior := predict(mod, newdata=df[df$sex_id==sex,], allow.new.levels=TRUE, re.form = NA)]
      ## Grab model fit statistics
      stats3 <- as.data.frame(summary(mod2)$coefficients)
      names(stats3) <- c("beta_re_region", "se", "t_value")
      stats$cov <- rownames(stats)
      stats <- stats[,c("cov", "beta", "se", "t_value")]
      sex_id<-sex
      stats <- cbind(me_name, data_id, model_id, sex_id, stats)
      mod_summary <- rbind(stats, mod_summary)
      ## Calculate the R^2 value
      get_r2 <- lm(model.response(model.frame(mod)) ~ predict(mod))
      r2 <- signif(summary(get_r2)$r.squared, 2)
      ## Print model summary to output root if full run
      if (min(df$train, na.rm=TRUE) == 1) {
        sink(paste0(output_root, "/", me_name, "_data_id_", data_id, "_model_id_", model_id, "_sex_id_", sex,".txt"), type="output")
        print(paste0("Your estimated model R-squared value is: ", r2))
        print(summary(mod))
        sink()
      }
    }
  }
  
  ## LM
  if (model_type == "lm") {
    for (sex in unique(df$sex_id)) {
      ## Run model
      mod <- lm(as.formula(paste0(prior_model)), data = df[df$sex_id==sex,], na.action=na.omit)
      ## Predict
      df[sex_id == sex, prior := predict(mod, newdata=df[df$sex_id==sex,])]
      ## Grab model fit statistics
      stats <- as.data.frame(summary(mod)$coefficients)
      names(stats) <- c("beta", "se", "t_value")
      stats$cov <- rownames(stats)
      stats <- stats[,c("cov", "beta", "se", "t_value")]
      sex_id<-sex
      stats <- cbind(me_name, data_id, model_id, sex_id, stats)
      mod_summary <- rbind(stats, mod_summary)
      ## Print model summary to output root if full run
      if (min(df$train, na.rm=TRUE) == 1) {
        sink(paste0(output_root, "/", me_name, "_data_id_", data_id, "_model_id_", model_id, "_sex_id_", sex,".txt"), type="output")
        print(summary(mod))
        sink()
      }    
    }
  }
  
}


#####################################################################
### Clean
#####################################################################

## Order
df <- df[order(ihme_loc_id, year_id, age_group_id, sex_id),]

## Save
write.csv(df, paste0(run_root, "/prior.csv"), row.names=FALSE, na="")

## Write model stats if full run
if (min(df$train, na.rm=TRUE) == 1) {
  write.csv(mod_summary, paste0(model_root, "/prior_summary.csv"), row.names=FALSE, na="")
}
