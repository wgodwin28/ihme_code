################################################################################
## Purpose: Generate incidence of COPD due to HAP for China collab
## Date created: 11/02/2017
## Date modified:
## Author: Will Godwin, wgodwin@uw.edu
## Run instructions: source('/snfs2/HOME/wgodwin/risk_factors/wash/06_pafs/hap_copd_incidence.R', echo = T)
## Notes:
################################################################################

### Setup
rm(list=ls())
windows <- Sys.info()[1]=="Windows"
root <- ifelse(windows,"J:/","/home/j/")
user <- ifelse(windows, Sys.getenv("USERNAME"), Sys.getenv("USER"))
code.dir <- paste0(ifelse(windows, "H:", paste0("/homes/", user)), "/risk_factors/")

## Packages
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
library(data.table)
#library(ggplot2)
#library(RMySQL)
#library(maptools)
#library(gridExtra)
#library(ggrepel)
library(parallel)

### Functions
source(paste0(root, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
source(paste0(root, "temp/central_comp/libraries/current/r/get_draws.R"))
source(paste0(root, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
source(paste0(root, "temp/central_comp/libraries/current/r/get_outputs.R"))
source(paste0(root, "temp/central_comp/libraries/current/r/get_population.R"))
source(paste0(root, "temp/central_comp/libraries/current/r/get_ids.R"))

#pull metadata
age_ids <- get_ids("age_group")
sex_ids <- get_ids("sex")
rei_ids <- get_ids("rei")

#set location_ids
loc.table <- get_location_metadata(location_set_id = 22)
loc.names <- loc.table[, .(location_name, location_id)]
prov.list <- loc.table[parent_id == 44533, location_id]
prov.list <- c(354, 361, 6, prov.list)

#pull pops
population <- get_population(age_group_id=c(seq(10,20),30,31,32,235), sex_id=c(1, 2), 
                             location_id=prov.list, 
                             year_id=c(1990, 1995, 2000, 2005, 2006, 2010, 2016))[, -("run_id"), with=FALSE]

##Pull PAFs of COPD due to HAP (rei_id 87)-or switch to 86 for AAP, or 88 for ozone
pafs <- get_draws(gbd_id_field = "rei_id", 88, gbd_round_id = 4,
                  location_ids = prov.list, year_ids = c(1990, 1995, 2000, 2005, 2006, 2010, 2016),
                  source="risk", status = "best",  draw_type="paf")
pafs <- pafs[cause_id == 509,]

## Pull incidence of COPD
#incidence <- get_draws("cause_id", 509, location_ids = prov.list, sex_ids = c(1,2,3),measure_id = 6, source = "como", status = "best")
incidence <- fread("/home/j/temp/wgodwin/chn/collab/copd_incidence2.csv") ##saved flat file b/c takes for ever to read in every time
incidence <- incidence[year_id %in% c(1990, 1995, 2000, 2005, 2006, 2010, 2016),]
incidence <- incidence[sex_id %in% c(1,2)]
setnames(incidence, paste0("draw_", 0:999), paste0("inc_", 0:999))
setnames(incidence, "measure_id", "measure")

## Merge pafs and incidence, then multiply together at draw level
both <- merge(incidence, pafs, by = c("location_id", "year_id", "age_group_id", "sex_id"))
draws <- 0:999
draw_cols <- paste0("copd_inc_", draws)
both[, (draw_cols) := lapply(draws, function(x) { get(paste0("paf_", x)) * get(paste0("inc_", x)) }) ]

#Clean and check on mean output
both <- both[, c("location_id", "year_id", "sex_id", "age_group_id", "measure_id", draw_cols), with = F]

## Merge on populations to pop-weight up to mainland china
both <- merge(both, population, by = c("location_id", "year_id", "age_group_id", "sex_id"), all.x = T)
subnats <- setdiff(prov.list, c(354, 361, 6))
chn_sub <- both[location_id %in% subnats]

#Mainland China Agg
  #Calc total population across subnats
  chn_sub <- chn_sub[, poptotal := sum(population), by=c("year_id", "age_group_id", "sex_id", "measure_id")] ## added measure_id...
  
  #apply weights to the attributable incidence then sum up across subnats
  chn_sub[, (draw_cols) := lapply(draw_cols, function(x) {get(x) * population / poptotal})]
  chn_sub[, (draw_cols) := mclapply(.SD, sum, mc.cores=4), by=c("year_id", "age_group_id", "sex_id", "measure_id"), .SDcols=draw_cols]
  
  #keep one of the subnats and change it to mainland china value
  chn_sub <- chn_sub[location_id == 491,]
  chn_sub[, location_id := 44533]
  
  #append on national estimate with subnats
  dt <- rbind(both, chn_sub, fill = T)

#Full China Agg
  subnats <- setdiff(prov.list, c(6))
  chn_sub <- both[location_id %in% subnats]
  
  #Calc total population across subnats
  chn_sub <- chn_sub[, poptotal := sum(population), by=c("year_id", "age_group_id", "sex_id", "measure_id")] ## added measure_id...
  
  #apply weights to the attributable incidence then sum up across subnats
  chn_sub[, (draw_cols) := lapply(draw_cols, function(x) {get(x) * population / poptotal})]
  chn_sub[, (draw_cols) := mclapply(.SD, sum, mc.cores=4), by=c("year_id", "age_group_id", "sex_id", "measure_id"), .SDcols=draw_cols]
  
  #keep one of the subnats and change it to mainland china value
  chn_sub <- chn_sub[location_id == 491,]
  chn_sub[, location_id := 6]
  
  #append on national estimate with subnats
  dt <- rbind(dt, chn_sub, fill = T)
  
#Sex Agg
  #Calc total population across sexes
  dt.sex <- dt[, poptotal := sum(population), by=c("year_id", "age_group_id", "location_id", "measure_id")]
  
  #apply weights to the attributable incidence then sum up across subnats
  dt.sex[, (draw_cols) := lapply(draw_cols, function(x) {get(x) * population / poptotal})]
  dt.sex[, (draw_cols) := mclapply(.SD, sum, mc.cores=4), by=c("year_id", "age_group_id", "location_id", "measure_id"), .SDcols=draw_cols]
  
  #keep one sex and change it to both sex value
  dt.sex <- dt.sex[sex_id == 1,]
  dt.sex[, sex_id := 3]

  #append on all sex estimate with sex-specific
  dt <- rbind(dt, dt.sex, fill = T)
  dt <- dt[, c("location_id", "year_id", "sex_id", "age_group_id", "measure_id", draw_cols), with = F]

#Collapse to mean/upper/lower
#dt[, mean := rowMeans(.SD), .SDcols=draw_cols, by=list(age_group_id,sex_id, location_id, year_id)]
dt$mean <- apply(dt[,draw_cols, with=F], 1, quantile, probs = 0.5)
dt$lower <- apply(dt[,draw_cols, with=F], 1, quantile, probs = 0.025)
dt$upper <- apply(dt[,draw_cols, with=F], 1, quantile, probs = 0.975)

#append on useful metadata and add labels to measure_id
dt <- dt[, .(location_id, year_id, sex_id, age_group_id, measure_id, mean, lower, upper)]
dt <- merge(dt, age_ids, by = "age_group_id", all.x = T)
dt <- merge(dt, loc.names, by = "location_id", all.x = T)
dt <- merge(dt, sex_ids, by = "sex_id", all.x = T)
dt[measure_id == 3, measure :="yld"]
dt[measure_id == 4, measure :="yll"]

#Clean and save
dt <- dt[, .(location_name, year_id, sex, age_group_name, measure, mean, lower, upper)]
write.csv(dt, "/home/j/temp/wgodwin/chn/collab/attr_copd_incidence_ozone2.csv", row.names = F)

#Scrap
# sev.dt <- get_outputs(topic = "rei", location_id = c(354, 361, 35646, 35623, 35617), year_id = c(1990,2016), measure_id = 29, rei_id = 83, metric_id = 3, 
#                       age_group_id = c(3,4,30,31), version = "latest", sex_id = 3)
# 
# pafs <- get_draws(gbd_id_field = "rei_id", 86, gbd_round_id = 4,
#                   location_ids = c(354, 361, 35646, 35623, 35617), age_group_ids = c(4, 5, 30, 31),
#                   source="risk", status = "best",  draw_type="paf")
# pafs[, mean := rowMeans(.SD), .SDcols=draw_cols, by=list(age_group_id,sex_id, location_id, year_id, measure_id)]
# pafs <- pafs[, .(age_group_id,sex_id, location_id, year_id, measure_id, mean)]
