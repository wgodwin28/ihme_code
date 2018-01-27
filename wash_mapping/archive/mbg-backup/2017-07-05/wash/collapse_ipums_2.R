if(!require(pacman)) {
  install.packages("pacman"); require(pacman)}
p_load(plyr, data.table, magrittr, parallel, doParallel)

j <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
cores <- 30
#qlogin -pe multi_slot 30 -P proj_geospatial -now no
#source("/snfs2/HOME/gmanny/backups/Documents/Repos/mbg/wash/collapse_ipums_2.R")

ipums <- list.files(pattern = "IPUMS", paste0(j, 'LIMITED_USE/LU_GEOSPATIAL/geo_matched/wash/IPUMS'), full.names = T)

w_source <- read.csv("/snfs1/WORK/11_geospatial/wash/definitions/w_source_defined_updated_2017_05_24.csv", stringsAsFactors = F)
w_other <- read.csv("/snfs1/WORK/11_geospatial/wash/definitions/2nd_w_other_defined_updated_2017_05_18.csv", stringsAsFactors = F)
t_type <- read.csv("/snfs1/WORK/11_geospatial/wash/definitions/t_type_defined_updated_2017_05_25.csv", stringsAsFactors = F)
w_source <- data.table(w_source)
w_other <- data.table(w_other)
t_type <- data.table(t_type)
l <- length(t_type[sdg == "latrine_cw", sdg])
v <- runif(l) + 1
t_type[sdg == "latrine_cw", t_master_sdg := v]

#recode strings to numeric values
t_type[sdg == "imp" | sdg == "latrine_imp", t_master_sdg := 2]
t_type[sdg == "unimp" | sdg == "latrine_unimp", t_master_sdg := 1]
t_type[sdg == "open", t_master_sdg := 0]

message("make cluster")
cl <- makeCluster(cores)
message("register cluster")
registerDoParallel(cl)
message("start foreach")
top <- foreach(i=1:length(ipums), .packages = c('data.table', 'magrittr', 'plyr')) %dopar% {
  ip <- fread(ipums[i])
  if ("start_year" %in% names(ip)){
    setnames(ip, "start_year", "year_start")
  }
  if ("year" %in% names(ip)){
    setnames(ip, "year", "year_start")
  }
  if (!("hhweight" %in% names(ip))){
    ip[, hhweight := pweight]
  }
  if (all(c("year_start", "t_type", "survey_name", "ihme_loc_id", "nid", "hhweight", "hh_id") %in% names(ip))){
    #write the filepath to a txt
    ip  <- ip[, unique(names(ip)), with=F]
    #message("dropping duplicate colnames")
    
    if ("lat" %in% names(ip)){
      poly <- ip[!is.na(shapefile) & !is.na(location_code) & (is.na(lat) | is.na(long)), ]
      poly_matched <- merge(poly, t_type, by.x="t_type", by.y="string", allow.cartesian=T)
      t_poly_collapsed <- poly_matched[, sani := weighted.mean(t_master_sdg, hhweight, na.rm=T), by=list(shapefile, location_code)]
      t_poly_collapsed <- poly_matched[, N := length(nid), by=list(shapefile, location_code)]
      t_poly_collapsed <- unique(t_poly_collapsed, by=c("shapefile", "location_code"))
      t_poly_collapsed[, point:=0]
      
      point <- ip[!is.na(lat) & !is.na(long), ]
      pt_matched <- merge(point, t_type, by.x="t_type", by.y="string", allow.cartesian=T)
      t_pt_collapsed <- pt_matched[, sani := weighted.mean(t_master_sdg, hhweight, na.rm=T), by=list(lat, long)]
      t_pt_collapsed <- pt_matched[, N := length(nid), by=list(lat, long)]
      t_pt_collapsed[, point:=1]
      t_pt_collapsed <- unique(t_pt_collapsed, by=c("lat", "long"))
      t_ipums_collapsed <- rbind(t_pt_collapsed, t_poly_collapsed, fill=T)
    } else{
      poly <- ip[!is.na(shapefile) & !is.na(location_code), ]
      poly_matched <- merge(poly, t_type, by.x="t_type", by.y="string", allow.cartesian=T)
      t_poly_collapsed <- poly_matched[, sani := weighted.mean(t_master_sdg, hhweight, na.rm=T), by=list(shapefile, location_code)]
      t_poly_collapsed <- poly_matched[, N := length(nid), by=list(shapefile, location_code)]
      t_poly_collapsed <- unique(t_poly_collapsed, by=c("shapefile", "location_code"))
      t_poly_collapsed[, point:=0]
      t_ipums_collapsed <- t_poly_collapsed
    }
    setnames(t_ipums_collapsed, "survey_name", "survey_series")
    keep <- c("nid", "survey_series", "iso3", "year_start", "N", "point", "lat", "long", "shapefile", "location_code", "sani")
    keep <- keep[keep %in% names(t_ipums_collapsed)]
    t_ipums_collapsed <- t_ipums_collapsed[, keep, with=F]
    nid <- unique(t_ipums_collapsed$nid)
    iso3 <- unique(t_ipums_collapsed$iso3)
    year <- unique(t_ipums_collapsed$year_start)
    outname <- paste(iso3, year, nid, sep="_")
    write.csv(t_ipums_collapsed, paste0("/snfs1/LIMITED_USE/LU_GEOSPATIAL/collapsed/wash/IPUMS/", outname, ".csv"), row.names=F, na="")
    return(t_ipums_collapsed)
  }
}
message("foreach finished")
message("closing cluster")
stopCluster(cl)

sani_ipums_collapse <- rbindlist(top, use.names = T, fill=T)
save(sani_ipums_collapse, file="/snfs1/LIMITED_USE/LU_GEOSPATIAL/collapsed/wash/ipums_plot_data_06_20_2017.Rdata")