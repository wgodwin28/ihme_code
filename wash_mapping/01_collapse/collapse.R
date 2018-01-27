#### Set Up Environment ####
# source("/snfs2/HOME/wgodwin/wash_mapping/01_collapse/collapse.R")
# Clear environment
rm(list = ls())

# Define indicator family; can be water, sani, or hw
indi_fam <- "sani"

# Define agg level; can be country or '' [use '' for default]
agg_level <- 'country'

# Define indicator era
sdg <- F

# define process
windows <- Sys.info()[1]=="Windows"
user <- ifelse(windows, Sys.getenv("USERNAME"), Sys.getenv("USER"))
project <- ifelse(user == "wgodwin", "gbd", "geo") 

# Set repo path
root <- ifelse(Sys.info()[1]=="Windows", "J:/", "/snfs1/")
if(project == "gbd") repo <- ifelse(Sys.info()[1]=="Windows", 'H:/wash_mapping/01_collapse/',
                    '/snfs2/HOME/wgodwin/wash_mapping/01_collapse/')
                    #'/share/code/geospatial/adesh/wash_mapping/01_collapse/')

# Load Packages
# Set package library
#if(Sys.info()[1]!="Windows") {
  #package_lib <- paste0(root,'temp/geospatial/packages') 
  #.libPaths(package_lib)
#}

# Detach all but base packages
detachAllPackages <- function() {
  basic.packages <- c("package:stats","package:graphics","package:grDevices",
                      "package:utils","package:datasets","package:methods",
                      "package:base")
  package.list <- search()[ifelse(unlist(gregexpr("package:",search()))==1,TRUE,FALSE)]
  package.list <- setdiff(package.list,basic.packages)
  if (length(package.list)>0)  for (package in package.list) 
    detach(package, character.only=TRUE)
}
detachAllPackages() 

# Load and install, if necessary, needed packages
packages <- c('data.table', 'haven', 'survey', 'reshape2', 'dplyr', 'feather')
new.packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(packages, library, character.only = T)

#for (data_type in c("pt", "poly")){
  data_type <- "pt"
  message(paste("Loading",data_type, "data"))
  # Load data
  if (!("pt_collapse" %in% ls()) & data_type == 'pt') {
    pt_collapse <- read_feather(paste0(root,'LIMITED_USE/LU_GEOSPATIAL/geo_matched/wash/points_2018_01_11.feather'))
    Encoding(pt_collapse$w_source_drink) <- "windows-1252"
    Encoding(pt_collapse$w_source_other) <- "windows-1252"
    Encoding(pt_collapse$t_type) <- "windows-1252"
  } 
    
  if (!("poly_collapse" %in% ls()) & data_type == 'poly') {
    name <- read_feather(paste0(root,'LIMITED_USE/LU_GEOSPATIAL/geo_matched/wash/poly_2017_09_28.feather'))
    Encoding(poly_collapse$w_source_drink) <- "windows-1252"
    Encoding(poly_collapse$w_source_other) <- "windows-1252"
    Encoding(poly_collapse$t_type) <- "windows-1252"
    pt_collapse <- get(name)
    rm(poly_collapse)
  }

  if (!("definitions" %in% ls())) {
    if (indi_fam == "sani") {
      definitions <- read.csv(paste0(root,'WORK/11_geospatial/wash/definitions/t_type_defined_2018_01_12.csv'),
                              encoding="windows-1252", stringsAsFactors = F)
    } else {
      definitions <- read.csv(paste0(root,'WORK/11_geospatial/wash/definitions/w_source_defined_2017_01_18.csv'),
                              encoding="windows-1252", stringsAsFactors = F) 
      definitions2 <- read.csv(paste0(root,'WORK/11_geospatial/wash/definitions/w_other_defined_2017_01_11.csv'),
                               encoding="windows-1252", stringsAsFactors = F)
      definitions2 <- rename(definitions2, sdg2 = sdg)
    }
  }

  definitions <- distinct(definitions)
  if (exists('definitions2')) {definitions2 <- distinct(definitions2)}

  rm(list = setdiff(ls(),c('definitions','pt_collapse','definitions2','indi_fam','repo','data_type','root','agg_level', 'sdg', 'project')))

  #### Load functions ####
  setwd(repo)
  source('functions/hh_cw.R')
  source('functions/address_missing.R')
  source('functions/cw_indi.R')
  source('functions/agg_wash.R')
  source('functions/define_wash.R')
  source('functions/collapse_gbd.R')

  #### Subset & Shape Data ####
  # Subset to relevant variables
  if(project == "gbd"){
    ptdat_0 <- dplyr::select(pt_collapse, nid, iso3, strata, psu, lat, long, survey_series, hhweight, urban, w_source_drink, w_source_other, t_type,
                           hh_size, year_start,hhweight,shapefile,location_code, admin_1_id, admin_1_urban_id, admin_2_id)
  } else {
    ptdat_0 <- dplyr::select(pt_collapse, nid, iso3, lat, long, survey_series, hhweight, urban, w_source_drink, w_source_other, 
                           hh_size, year_start,hhweight,shapefile,location_code)
  }
  problem_list <- filter(ptdat_0, hh_size <= 0)
  #setwd('C:/Users/adesh/Desktop')
  #write.csv(problem_list %>% group_by(nid, iso3, survey_series, year_start) %>% summarize(obs = n(), min_hhs = min(hh_size)),
  #          file = paste0(data_type,"_problems.csv"))
  setwd(repo)

  # Create a unique cluster id
  if (data_type == 'pt') {
    ptdat <- mutate(ptdat_0, cluster_id = paste(iso3, lat, long, survey_series, year_start, sep = "_"))
  } else {
    ptdat <- mutate(ptdat_0, cluster_id = paste(iso3, shapefile, location_code, survey_series, year_start, sep = "_"))  
  }

  # Create a table which assigns numbers to unique IDs and merge it back to data to have shorter
  # unique IDs
  short_id <- data.frame(cluster_id = unique(ptdat$cluster_id), 
                         id_short = seq(1:length(unique(ptdat$cluster_id))),
                         stringsAsFactors = F)
  ptdat <- left_join(ptdat, short_id, by = 'cluster_id')
  rm(short_id)

  # Remove longer cluster_ids
  ptdat <- dplyr::select(ptdat, -cluster_id)
  
  # Change weight to 1 if collapsing point data
  if (data_type == "pt" & agg_level != 'country') {ptdat$hhweight <- 1}

  # Change shapefile and location code to missing if collapsing point data
  if (data_type == "pt" | project == "gbd") {ptdat$shapefile <- NA; ptdat$location_code <- NA}

  #### Define Indicator ####
  message("Defining Indicator...")
  ptdat <- as.data.frame(ptdat) ### Check on why the ptdat is turning into a data.table-causing left_join in define_indi to break
  ptdat <- define_indi()

  #### Address Missingness ####
  # Remove clusters with more than 20% weighted missingness
  message("Addressing Missingness...")
  ptdat <- rm_miss()

  # Remove cluster_ids with missing hhweight or invalid hhs
  miss_wts <- unique(ptdat$id_short[which(is.na(ptdat$hhweight))])
  ptdat <- filter(ptdat, !(id_short %in% miss_wts))

  invalid_hhs <- unique(ptdat$id_short[which(ptdat$hh_size <= 0)])
  ptdat <- filter(ptdat, !(id_short %in% invalid_hhs))

  # Crosswalk missing household size data
  message("Crosswalking HH Sizes...")
  ptdat <- hh_cw(data = ptdat)

  # Calculated household size weighted means for all clusters
  # Assign observations with NA indicator value the weighted average for the cluster
  message("Imputing indicator...")
  ptdat <- impute_indi()

  #### Aggregate Data ####
  # Aggregate indicator to cluster level
  ptdat <- agg_indi(mydat = ptdat, var_family = indi_fam, dt_type = data_type, agg = agg_level, proj = project)
  
  # Reshape gbd data to enable crosswalk
  if(project == "gbd") {
    ptdat <- reshape(ptdat, idvar = c("year_start", "iso3", "survey_series", "nid"), timevar = "var", v.names = c("mean", "se", "deff"), direction = "wide", sep = "_")
    colnames(ptdat)<- sub("mean_", "", colnames(ptdat))
  }
  
  # Crosswalk indicator data
  message("Crosswalking Indicators...")
  ptdat <- cw_indi()

  # create sdg improved for sdg era
  if (sdg) {
    ptdat$sdg_imp <- ptdat$piped + ptdat$imp
  }

  #save poly and point collapses
  today <- gsub("-", "_", Sys.Date())
  
  if (data_type == "poly" & project != 'gbd') {
    polydat <- ptdat
    rm(ptdat)
    save(polydat, file=paste0(root,"LIMITED_USE/LU_GEOSPATIAL/collapsed/wash/polydat_", today, ".RData"))
  }else if(data_type == "pt" & project != 'gbd'){
    save(ptdat, file=paste0(root,"LIMITED_USE/LU_GEOSPATIAL/collapsed/wash/ptdat_", today, ".RData"))
  }else if (data_type == "pt" & project == 'gbd'){
    pt_coll <- copy(ptdat)
  }
#}

# save for gbd
if(project == 'gbd') {  
  #alldat <- rbind(pt_coll, ptdat)
  if(indi_fam == "sani") {indi_fam <- "sanitation"}
  if(indi_fam == "hw") {indi_fam <- "hygiene"}
  write.csv(ptdat, file = paste0(root, "WORK/05_risk/risks/wash_", indi_fam, "/data/exp/01_data_audit/tabulated_", today, "_poly_noimpute.csv"), row.names = F)
}