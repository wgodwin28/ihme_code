#Purpose: Pop weight night time lights for BRA and MEX VR data
#Output should have average daily temperature by admin 2 level for each day, saved by year
#source('/snfs2/HOME/wgodwin/temperature/era_interim/municipality_prep_erac.R', echo = T)
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
start <- 2016
end <- 2016
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/total/1y/")
lights.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/dmspntl/mean/1y/")
shapefile.dir = paste0(j, "WORK/05_risk/risks/temperature/data/exp/shapes/", iso, "/")
cov.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/", iso, "/all_age/")
dir.create(cov.dir)
source(paste0(j, "temp/central_comp/libraries/current/r/get_ids.R"))

########Read in shapefile and extract##########
borders <- readOGR(paste0(shapefile.dir, iso, "_admin2.shp"))

########################################################################################
###############################Night time lights and pop extraction#####################
########################################################################################
for (year in start:end) {
  #Read in night-time lights data
  #lights <- raster(paste0(lights.dir, 'dmspntl_mean_1y_',year,'_00_00', '.tif'))
  #lights <- crop(lights, borders)
  
  #Read in and crop pop
  pop <- raster(paste0(pop.dir, 'worldpop_total_1y_',year,'_00_00', '.tif'))
  pop <- crop(pop, borders)
  
  #pop weight night-lights values
  #lights <- lights * pop
  
  #extract weighted night lights values to sum up to the municipality level
  #muni_lights <- extract(lights, borders, fun = sum, na.rm = T) %>% as.data.table
  #muni_lights <- cbind(muni_lights,as.numeric(as.character(borders@data$adm2_code)), as.character(borders@data$adm2_name)) %>% as.data.table
  #if(iso == "bra"){muni_lights[, V2 := substr(V2, 0,6)]}
  #setnames(muni_lights, c("V1","V2", "V3"), c("nght_lghts", "adm2_id", "adm2_name"))
  
  #do the same for population
  muni_pop <-  extract(pop, borders, fun = sum, na.rm = T) %>% as.data.table
  muni_pop <- cbind(muni_pop,as.numeric(as.character(borders@data$adm2_code)), as.character(borders@data$adm2_name)) %>% as.data.table
  if(iso == "bra"){muni_pop[, V2 := substr(V2, 0,6)]}
  setnames(muni_pop, c("V1","V2", "V3"), c("population", "adm2_id", "adm2_name"))
  muni_pop <- muni_pop[, lapply(.SD, sum, na.rm = T), .SDcols = "population", by = c("adm2_id", "adm2_name")]
  
  #Merge together and calculate weighted night-lights
  #dt <- merge(muni_lights, muni_pop, by = c("adm2_id", "adm2_name"))
  #dt[, lights := nght_lghts/population]
  dt <- copy(muni_pop)
  dt[, year_id := year]
  write.csv(dt, paste0(cov.dir, "pop_", year, ".csv"), row.names = F)
  print(year)
}

#compile and save together
files <- list.files(cov.dir, full.names = T)
dt <- rbindlist(lapply(files, fread), fill = T)
dt[, nght_lghts := NULL]
write.csv(dt, paste0(cov.dir, "pop_full.csv"), row.names = F)

##################################################################################
##########Just population-age specific pops prep##################################
##################################################################################
##Run toggles set above
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/")
cov.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/", iso, "/age_specific/")
dir.create(cov.dir, recursive = T)

##GBD age_group_ids that correspond to the file saving structure in MBG directory
template <- data.table(age_string = c("0004", "0509", "1014", "1519",
                                      "2024", "2529", "3034", "3539",
                                      "4044", "4549", "5054", "5559",
                                      "6064", "65pl"),
                       age_group_id = c("236", "6", "7", "8", "9", 
                                        "10", "11", "12", "13", "14", 
                                        "15", "16", "17", "154"))

## Loop through age,year,sex combinations for each country we want admin2 pops for
ages <- unique(template$age_string)
for(year in start:end){
  for(age in ages){
    for(sex in c("m", "f")){
      #Read in and crop pop
      pop <- raster(paste0(pop.dir, "a",age,sex,"/1y/worldpop_a", age, sex,"_1y_", year,"_00_00.tif"))
      pop <- crop(pop, borders)
      
      #pop weight night-lights values
      #lights <- lights * pop
      
      #extract weighted night lights values to sum up to the municipality level
      #muni_lights <- extract(lights, borders, fun = sum, na.rm = T) %>% as.data.table
      #muni_lights <- cbind(muni_lights,as.numeric(as.character(borders@data$adm2_code)), as.character(borders@data$adm2_name)) %>% as.data.table
      #if(iso == "bra"){muni_lights[, V2 := substr(V2, 0,6)]}
      #setnames(muni_lights, c("V1","V2", "V3"), c("nght_lghts", "adm2_id", "adm2_name"))
      
      #do the same for population
      muni_pop <-  extract(pop, borders, fun = sum, na.rm = T) %>% as.data.table
      muni_pop <- cbind(muni_pop,as.numeric(as.character(borders@data$adm2_code)), as.character(borders@data$adm2_name)) %>% as.data.table
      if(iso == "bra"){muni_pop[, V2 := substr(V2, 0,6)]}
      setnames(muni_pop, c("V1","V2", "V3"), c("population", "adm2_id", "adm2_name"))
      
      #Merge together and calculate weighted night-lights
      #dt <- merge(muni_lights, muni_pop, by = c("adm2_id", "adm2_name"))
      #dt[, lights := nght_lghts/population]
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

#rbind and save
files <- list.files(cov.dir, pattern = ".csv", full.names = T)
dt <- rbindlist(lapply(files, fread))
write.csv(dt, paste0(cov.dir,"pop_full.csv"), row.names = F)

############################################################################
iso <- "nza"
dt <- fread(paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/", iso, "/age_specific/pop_full.csv"))
dt[age_group_id == 236, age_mid := 2.3]
dt[age_group_id == 6, age_mid := 7.5]
dt[age_group_id == 7, age_mid := 12.5]
dt[age_group_id == 8, age_mid := 17.5]
dt[age_group_id == 9, age_mid := 22.5]
dt[age_group_id == 10, age_mid := 27.5]
dt[age_group_id == 11, age_mid := 32.5]
dt[age_group_id == 12, age_mid := 37.5]
dt[age_group_id == 13, age_mid := 42.5]
dt[age_group_id == 14, age_mid := 47.5]
dt[age_group_id == 15, age_mid := 52.5]
dt[age_group_id == 16, age_mid := 57.5]
dt[age_group_id == 17, age_mid := 62.5]
dt[age_group_id == 154, age_mid := 73]

dt <- dt[, lapply(.SD, sum), .SDcols = "population", by = c("adm2_id", "year_id", "age_mid")]
dt[, x := age_mid * population / sum(population), by=c("adm2_id","year_id")]
dt[, pop_big := lapply(.SD, sum), .SDcols = "population", by = c("adm2_id", "year_id")]
dt[, pop_weight := population/pop_big]
dt[, age_weighted := pop_weight * age_mid]
dt <- dt[, lapply(.SD, sum), .SDcols = "age_weighted", by = c("adm2_id", "year_id")]

###Proportion of population in broad age bins
iso <- "mex"
dt <- fread(paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/", iso, "/age_broad/pop_full.csv"))
dt <- dt[, lapply(.SD, sum), .SDcols = "population", by = c("adm2_id", "year_id", "age_group_id")]
dt[, pop_big := lapply(.SD, sum), .SDcols = "population", by = c("adm2_id", "year_id")]
dt[, pop_weight := population/pop_big]
dt.temp <- dt[age_group_id == 39]
setnames(dt.temp, c("adm2_id", "pop_weight"), c("adm2_id_res", "pop_prop_0_15"))
dt.temp <- dt.temp[,.(adm2_id_res, year_id, pop_prop_0_15)]
full8 <- merge(full7, dt.temp, by = c("adm2_id_res", "year_id"), all.x = T)
full8[is.na(pop_prop_45_plus), pop_prop_45_plus := pop_prop_45_plus2]
full8$pop_prop_15_452 <- NULL

setnames(full8, c("pop_prop_0_15.x", "age_weighted"), c("pop_prop_0_15", "age_mean"))
write.csv(full8, "/home/j/WORK/05_risk/risks/temperature/data/rr/rr_analysis/nzl_mex_clean_ages.csv", row.names = F)

