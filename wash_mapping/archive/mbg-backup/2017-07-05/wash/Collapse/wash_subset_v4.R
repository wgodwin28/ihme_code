#### Set Up Environment ####
# Clear environment
rm(list = ls())

# Load Packages
library(pacman)
packages <- c('tidyverse','tmap','sp')
pacman::p_load(char = packages)
rm(packages)

# Define indicator family
indi_fam <- "water"

# Load data
if (!("pt_collapse" %in% ls())) {
name <- load('J:/LIMITED_USE/LU_GEOSPATIAL/geo_matched/wash/points_collapsed_2017_06_15.Rdata')
pt_collapse <- get(name)
}

if (!("definitions" %in% ls())) {
  if (indi_fam == "sani") {
  definitions <- read_csv("J:/WORK/11_geospatial/wash/definitions/t_type_defined_updated_2017_05_25.csv",
                         progress = T, col_types = 'cc_')
  
  } else {
  definitions <- read_csv("J:/WORK/11_geospatial/wash/definitions/w_source_defined_updated_2017_05_24.csv",
                        progress = T, col_types = 'cc__') 
  definitions2 <- read_csv("J:/WORK/11_geospatial/wash/definitions/2nd_w_other_defined_updated_2017_05_18.csv",
                          progress = T, col_types = 'cc_')
  definitions2 <- rename(definitions2, sdg2 = sdg)
  }
}

rm(list = setdiff(ls(),c('definitions','pt_collapse','definitions2','indi_fam')))

#### Load functions ####
source('C:/Users/adesh/Documents/WASH/wash_code/hh_cw.R')
source('C:/Users/adesh/Documents/WASH/wash_code/address_missing.R')
source('C:/Users/adesh/Documents/WASH/wash_code/cw_indi.R')
source('C:/Users/adesh/Documents/WASH/wash_code/agg_wash.R')
source('C:/Users/adesh/Documents/WASH/wash_code/define_wash.R')

#### Subset & Shape Data ####
# Subset to relevant variables
ptdat_0 <- dplyr::select(pt_collapse, nid, iso3, lat, long, survey_series, hhweight, urban, w_source_drink, w_source_other,
                hh_size, year_start)

# Create a unique cluster id
ptdat <- mutate(ptdat_0, cluster_id = paste(iso3, lat, long, survey_series, year_start, sep = "_"))

# Create a table which assigns numbers to unique IDs and merge it back to data to have shorter
# unique IDs
short_id <- data.frame(cluster_id = unique(ptdat$cluster_id), 
                       id_short = seq(1:length(unique(ptdat$cluster_id))),
                       stringsAsFactors = F)
ptdat <- left_join(ptdat, short_id, by = 'cluster_id')
rm(short_id)

# Remove longer cluster_ids
ptdat <- dplyr::select(ptdat, -cluster_id)

#### Define Indicator ####
ptdat <- define_indi()

#### Address Missingness ####

# Remove clusters with more than 20% weighted missingness
ptdat <- rm_miss()

# Crosswalk missing household size data
ptdat <- hh_cw(data = ptdat)

# Calculated household size weighted means for all clusters
# Assign observations with NA indicator value the weighted average for the cluster
ptdat <- impute_indi()

#### Aggregate Data ####
# Aggregate indicator to cluster level
ptdat <- agg_indi()

# Crosswalk indicator data
ptdat <- cw_indi()

### CHECK ALL COLUMNS FOR VALID VALUES BEFORE EXPORTING ###
message('CHECK ALL COLUMNS FOR VALID VALUES BEFORE EXPORTING')

#### Plot Data ####
plotdat <- ptdat
plotdat <- plotdat[,c(1:9,11,13,12,10)]
test <- apply(plotdat[,10:13], 1, which.max)
plotdat <- cbind(plotdat, test); rm(test)
plotdat$test[which(plotdat$test == 1)] <- 'surface'
plotdat$test[which(plotdat$test == 2)] <- 'unimp'
plotdat$test[which(plotdat$test == 3)] <- 'imp'
plotdat$test[which(plotdat$test == 4)] <- 'piped'

color_pal <- brewer.pal(4, 'Set2')
plotdat <- SpatialPointsDataFrame(coords = data.frame(as.numeric(plotdat$long), as.numeric(plotdat$lat)),
                      data = data.frame(water = as.character(plotdat$test)))
afro <- shapefile('Africa_SHP/Africa.shp')
tm_shape(afro) + tm_borders() +
tm_shape(plotdat) + tm_dots(col = "water", palette = color_pal)
