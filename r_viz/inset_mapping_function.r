## Install  the following packages if necessary
 ##  install.packages("RColorBrewer")
  ## install.packages("maptools")
##

## load the function
  rm(list=ls())
  source("J:/DATA/SHAPE_FILES/GBD_geographies/master/GBD_2015/inset_maps/noSubs/GBD_WITH_INSETS_MAPPING_FUNCTION.r")
  library(foreign)
  library(RColorBrewer)
  library(maptools)
  
## read in and format data
  data <- read.csv("J:/WORK/05_risk/risks/air_hap/02_rr/02_output/PM2.5 mapping/lit_db/amb_adjustment/v2/amb_exp.csv") ## your data must have 1 obs per country and two variables: "ihme_loc_id", and "mapvar"
  #data <- read.dta("J:/temp/wgodwin/review_week/collapse_improved_san.dta", convert.factor=F)
  #data <- read.table("FILE.txt", header=T)

  
## make map
  gbd_map(data=data,
          limits=c(0,25,50,75,100,125,150,175,200,225,250), # change to whatever bins make sense for your data
	  #label=c(,,,,,,, ), # label bins in the legend
          col="RdYlBu", # choose palette
          col.reverse=T, #reverse palette if you want
          title="Number of observations for PM 2.5 Model", # map title
	        na.color = "dark gray",
          fname="J:/WORK/05_risk/risks/air_hap/02_rr/02_output/01_pm_mapping/lit_db/amb_adjustment/v2/pm_data_map.pdf") # save as .tif .eps or .pdf
  
	          