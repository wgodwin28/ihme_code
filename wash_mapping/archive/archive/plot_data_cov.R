#install.packages("fields")
library(fields)
library(raster)
library(dplyr)
library(data.table)


### WATER ###
repo <- '/share/code/geospatial/adesh/mbg/'
indicator_group <- 'wash'

## Load libraries and miscellaneous MBG project functions.
setwd(repo)
root <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
package_lib <- paste0(root,'/temp/geospatial/packages') # Library for all MBG versioned packages. Ensures that none of this code is
#    dependent on the machine where the user runs the code.
.libPaths(package_lib)                                  # Ensures packages look for dependencies here when called with library(). 
#    Necessary for seeg libraries.
source('mbg_central/mbg_functions.R')                   # Functions to run MBG model.
source('mbg_central/prep_functions.R')                  # Functions to setup MBG run
source('mbg_central/covariate_functions.R')             # Functions to prep and transform 5*5 covariates
source('mbg_central/misc_functions.R')                  # Other computational MBG-related functions.
source('mbg_central/post_estimation_functions.R')
source('mbg_central/gbd_functions.R')
source('mbg_central/shiny_functions.R')
source('mbg_central/holdout_functions.R')
source('mbg_central/stacking_functions.R')
source('mbg_central/categorical_variable_functions.R')
source('mbg_central/seegMBG_transform_functions.R')     # Using Roy's edit for now that can take temporally varying covariates,
#   TODO: will need to send pull request to seegMBG of github
package_list <- c('foreign', 'rgeos', 'data.table','raster','rgdal','INLA','seegSDM','seegMBG','plyr','dplyr')
for(package in package_list) {
  library(package, lib.loc = package_lib, character.only=TRUE)
}


input_data <- read.csv("/snfs1/WORK/11_geospatial/10_mbg/input_data/w_piped.csv")

df <- input_data
df <- mutate(df, shapefile = point)
df$shapefile[which(df$point == 0)] <- NA
df <- data.table(df)
test  <- graph_data_coverage_values(df = df, var = "w_piped", out_file = "/homes/adesh/mbg_results/water/feb-13-17/jon_plot.png", title="Water Data Coverage",
                                year_min= 1985,
                                year_max = 2016,
                                year_var = "year",
                                region = "africa",
                                sum_by = "psu",
                                cores = 4, indicator = "w_piped", high_is_bad = T, return_maps = T, legend_title = "legend")


