#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: WG
# Date: 02/16/2018
# Purpose: Mapping tools for temperature PAFs
# source("/homes/wgodwin/temperature/paf/calc/paf_map.R", echo=T)
#********************************************************************************************************************************

#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  j <- "/home/j/" 
  h <- "/homes/wgodwin/"
} else { 
  j <- "J:"
  h <- "H:"
}

#load packages
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
require(data.table)
require(magrittr)
require(mapproj)
require(ggplot2)

# important functions and prep
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
source(paste0(j, "temp/central_comp/libraries/current/r/get_model_results.R"))
source(paste0(j,"WORK/05_risk/central/code/maps/global_map.R"))
locs <- get_location_metadata(location_set_id=22)[, .(location_id, ihme_loc_id, location_name, super_region_name)]
suffix <- "mmtDif_braMexNzl_halfnobra"

#pafs directory
version <- 20
in.dir <- paste0("/share/epi/risk/temp/temperature/paf/", version)
out.dir <- paste0(j, "WORK/05_risk/risks/temperature/diagnostics/paf/")

###########################################################################################
################################GLOBAL MAP#################################################
###########################################################################################
#Diagnostic map
date <- Sys.Date()
  
##PAFs#####################################################################################
  files <- list.files(path = paste0(in.dir, "/summary"), full.names = T)
  causes <- c("cvd_ihd", "ckd", "diabetes", "cvd_stroke","resp_copd", "inj_drowning", "nutrition_pem", "lri")
  #causes <- c("resp_asthma", "tb", "uri", "sids")
  #plot by cause and PAF type
  pdf(paste0(out.dir, "global_", suffix, ".pdf"))
  for (c in causes){
    for(p in c("cold","heat", "joint")){
      #dt[, error_band := upper - lower]
      files.relev <- grep(c, files, value = T)
      rrs <- rbindlist(lapply(files.relev, fread))
      rrs[, location_id := as.numeric(location_id)]
      dt <- merge(rrs, locs, by = "location_id", all.x = T)
      if(p == "cold") dt.temp <- dt[heat == 0]
      if(p == "heat") dt.temp <- dt[heat == 1]
      if(p == "joint") dt.temp <- dt[heat == 2]
      mi <- round(min(dt.temp$mean, na.rm = T), digits = 2)
      ma <- round(max(dt.temp$mean, na.rm = T), digits = 2)
      width <- ma - mi
      if(p == "cold") interval <- round(width/8, digits = 2)
      if(p == "heat") interval <- round(width/6, digits = 3)
      if(p == "joint") interval <- round(width/8, digits = 2)
      global_map(data=dt.temp, map.var="mean", years = c(1990, 2005, 2017),
                 plot.title=paste0("Temperature (", p,") PAF for ", c),
                 #output.path=paste0(out.dir, "global_mmtDif_mexNzl_cold_", c, ".pdf"),
                 subnat=T,
                 scale="cat",
                 #limits = c(seq(0, .2, .04),.25,.3,.4),
                 limits = seq(mi,ma,interval),
                 col.rev = T)
      #rr.max <- rrs[, lapply(.SD, max), .SDcols = "rr_mean", by = c("bin")]
      #rr.mean <- rrs[, lapply(.SD, mean), .SDcols = "rr_mean", by = c("bin")]
    }
  }
  dev.off()
  
  
  #LDLs mapping function
  source(paste0(j, "DATA/SHAPE_FILES/GBD_geographies/master/GBD_2015/inset_maps/allSubs/GBD_WITH_INSETS_MAPPING_FUNCTION.R"))
  ## make map
  setnames(dt, "PAF_mean", "mapvar")
  pdf(paste0(out.dir,"global_map_cat_", date, ".pdf"))
  for (year in unique(dt$year_id)) {
    temp <- dt[year_id == year]
    gbd_map(data=temp,
            limits=seq(-0.35,0.85,0.2), # change to whatever bins make sense for your data
            #label=c(,,,,,,, ), # label bins in the legend
            col="RdYlBu", # choose palette
            col.reverse=T, #reverse palette if you want
            title=paste0("Temperature PAF for ", year), # map title
            na.color = "dark gray") # save as .tif .eps or .pdf
  }
  dev.off()

  ##Scatter comparison of PAF versions####
  version.old <- 20
  version.new <- 21
  dir0 <- paste0("/share/epi/risk/temp/temperature/paf/", version.old)
  dir1 <- paste0("/share/epi/risk/temp/temperature/paf/", version.new)
  causes <- c("cvd_ihd", "ckd","lri", "diabetes")
  files0 <- list.files(path = paste0(dir0, "/summary"), full.names = T)
  files1 <- list.files(path = paste0(dir1, "/summary"), full.names = T)
  
  ##Bind together files for each version
  dt <- data.table()
  for(c in causes){
    files.relev <- grep(c, files0, value = T)
    dt0 <- rbindlist(lapply(files.relev, fread))
    setnames(dt0, c("lower", "mean", "upper"), c("lower_old", "mean_old", "upper_old"))
    files.relev <- grep(c, files1, value = T)
    dt1 <- rbindlist(lapply(files.relev, fread))
    dt.temp <- merge(dt0, dt1, by=c("location_id", "year_id", "heat"))
    dt.temp[, location_id := as.numeric(location_id)]
    dt.temp[, acause := c]
    dt <- rbind(dt, dt.temp)
  }
  
  dt.heat <- fread("/share/epi/risk/paf/294275/summaries/summaries.csv")[age_group_id == 2 & sex_id == 1]
  dt.heat[, heat := 1]
  dt.cold <- fread("/share/epi/risk/paf/294278/summaries/summaries.csv")[age_group_id == 2 & sex_id == 1]
  dt.cold[, heat := 0]
  dt.old <- rbind(dt.cold, dt.heat)
  setnames(dt.old, c("lower", "mean", "upper"), c("lower_old", "mean_old", "upper_old"))
  
  dt <- data.table()
  for(c in causes){
    files.relev <- grep(c, files0, value = T)
    dt.temp <- rbindlist(lapply(files.relev, fread))
    dt.temp[, location_id := as.numeric(location_id)]
    dt.temp[, acause := c]
    dt <- rbind(dt, dt.temp)
  }
  cause.dt <- get_cause_metadata(cause_set_version_id = 264)[,.(acause,cause_id)]
  dt <- merge(dt, cause.dt, by = "acause")
  dt <- merge(dt, dt.old, by=c("cause_id", "location_id", "year_id", "heat"))
  ##Merge on location metadata
  dt <- merge(dt, locs, by = "location_id")
  
  #Do the plot
  pdf(paste0(out.dir, "paf_scatter_tier1s_bra.pdf"), width = 10, height = 6)
  for (c in causes) {
    for(p in c(0,1,2)){
      for (year in unique(dt$year_id)) {
        plot.dt <- dt[heat==p & year_id == year & acause == c]
        mi <- min(plot.dt$mean, na.rm = T)
        ma <- max(plot.dt$mean, na.rm = T)
        t <- ifelse(p==0, "Below TMREL", ifelse(p==1, "Above TMREL", "Joint"))
        g <- ggplot(data=plot.dt, aes(y=mean, x=mean_old, colour=super_region_name)) + #label=ihme_loc_id,
          #geom_text(size=2.5, alpha=0.7, show.legend=FALSE) + 
          geom_point(size=1, alpha=0.7) +
          geom_abline(slope = 1) +
          ylim(mi, ma) + xlim(mi, ma) +
          xlab("PAF v20(w/o BRA)") + ylab("PAF v21(w/ BRA)") +
          scale_colour_manual(values=c("Central Europe, Eastern Europe, and Central Asia" = "#9E0142",
                                       "High-income"                                      = "#E55A42",
                                       "Latin America and Caribbean"                      = "#FAB972",
                                       "North Africa and Middle East"                     = "#F2EA91", 
                                       "South Asia"                                       = "#BBE49C", 
                                       "Southeast Asia, East Asia, and Oceania"           = "#64AEA4",
                                       "Sub-Saharan Africa"                               = "#5E4FA2"),
                                        name="Super region", drop=FALSE) +
          theme(plot.title=element_text(face="bold", size=12), axis.text=element_text(size=10),
                strip.background=element_blank(), axis.line=element_line(colour="black"),
                panel.grid.major=element_blank(), panel.grid.minor=element_blank(), panel.background=element_blank(), 
                legend.background=element_blank(), legend.key=element_blank()) +
          guides(colour=guide_legend(override.aes=list(shape=15, size=5))) +
          ggtitle(paste0("PAF ", c, " (", t, ") for ", year))
        print(g)
      }
    }
  }
  dev.off()
  
##Relative risk maps#########################################################################
  ##Pull in relevant files
  files <- list.files(path = paste0(in.dir, "/rr_test"), full.names = T)
  rrs <- rbindlist(lapply(files, fread))
  rrs[, location_id := as.numeric(location_id)]
  dt <- merge(rrs, locs, by = "location_id", all.x = T)

  #Loop through mmt bins and generate plots
  bins <- unique(dt$bin)
  pdf(paste0(j, "WORK/05_risk/risks/temperature/diagnostics/rr/global_map_", date, ".pdf"))
  for (b in bins) {
    temp <- dt[bin == b,]
    global_map(data=temp, map.var="rr_mean",
               plot.title=paste0("Temperature RR 1990 for mmt ", b),
               subnat=T,
               scale="cont",
               col.rev = T)
  }
  dev.off()

###########################################################################################
################################MEXICO MAP#################################################
###########################################################################################
  #Pull mex locations
  locations <- get_location_metadata(location_set_id=22)[parent_id == "130",.(location_id, location_name)]
  locs <- locations[, location_id]
  mex <- readOGR(paste0(j, "DATA/SHAPE_FILES/GBD_geographies/selected_subnationals/MEX/ADM1/GIS/MEX_adm1.shp"))
  mex_poly <- fortify(mex, region="NAME_1") %>% data.table
  setnames(mex_poly, "id", "location_name")
  
  #Prep DF
  files <- list.files(path = paste0(in.dir, "/summary"), full.names = T)
  rrs <- rbindlist(lapply(files, fread))
  rrs[, location_id := as.numeric(location_id)]
  rrs <- rrs[location_id %in% locs]
  df <- merge(rrs, locations, by = "location_id", all.x = T)
  plot_df <- merge(df, mex_poly, by = "location_name", allow.cartesian = T)
  
  #color pallete
  heat_color <- rev(c('#d73027','#f46d43','#fee090','#ffffbf','#e0f3f8','#abd9e9','#74add1','#4575b4'))
  
  #gg
  pdf(paste0(out.dir, "mex_", date, ".pdf"))
  for (year in unique(plot_df$year_id)){
    temp_df <- plot_df[year_id==year,]
    plotty <- ggplot(temp_df) + geom_polygon(aes(x=long, y=lat, group=group, fill=PAF_mean)) +
      scale_fill_gradientn(colors = heat_color) +
      theme_classic() +
      coord_map() + 
      labs(title = paste0("Temperature PAF in ", year))
    print(plotty)
  }
  dev.off()
  
  #gg with facet wrap on year
  pdf(paste0(out.dir, "mex_2_", date, ".pdf"))
  plotty <- ggplot(plot_df) + geom_polygon(aes(x=long, y=lat, group=group, fill=PAF_mean)) +
    scale_fill_gradientn(colors = heat_color) +
    theme_classic() +
    coord_map() + 
    labs(title = paste0("Temperature PAF")) +
    facet_wrap(~year_id, nrow = 2)
  print(plotty)
  dev.off()
