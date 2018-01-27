#----HEADER-------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 06/27/2016
# Project: RF: air_pm
# Purpose: Create comparison plots for PM2.5 exposure
# source("/homes/jfrostad/_code/risks/air_pm/exp/02_graph.R", echo=T)
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
exp.versions <- c(7,8) #versions to compare

# load packages, install if missing
pacman::p_load(data.table, ggplot2, grid, gridExtra, magrittr, stringr)

# set working directories
home.dir <- file.path(j_root, "WORK/05_risk/risks/air_pm/")
setwd(home.dir)
#***********************************************************************************************************************

#----IN/OUT-------------------------------------------------------------------------------------------------------------
##in##
data.dir <- file.path(home.dir, 'products/exp')

##out##
graphs.dir <- file.path(home.dir, 'diagnostics/exp')
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

# this bash script will append all csvs to create a global file, then create national files for each subnational country
aggregateResults <- function(version) {
  paste0("bash ", file.path(h_root, "_code/risks/air_pm/exp/01b_aggregate_results.sh"), " ", version) 
}
#***********************************************************************************************************************
 
#----PREP---------------------------------------------------------------------------------------------------------------
#run bash script to append all countries 
lapply(exp.versions, function(v) aggregateResults(v) %>% system) #run a bash script that will append all the results to create a global csv

#read in the appended datasets
data.list <- lapply(exp.versions, function(v) file.path(data.dir, v, 'summary', 'all.csv') %>% fread %>% setkeyv(c('iso3', 'year')))
#merge
all.data <- merge(data.list[[1]], data.list[[2]], all.x=TRUE)

ggplot(data=all.data[year==1990],
       aes(x=exp_mean.x,
           y=exp_mean.y,
           label=iso3)) +
  geom_text() +
  geom_abline(slope=1) +
  theme_bw()
