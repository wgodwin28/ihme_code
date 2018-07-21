#Purpose: Prep age-specific populations
rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

# load packages, install if missing  
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
pacman::p_load(data.table, fst, ggplot2, parallel, magrittr, maptools, raster, rgdal, rgeos, sp, splines, stringr, RMySQL, snow, ncdf4)

#Set toggles
iso <- "bra"
start <- 2008
end <- 2016
source(paste0(j, "temp/central_comp/libraries/current/r/get_ids.R"))
shapefile.dir = paste0(j, "WORK/05_risk/risks/temperature/data/exp/shapes/", iso, "/")
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/")
cov.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/", iso, "/age_specific/")
out.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/", iso, "/age_broad/")
dir.create(out.dir, recursive = T)
dir.create(cov.dir, recursive = T)

########Read in shapefile and extract##########
borders <- readOGR(paste0(shapefile.dir, iso, "_admin2.shp"))

####################################################################################################
##########Compile and extract age-specific populations for each relevant country in RR analysis#####
####################################################################################################
template <- data.table(age_string = c("0004", "0509", "1014", "1519",
                                      "2024", "2529", "3034", "3539",
                                      "4044", "4549", "5054", "5559",
                                      "6064", "65pl"),
                       age_group_id = c("236", "6", "7", "8", "9", 
                                        "10", "11", "12", "13", "14", 
                                        "15", "16", "17", "154"))

#loop through age, year, and sex specific rasters to sum to broad age bins, then extract from rasters
ages <- unique(template$age_string)
for (year in start:end) {
  for(sex in c("m", "f")){
    for(age in ages){
      #Read in and crop pop
      pop <- raster(paste0(pop.dir, "a",age,sex,"/1y/worldpop_a", age, sex,"_1y_", year,"_00_00.tif"))
      pop <- crop(pop, borders)
      
      #do the same for population
      muni_pop <-  extract(pop, borders, fun = sum, na.rm = T) %>% as.data.table
      muni_pop <- cbind(muni_pop,as.numeric(as.character(borders@data$adm2_code)), as.character(borders@data$adm2_name)) %>% as.data.table
      if(iso == "bra"){muni_pop[, V2 := substr(V2, 0,6)]}
      setnames(muni_pop, c("V1","V2", "V3"), c("population", "adm2_id", "adm2_name"))
      
      #Merge together and calculate weighted night-lights
      dt <- copy(muni_pop)
      dt[, year_id := year]
      s <- ifelse(sex == "m", 1,2)
      dt[, sex_id := s]
      a <- template[age_string == age, age_group_id]
      dt[, age_group_id := a]
      write.csv(dt, paste0(cov.dir, "pop_", year, "_", age, "_", sex, ".csv"), row.names = F)
      print(paste(sex, age, year))
    }
  }
}

#Append together and save for RR models
files <- list.files(cov.dir, pattern = ".csv", full.names = T)
dt <- rbindlist(lapply(files, fread))
write.csv(dt, paste0(cov.dir,"pop_full.csv"), row.names = F)

#########sum over specific age bins to generate pops by broad age categories(0-15, 15-45, 45+)##############
dt <- fread(paste0(cov.dir,"pop_full.csv"))
setnames(dt, "age_group_id", "age_specific")
dt[age_specific == 236 | age_specific == 6 | age_specific == 7, age_group_id := 39]
dt[age_specific == 8 | age_specific == 9 | age_specific == 10 | age_specific == 11 | age_specific == 12 | age_specific == 13, age_group_id := 156]
dt[age_specific == 14 | age_specific == 15 | age_specific == 16 | age_specific == 17 | age_specific == 154, age_group_id := 223]
dt <- dt[, lapply(.SD, sum), .SDcols = "population", by = .(adm2_id, adm2_name, year_id, sex_id, age_group_id)]

#save
write.csv(dt, paste0(out.dir,"pop_full.csv"), row.names = F)
