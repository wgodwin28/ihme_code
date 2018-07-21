#MAPS
rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

source("J:/WORK/05_risk/central/code/maps/global_map.R")
library(data.table)
library(ggthemes)
df <- fread("J:/temp/wgodwin/diagnostics/hwws/final_new2.csv")
global_map(data=df, map.var="mean", plot.title="Prevalence of Handwashing", output.path="J:/temp/wgodwin/diagnostics/new_hwws/hwws_map_final_new3.pdf", years=c(1990, 1995, 2000, 2005, 2010, 2015), ages = 22, sexes=3, subnat=TRUE, scale="cont", col="easter_to_earth", col.rev=FALSE)

source(paste0(j,'temp/central_comp/libraries/current/r/get_location_metadata.R'))
global_map(data=dt, map.var="mapvar", plot.title="Temperature PAF", output.path="J:/temp/wgodwin/test.pdf", years=c(2017), ages = 22, sexes=3, subnat=TRUE, scale="cont", col="easter_to_earth", col.rev=FALSE)


## load the function
rm(list=ls())
source(paste0(j, "DATA/SHAPE_FILES/GBD_geographies/master/GBD_2015/inset_maps/noSubs/GBD_WITH_INSETS_MAPPING_FUNCTION.R"))
source(paste0(j, "DATA/SHAPE_FILES/GBD_geographies/master/GBD_2015/inset_maps/allSubs/GBD_WITH_INSETS_MAPPING_FUNCTION.R"))

library(foreign)
library(RColorBrewer)
library(maptools)

## read in and format data
data <- read.csv("J:/WORK/05_risk/risks/air_hap/02_rr/02_output/PM2.5 mapping/lit_db/amb_adjustment/v2/amb_exp.csv") ## your data must have 1 obs per country and two variables: "ihme_loc_id", and "mapvar"
data <- fread(paste0(j, "/WORK/05_risk/risks/wash_water/data/exp/01_data_audit/treat_sources.csv"))
data <- fread(paste0(j, "/WORK/05_risk/risks/wash_water/data/exp/03_model/1/wash_water_piped.csv"))
#data <- read.dta("J:/temp/wgodwin/review_week/collapse_improved_san.dta", convert.factor=F)
#data <- read.table("FILE.txt", header=T)
data[, mapvar := 1]
data <- data[, lapply(.SD, sum), .SDcols = "mapvar", by = "ihme_loc_id"] 

## make map
gbd_map(data=data,
        limits=c(1,3,5,7), # change to whatever bins make sense for your data
        #label=c(,,,,,,, ), # label bins in the legend
        col="RdYlBu", # choose palette
        col.reverse=F, #reverse palette if you want
        title="Handwashing Input Data Coverage", # map title
        na.color = "dark gray",
        fname=paste0(j ,"WORK/05_risk/risks/wash_water/diagnostics/review_week/hwws_data_map.pdf")) # save as .tif .eps or .pdf

#Scatter comparison with JMP estimates
who.dt <- fread(paste0(j, "/WORK/05_risk/risks/wash_water/diagnostics/review_week/who_estimates/download.csv"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
locations <- get_location_metadata(location_set_id=22)[level == 3,.(location_id, ihme_loc_id, super_region_name, location_name)]

#Piped water
piped.who <- who.dt[service_level=="Piped improved"]
setnames(piped.who, c("country", "value"), c("ihme_loc_id", "data_who"))
piped.who[, data_who := data_who/100]
#piped.who <- piped.who[, lapply(.SD, sum), .SDcols = "data_who", by = c("ihme_loc_id")]
draws <- paste0("draw_",0:999)
data <- fread("/share/epi/risk/temp/wash_water/run2/wash_water_imp.csv")
data[, mean := rowMeans(.SD), .SDcols=draws]
data <- data[year_id == 2015]
data <- data[, .(location_id, mean)]
data <- merge(data, locations, by = "location_id")

#Merge with who
both <- merge(data, piped.who, by = "ihme_loc_id", all = T)
plot(both$mean, both$data_who)


##gg
p <- ggplot() + 
  geom_point(data = both, aes(x = mean3, y = imp, colour = super_region_name,
                              text = paste0("\nlocation: ", super_region_name)), alpha = .5) + 
  labs(x = "GBD estimates", y = "JMP estimates", 
       colour = "GBD super region")
print(p)


#Rachels function
source("/home/j/temp/wgodwin/r_viz/map_pafs.r")
#294-all cause
for (risk in c(331)) {
  map_PAF(rei=risk, national = F,cause=294, path_root="/home/j/temp/wgodwin/", years=c(2017))
}
