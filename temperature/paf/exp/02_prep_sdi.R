#Purpose: Prep pixel level SDI for PAF calculator and Relative Risk models
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
pacman::p_load(data.table, fst, ggplot2, parallel, magrittr, maptools, raster, rgdal, rgeos, sp, splines, stringr, RMySQL, snow, ncdf4, feather)

#############################################################################################################
################PIXEL LEVEL SDI POP WEIGHTING PREP###########################################################
#############################################################################################################
#Settings
in.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/rr/rr_analysis/sdi_pred/")
data.dir <- paste0(j,"WORK/05_risk/risks/temperature/data/exp/prepped/mean/era_interim/")
iso <- "bra" #bra, mex, nza, gtm
meta.dir <- paste0(j,"WORK/05_risk/risks/temperature/data/exp/prepped/", iso,"/")
shapefile.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/shapes/", iso, "/")
out.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/rr/rr_analysis/sdi_prepped/", iso, "/")
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/total/1y/")
dir.create(out.dir, showWarnings = F)

#Bring in sdi for later
source(paste0(j, "temp/central_comp/libraries/current/r/get_covariate_estimates.R"))
dt.sdi <- get_covariate_estimates(covariate_id = 881)[,.(location_id, year_id, mean_value)]
setnames(dt.sdi, "mean_value", "sdi_denom")

#read in file and crop to borders of specified country
brik <- brick(paste0(data.dir, "1990_mean_meanmethod.nc"))
brik <- brik[[1]]
brik <- rotate(brik)

########Read in shapefile and extract##########
borders <- readOGR(paste0(shapefile.dir, iso, "_admin2.shp"))
miss.adm2 <- 2605459 # 2605459 # Scrap
borders <- subset(borders, adm2_code == miss.adm2) #Scrap

b <- raster()
extent(b) <- extent(borders)
res(b) <- .05

#loop through years
for(year in 1990:2013){
  #import raster
  r <- raster(paste0(in.dir, "SDIPred.M2r_", year, ".tif"))
  r <- crop(r, borders)
  
  #import population and resample to .05 x .05 resolution in order to multiply easier
  pop <- raster(paste0(pop.dir, 'worldpop_total_1y_',year,'_00_00', '.tif'))
  pop <- crop(pop, borders)
  pop <- resample(pop, b, method = "bilinear")
  
  #multiply sdi times pop and resample to .05 x .05 resolution
  r <- resample(r, b, method = "ngb")
  r <- r * pop
  
  #Aggregate both pop-weighted sdi and population to resolution of temperature raster
  r <- aggregate(r, fact = 10, fun = sum)
  #pop <- aggregate(pop, fact = 10, fun = sum, na.rm = T)
  pop <- cellStats(pop, mean) #
  #divide by pop
  r <- r/pop
  
  #r <- resample(r, brik, method = "ngb")
  
  #extract for modeling at adm2 level
  data <- extract(r, borders, fun = mean, na.rm = T, method = "bilinear") %>% as.data.table
  data <- cbind(data,as.numeric(as.character(borders@data$adm2_code)), as.character(borders@data$adm2_name)) %>% as.data.table
  setnames(data, c("V1", "V2", "V3"), c("sdi", "adm2_id", "adm2_name"))
  if(iso == "bra"){data[, adm2_id := substr(adm2_id, 0,6)]}
  
  if(iso == "bra"){miss.adm2 <- substr(miss.adm2, 0,6)} #
  sdi.miss <- data$sdi #
  d <- fread(paste0(out.dir, "sdi_", year, ".csv")) #
  d[adm2_id == miss.adm2, sdi := sdi.miss] #
  write.csv(d, paste0(out.dir, "sdi_", year, ".csv"), row.names = F) #
  
  #Clean and save
  #data[, year_id := year]
  #write.csv(data, paste0(out.dir, "sdi_", year, ".csv"), row.names = F)
  print(year)
}

###Work around to interpolate post 2013 since no nighttime lights estimates post 2013########################
iso <- "bra" #bra, mex, nza, gtm
meta.dir <- paste0(j,"WORK/05_risk/risks/temperature/data/exp/prepped/", iso,"/")
shapefile.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/shapes/", iso, "/")
out.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/rr/rr_analysis/sdi_prepped/", iso, "/")

#read in adm2 map to merge on location_id that applies to each municipality
dt <- fread(paste0(out.dir, "sdi_2013.csv"))
meta <- fread(paste0(meta.dir, "admin2_map.csv"))[,.(adm2_id, location_id)]
dt <- merge(dt, meta, by="adm2_id", all.x = T)

#merge on with 2013 estimates to generate ratio and either back extrapolate or forward extrapolate
dt <- merge(dt, dt.sdi, by = c("location_id", "year_id"), all.x = T)
dt[, sdi_ratio := sdi/sdi_denom]
dt.ratio <- dt[,.(adm2_id, sdi_ratio)]
for(year in 2014:2017){
  dt.temp <- dt[,.(adm2_id, year_id, location_id)]
  dt.temp[, year_id := year]
  dt.temp <- merge(dt.temp, dt.sdi, by = c("location_id", "year_id"), all.x = T)
  dt.temp <- merge(dt.temp, dt.ratio, by = "adm2_id")
  dt.temp[, sdi := sdi_denom * sdi_ratio]
  dt.temp <- dt.temp[,.(adm2_id, year_id, sdi)]
  write.csv(dt.temp, paste0(out.dir, "sdi_", year, ".csv"), row.names = F)
}

#Append together
for (c in c("bra", "mex")){
  out.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/rr/rr_analysis/sdi_prepped/",c, "/")
  files <- list.files(out.dir, full.names = T)
  t <- rbindlist(lapply(files, fread), fill = T)
  t <- t[, lapply(.SD, mean), .SDcols = "sdi", by= c("adm2_id", "adm2_name", "year_id")] #take the mean of any locations that may have the same adm2_id (only really applies to one adm2 in GTM)
  write.csv(t, paste0(out.dir, "sdi_all.csv"), row.names = F)
}

#############################################################################################################
################SDI PREP FOR PAF CALCULATOR##################################################################
#############################################################################################################
#Settings
in.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/rr/rr_analysis/sdi_pred/")
data.dir <- paste0(j,'WORK/05_risk/risks/temperature/data/exp/prepped/mean/era_interim/')
pop.dir <- paste0(j, "WORK/11_geospatial/01_covariates/00_MBG_STANDARD/worldpop/total/1y/")
out.dir <- paste0("/share/epi/risk/temp/temperature/exp/sdi/")
max.cores <- 6

#pull in global shapefile
borders <- readOGR(paste0(j,"DATA/SHAPE_FILES/GBD_geographies/master/GBD_2017/master/shapefiles"), layer = "GBD2017_analysis_final")

#loop through each year
for(year in 1991:2013){
  #read in and crop sdi raster
  r <- raster(paste0(in.dir, "SDIPred.M2r_", year, ".tif"))
  r <- crop(r, borders)
  
  #Prep appropriate temperature grip to resample from
  brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
  brik <- rotate(brik) # b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
  brik <- crop(brik, borders)
  
  #aggregate population to the exposure cell size
  r_fact <- round(dim(r)[1:2] / dim(brik)[1:2])
  r <- aggregate(r, r_fact)
  r <- resample(r, brik[[1]])
  
  #Convert to data table and set variable names
  r <- setDT(as.data.frame(r, xy = T))
  setnames(r, c("x", "y", paste0("SDIPred.M2r_", year)), c("long", "lat", "sdi"))
  
  #Save in order for merging in paf caculation
  print(year)
  write_feather(r, paste0(out.dir, "gridded_sdi_", year, ".feather"))
}

#bring in dataset that links each coordinate with appropriate GBD location_id
loc.coords <- read_feather()