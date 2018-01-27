############################################################################################################
## Name: Caleb Irvine
## Purpose: Use 2016 industry outputs to backfill prop_in_aggriculture covariate and prep for upload
## Date: 11/21/17
###########################################################################################################

## clear memory
rm(list=ls())

## runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  j <- "/home/j/" 
  h <- "/homes/wgodwin/"
} else { 
  j <- "J:/"
  h <- "H:/"
}

pacman::p_load(data.table,magrittr,parallel)

#function sourcing
source(paste0(j, "temp/central_comp/libraries/current/r/get_outputs.R"))
source(file.path(j,"temp/central_comp/libraries/current/r/get_location_metadata.R"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_ids.R"))
cov_ids <- get_ids("covariate")

## in/out
in_dir <- file.path("/share/epi/risk/temp/air_hap/run5/locations/air_hap")
out_dir <- file.path(j,"temp/wgodwin/save_results/covariates")

## read in all location files
sev.dt <- get_outputs(topic = "rei", location_id = "all", year_id = seq(1990,2016), measure_id = 29, rei_id = c(84), metric_id = 3, 
                     age_group_id = 22, gbd_round_id = 4, sex_id = 3)

#files <- list.files(in_dir)
#dt <- rbindlist(lapply(file.path(in_dir,files), fread))

#Draw columns
draws <- 0:999
draw_cols <- paste0("draw_", draws)

#loop through files, read in, calculate mean/upper/lower, then bind all locations together
stack<-list()
for(i in 1:length(files)){
  df <- fread(file.path(in_dir, files[i]))
  df <- df[age_group_id == 2]
  df <- df[sex_id == 1]
  df$mean_value <- apply(df[,draw_cols, with=F], 1, quantile, probs = 0.5)
  df$lower_value <- apply(df[,draw_cols, with=F], 1, quantile, probs = 0.025)
  df$upper_value <- apply(df[,draw_cols, with=F], 1, quantile, probs = 0.975)
  df <- df[, .(location_id, age_group_id, year_id, sex_id, mean_value, lower_value, upper_value)]
  stack[[i]]<-df
  
  print(paste(files[i], "added to stack:", i, "of", length(files)))
}
df <-rbindlist(stack, use.names=T)

########################Read in water/sanitation draws###########################
imp <- fread("/share/epi/risk/temp/wash_water/run4/st_gpr_viz/gbd_2016_best_draws/wash_sanitation_imp_draws.csv")
piped <- fread("/share/epi/risk/temp/wash_water/run4/st_gpr_viz/gbd_2016_best_draws/wash_sanitation_piped_draws.csv")
df <- merge(imp, piped, by= c("location_id", "year_id", "age_group_id", "sex_id"))

#Sum together
df[, (draw_cols) := lapply(draws, function(x) { get(paste0("draw_", x, ".x")) + get(paste0("draw_", x, ".y")) }) ]
df$mean_value <- apply(df[,draw_cols, with=F], 1, quantile, probs = 0.5)
df <- df[, .(location_id, age_group_id, year_id, sex_id, mean_value)]
df[mean_value >= 1, mean_value := .999]
df[, lower_value := mean_value]
df[, upper_value := mean_value]
##################################################################################
# 
# ## subset to relevant columns and rename them
# df <- df[me_name == "occ_ind_major_A_agg"]
# df <- df[,list(location_id,year_id,age_group_id,sex_id,measure_id,prop_mean,prop_lower,prop_upper)]
# df[,covariate_name_short := "prop_pop_agg"]
# df[,covariate_id := 1087]
# setnames(df,c("prop_mean","prop_lower","prop_upper"),c("mean_value","lower_value","upper_value"))
## MISSING LOCATION_ID 4749 (ENGLAND), don't know why
## ^children not too different from national GBR estimate, just substitute with that

## read in all GBD 2017 locations
locations <- get_location_metadata(gbd_round_id = 5, location_set_id = 22)
locs <- locations[level >= 3]

## merge on ihme_loc_id, identify missing locations and their parent level 3 locations from gbd 2016
df <- merge(df, locs[, .(location_id,ihme_loc_id)],by="location_id",all.y=T)
missing_locs <- df[is.na(mean_value), .(location_id, ihme_loc_id)]
missing_locs[,ihme_loc_id := substr(ihme_loc_id,1,3)]
df <- df[!is.na(mean_value)]

## copy the national estimates for all the new subnationals, then merge on correct ihme_loc_ids
missing_locs <- merge(missing_locs,df[,-c("location_id"),with=F],by="ihme_loc_id",all.x=T)
missing_locs[, ihme_loc_id := NULL]
missing_locs <- merge(locs[, .(ihme_loc_id,location_id)],missing_locs,by="location_id",all.y=T)

## add missing locations to original dataset
df <- rbind(df, missing_locs)

## add on 2017 estimates (a copy of 2016's)
new_year <- copy(df[year_id == 2016])
new_year[,year_id := 2017]
df <- rbind(df,new_year)

#Prep metadata and clean
df[, sex_id := 3]
df[, age_group_id := 22]
df[, covariate_id := 863] #CHANGE EACH TIME

## write output file in format for upload
write.csv(df[, -c("ihme_loc_id"), with=F],file.path(out_dir,"water_sev_interm2.csv"), row.names=F) #CHANGE EACH TIME
