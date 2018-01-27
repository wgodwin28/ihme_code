#----HEADER-------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 3/2/2016
# Purpose: Do some test regressions and create diagnostics to inform covariate transformation
# This code will: 
# 1. Create all applicable transformations for each covariate in your model
# 2. Create simple scatterplots of each transformation against your data
# 3. Run a simple linear regression of the transformed covariate vs. your data & show output
# 4. Create diagnostic plots from this regression, including:
# 4. a) Residuals vs Fitted Values
# 4. b) Scale-Location plot (sqrt(|residuals|)) v. Fitted values
# 4. c) Normal Q-Q Plot
# 4. d) Residuals vs. Leverages

# Guide for interpretting the plots: http://stats.stackexchange.com/questions/58141/interpreting-plot-lm
#***********************************************************************************************************************

#----CONFIG-------------------------------------------------------------------------------------------------------------
#+ configure-settings, include=FALSE
# set default width
options(width=120)

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
library("pacman")
library("magrittr")
pacman::p_load(car, data.table, knitr, lme4, magrittr, ggplot2, ggthemes, pander, readstata13, reshape2)

# set working directories
home.dir <- file.path(j_root, "temp/wgodwin/")
setwd(home.dir)

# set parameters
data.transformation <- "logit" # either "log", "logit", or "none"
id.vars <- c("ihme_loc_id", "year_id", "age_group_id", "sex_id", 'nid')
cov.vars <- c("ldi_pc", 'education_yrs_pc', "prop_urban", "sds")

# in/out
# in
data.dir <- file.path(home.dir, 'gpr_input/run4')
all.data <- file.path(data.dir, "wash_water_imp7.dta") %>% readstata13::read.dta13() %>% as.data.table()
# out
graphs.dir <- file.path(home.dir, 'diagnostics/covariates') %>% dir.create(recursive=T)

#function library
#+setup functions, include=FALSE

#define a custom function to transform your dependent variable
#this will take its default arg from whatever you set data.transformation to be
dataTransform <- function(x,
                          type=data.transformation) {
  switch(type,
         none = x,
         log = log(x),
         logit = logit(x))
}

covTransform <- function(dt,
                         identifiers,
                         cov) {
  
  message("transforming ", cov)
  
  # first, subset your dt down to only the cov of interest
  dt <- dt[, c(id.vars, cov, 'data'), with=F]
  
  # make sure the variable isn't already present in logspace
  if (grepl("ln_", cov) == FALSE) {
    # if not, we can assume the variable is already in normalspace
    
    message("+transforming to logspace")
    # create a version in logspace
    dt[, paste0("ln_", cov) := get(cov) %>% log(), with=F]
    
    # also return the range of the normalspace version to see if it fits logitspace assumptions
    range <- dt[, cov, with=F] %>% range()
    
    # test that the variable's range is between 0 and 1
    if (range[1] >= 0 & range[2] <= 1) {
      
      message("+transforming to logitspace")
      
      # if so, transform to logitspace (with a minute shift to ensure that max values don't return Infinite)
      dt[, paste0("lt_", cov) := (get(cov)-0.0001) %>% exp() %>% logit(), with=F]
      
    } else message("-logitspace not applicable") # if not, the transformation is complete    
    
    # finally, rename the variable to make current space explicit
    setnames(dt, cov, paste0('norm_', cov)) 
    
  } else { 
    # if already logged, first create a version in normalspace
    
    message("+transforming to normalspace")
    
    dt[, gsub("ln", "norm", cov) := get(cov) %>% exp(), with=F]
    
    # also return the range of the normalspace version to see if it fits logitspace assumptions
    range <- dt[, gsub("ln", "norm", cov), with=F] %>% range()
    
    # test that the variable's range is between 0 and 1
    if (range[1] >= 0 & range[2] <= 1) {
      
      message("+transforming to logitspace")
      
      # if so, transform to logitspace (with a minute shift to ensure that max values don't return Infinite)
      dt[, gsub("ln", "lt", cov) := (get(cov)-0.0001) %>% exp() %>% logit(), with=F]
      
    } else message("-logitspace not applicable") # if not, the transformation is complete 
    
  }
  
  # melt your dataset to prepare for graphing
  molten <- melt(dt, id.vars = c(id.vars, 'data'))
  
  return(molten)
  
}

#define a custom function to run the regression and then create some diagnostic plots
covCompare <- function(dt,
                       cov) {
  
  # create a basic scatterplot
  p1 <- ggplot(dt[variable==cov,], aes(x = data, y = value, color = ihme_loc_id)) + 
    facet_wrap(~age_group_id) +
    geom_point() +
    geom_abline(slope=1) +
    labs(title = paste0(cov),
         x = "data",
         y = "covariate") +
    scale_color_discrete(guide=F) +
    theme_tufte() +
    theme(plot.title=element_text(size=22))
  
  print(p1)
  
  # do a simple regression of your current covariate transformation against your data
  lm.simple <- lm(data=dt[variable==cov,], data ~ value)
  summary(lm.simple) %>% print()
  
  # create some basic regression diagnostic plots
  layout(matrix(1:4, ncol = 2))
  plot(lm.simple, which=c(1:3, 5))
  layout(1)
  
}
#***********************************************************************************************************************

#----PREP---------------------------------------------------------------------------------------------------------------
#+ prep-data, include=FALSE, cache=TRUE
# selected chunk opts do not print the output here and cache my prepped data to save time on rerun

#set up a datatable for graphing and regressions
#need to create all my various permutations and name them properly

#subset your square dataset to real datapoints only and keep the variables you are interested in
raw <- all.data[is.na(data)==F, c(id.vars, cov.vars, 'data'), with=F]

#transform your data in the same way you will for the ST-GPR run
raw[, data := dataTransform(data)]

#use your custom function to create all covariate transformations
transformed <- lapply(cov.vars, covTransform, dt=raw, identifiers=id.vars) %>% rbindlist()
#***********************************************************************************************************************

#----GRAPH--------------------------------------------------------------------------------------------------------------
#+loop-over-covariates, include=TRUE, fig.width=10, fig.height=10
# now apply the compare function to your list of transformed covariates
lapply(unique(transformed$variable), covCompare, dt=transformed)
#***********************************************************************************************************************

#----TEST FULL----------------------------------------------------------------------------------------------------------
#+advanced-modeling-prep, include=FALSE

# once you have narrowed down on a possible transformation, you can test it with your full model here
# all.data[, data := dataTransform(data)]
# all.data[, lt_prop_urban := logit(prop_urban + 0.0001)]
# all.data[, ln_prop_urban := log(prop_urban)]
# setnames(all.data, "prop_urban", "normal_prop_urban")

#+advanced-modeling-run, include=TRUE

# lm.lt <- lmer(data=all.data, 
#                  data ~ as.factor(age_group_id) + lt_prop_urban:as.factor(super_region_id) + geometric_mean + 
#                  outphase_smooth + ln_LDI_pc + (1|location_id) + (1|region_id))
#   summary(lm.lt) %>% print()
# 
# lm.ln <- lmer(data=all.data, 
#               data ~ as.factor(age_group_id) + ln_prop_urban:as.factor(super_region_id) + geometric_mean + 
#                 outphase_smooth + ln_LDI_pc + (1|location_id) + (1|region_id))
#   summary(lm.ln) %>% print()
#   
# lm.norm <- lmer(data=all.data, 
#               data ~ as.factor(age_group_id) + normal_prop_urban:as.factor(super_region_id) + geometric_mean + 
#                 outphase_smooth + ln_LDI_pc + (1|location_id) + (1|region_id))
#   summary(lm.norm) %>% print()
#***********************************************************************************************************************