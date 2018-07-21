#Calculate pop-weighted SD across pixels

rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
  h = "H:/"
} else{
  j = "/home/j/"
  h = "/homes/wgodwin/"
}

#load libraries
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
pacman::p_load(data.table, parallel, magrittr, feather, mvtnorm, zoo, maptools)
arg <- commandArgs()[-(1:3)]

##Functions
wtsd <- function(x, pop){
  sqrt(sum((x-mean(x))^2 * (pop/sum(pop))))
}

#Settings
in.dir <- "/share/epi/risk/temp/temperature/exp/gridded/"
pop.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/paf/")
out.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/exploration/")
loc <- 22
year <- 1990
cores <- 6

#########################################################################################
###First calculate number of pixels per gbd location#####################################
#########################################################################################
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
loc.dt <- get_location_metadata(location_set_id=22)[most_detailed == 1,.(location_id, ihme_loc_id)]
locations <- loc.dt[, unique(location_id)]
year <- 1990
d <- data.table(location_id = vector(), pixels = vector())
for (loc in locations) {
  t <- read_feather(paste0(in.dir,"loc_", loc, "_",  year, ".feather")) %>% as.data.table
  t <- t[!is.na(tmean)]
  l <- length(t$long)/365
  e <- data.table(location_id = loc, pixels = l)
  cat(loc)
  d <- rbind(d, e)
}
d <-merge(d, loc.dt, by="location_id")
write.csv(d, paste0(out.dir, "pixels.csv"), row.names = F)

########################################################################################
##Now calulate standard deviation of temperature for each gbd location by day###########
########################################################################################
#Function to loop through locations and calulate SD over pixels, by year
country.calc <- function(loc){
  years <- c(1990, 1995, 2000, 2005, 2010, 2017)
  dt.all <- data.table(date = as.Date(as.integer()), location_id = as.numeric(), weighted_sd = as.numeric())
  for(year in years){
    dt <- read_feather(paste0(in.dir, "loc_", loc, "_", year, ".feather")) %>% as.data.table
    dt <- dt[!is.na(tmean)]
    
    #merge on pops
    pop <- read_feather(paste0(pop.dir, "gridded_pop_", year, ".feather")) %>% as.data.table
    dt <- merge(dt, pop, by = c("lat", "long"), all.x = T)
    
    #Calculate weighted sd
    dt <- dt[, .(weighted_sd = wtsd(tmean, pop)), by = c("date", "location_id")]
    dt.all <- rbind(dt.all, dt)
    print(year)
  }
  return(dt.all)
}

#run function
start <- Sys.time()
t <- mclapply(locations, country.calc, mc.cores = cores) %>% rbindlist
end <- Sys.time()
end - start

#Save for later
write.csv(t, paste0(out.dir, "weighted_sd.csv"), row.names = F)

#Summary statistics
summary(t$weighted_sd)
hist(t[weighted_sd < 10, weighted_sd])
m <- t[, .(sd_mean = mean(weighted_sd), sd_median = median(weighted_sd), sd_min = min(weighted_sd), sd_max = max(weighted_sd)), by = "location_id"]

#merge with pixel number dataset and save
p <- fread(paste0(out.dir, "pixels.csv"))
m[, location_id := as.integer(as.character(location_id))]
m <- merge(m, p, by = "location_id")
write.csv(m, paste0(out.dir, "weighted_sd_pixels.csv"), row.names = F)

####maps####
source(paste0(j,"WORK/05_risk/central/code/maps/global_map.R"))
global_map(data=m, map.var="sd_mean",
           plot.title=paste0("Temperature SD"),
           #output.path=paste0(out.dir, "global_mmtDif_mexNzl_cold_", c, ".pdf"),
           subnat=T,
           scale="cont",
           #limits = c(seq(0, .2, .04),.25,.3,.4),
           #limits = seq(mi,ma,interval),
           col.rev = T)
