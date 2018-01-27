rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

#toggle
make_nat <- T
make_gg <- F

# #Collect arguments
# year=as.numeric(commandArgs()[1])
# data.dir = as.character(commandArgs()[2])
# save.dir = as.character(commandArgs()[3])
# shapefile.dir = as.character(commandArgs()[4])
# 
# #check to make sure things passed properly
# print(commandArgs())
# print(paste(year, data.dir, save.dir))

#load libraries
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
for(ppp in c('parallel', 'rgdal', 'sp', 'raster','ncdf4','data.table', 'ggplot2', 'magrittr')){
  library(ppp, lib.loc = pack_lib, character.only =T)
}

## set filepath objects and source locations function
proj <- "era_c" # era_c or era_interim
data.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/mean/', proj, '/')
out.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/era_nat/', proj, '/')
shapefile.dir = paste0(j, "DATA/SHAPE_FILES/GBD_geographies/master/GBD_2016/master/shapefiles")
map.dir = paste0(j,'temp/wgodwin/temperature/exposure/diagnostics/')
source(paste0(j, "temp/central_comp/libraries/current/r/get_location_metadata.R"))
source(paste0(j, "WORK/05_risk/central/code/maps/global_map.R"))
locations <- get_location_metadata(location_set_id=22)
locations <- locations[, .(location_id, region_name, super_region_name, ihme_loc_id)]
  
  if(make_nat){
    ########Read in shapefile and extract##########
    borders <- readOGR(shapefile.dir, layer = "GBD2016_analysis_final")
    borders <- borders[borders$level == 3,] ## subset to just nationals for now

    for(year in seq(1999, 2016)){
      #########load in file##############
      brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
      brik <- rotate(brik) # b/c era raster coordinates is from 0 to 360 and needs to be -180 to 180
      
      raster.ids <- extract(brik, borders)
      
      # Convert to datatable with three columns
      temp <- NULL
      for (iii in 1:length(raster.ids)) {
        if (!is.null(raster.ids[[iii]])) {
          
          message("binding locs in border #", iii)
          
          temp <- rbind(temp, data.table(location_id=borders$loc_id[iii],
                                         location_name=borders$loc_nm_sh[iii],
                                         id=raster.ids[[iii]]))
        }
      }
      
      #melt to long format and generate more interpretable day variable
      dt <- melt(temp, id = c("location_name", "location_id"))
      dt[, day := substring(as.character(variable), 5, 11)]
      dt <- dt[,.(location_name, location_id, day, value)]
      
      #collapse to get mean by day and location_name
      dt <- dt[, lapply(.SD, mean, na.rm = T), by = c("location_name", "location_id", "day")]
      dt[, year_id := year]
      
      #save and fin
      write.csv(dt, file = paste0(out.dir, year, "_nat_collapsed.csv"), row.names = F)
      print(paste("saved national means for", year))
    }
  }

  if(make_gg){
    #Rbind all years together and plot
    files <- list.files(out.dir)
    setwd(out.dir)
    dt <- rbindlist(lapply(files, fread))
    dt[,location_id := as.integer(location_id)]
    dt <- merge(dt, locations, by = c("location_id"))
    
    ## need to generate ordered id by country, that orders the day, year
    dt[, id := seq_len(.N), by = "location_name"]
    regions <- unique(dt$region_name)
    
    ##ggplot
      #by year
      pdf(paste0(map.dir, "regions_year_1989_2016.pdf"))
      for(region in regions){
        #limits <- c(min(dt$value, na.rm = T), max(dt$value, na.rm = T))
        limits <- c(240, 316)
        dt.temp <- dt[region_name == region,]
        dt.temp[, id := seq_len(.N), by = "location_name"]
        #breaks <- seq(1, 2920, by=365)
        breaks <- seq(1, 10220, by=365)
        labels <- seq(1989, 2016)
        gg <- ggplot(dt.temp, 
                   aes(x = id, 
                       y = value, 
                       color = location_name,
                       group = location_name)) +
        geom_line() + 
        #geom_point() +
        #geom_smooth() +
        scale_x_continuous(breaks=breaks, labels=labels) +
        scale_y_continuous(limits = limits) +
        xlab("Year") +
        ylab("Temperature (K)") +
        ggtitle(paste0("Temperature in ", region)) +
        theme(aspect.ratio=3/5)
        print(gg)
      }
      dev.off()
    
      #specific year, by day
      #ggplot
      pdf(paste0(map.dir, "regions_year_2015.pdf"))
      for(region in regions){
        #limits <- c(min(dt$value, na.rm = T), max(dt$value, na.rm = T))
        limits <- c(240, 316)
        dt.temp <- dt[region_name == region,]
        dt.temp[, id := seq_len(.N), by = "location_name"]
        gg <- ggplot(dt.temp, 
                     aes(x = id, 
                         y = value, 
                         color = location_name,
                         group = location_name)) +
          geom_line() + 
          #geom_point() +
          geom_smooth() +
          scale_y_continuous(limits = limits) +
          xlab("Day") +
          ylab("Temperature (K)") +
          ggtitle(paste0("Temperature in ", region)) +
          theme(aspect.ratio=3/5)
        print(gg)
      }
      dev.off()
      
      #compare one year with another across days by location
      #ggplot
      dt.recent <- fread(paste0(j, 'temp/wgodwin/temperature/exposure/prepped_data/era_nat/era_interim/2015_nat_collapsed.csv'))
      dt.old <- fread(paste0(j, 'temp/wgodwin/temperature/exposure/prepped_data/era_nat/era_c/1900_nat_collapsed.csv'))
      dt <- rbind(dt.recent, dt.old)
      locations <- dt[!is.na(value), unique(location_name)]
      dt[, value := value -273.15]
      
      #gg
      pdf(paste0(map.dir, "location_1900_2015.pdf"))
      for(location in locations){
        limits <- c(min(dt$value, na.rm = T), max(dt$value, na.rm = T))
        dt.temp <- dt[location_name == location,]
        gg <- ggplot(dt.temp, 
                     aes(x = as.numeric(day), 
                         y = value, 
                         color = as.factor(year_id),
                         group = year_id)) +
          geom_line() + 
          geom_point() +
          #geom_smooth() +
          scale_y_continuous(limits = limits) +
          xlab("Day") +
          ylab("Temperature (Celsius)") +
          ggtitle(paste0("Temperature in ", location))
          #theme(aspect.ratio=3/5, legend.title = "Year")
        print(gg)
      }
      dev.off()
      
      #Make maps
      dt.recent <- fread(paste0(j, 'temp/wgodwin/temperature/exposure/prepped_data/era_nat/era_interim/2015_nat_collapsed.csv'))
      dt.old <- fread(paste0(j, 'temp/wgodwin/temperature/exposure/prepped_data/era_nat/era_c/1900_nat_collapsed.csv'))
      dt <- rbind(dt.recent, dt.old)
      dt <- dt[, lapply(.SD, sd, na.rm = T), by = c("location_id", "location_name", "year_id"), .SDcols = "value"]
      dt[, location_id := as.numeric(location_id)]
      dt <- merge(dt, locations, by = "location_id")
      global_map(data=dt,
                 map.var="value",
                 plot.title="Temperature Standard Deviation for 1900 and 2015",
                 output.path=paste0(map.dir, "map_1900_2015.pdf"),
                 years=c(1900,2015),
                 sexes=3,
                 subnat=F,
                 scale="cont",
                 col="RdYlBu",
                 col.rev=TRUE)
      #mexico <- readOGR("/home/j/temp/Jeff/temperature/shapefiles/mex/GIS Mexican Municipalities/Mexican Municipalities.shp")
      #mex.dt <- fortify(mexico, region="NOM_MUN") %>% data.table
      #world.dt <- fortify(borders, region = "loc_name") %>% data.table
      
      ##gg
      geom_polygon(aes(x=long, y=lat, group=group, fill=diff)) +
        scale_fill_gradientn(colours=colors, limits=ylim)  + 
        geom_path(data=provinces, aes(x=long, y=lat, group=group)) + 
        scale_x_continuous("", breaks=NULL) + 
        scale_y_continuous("", breaks=NULL) + 
        coord_fixed(ratio=1) + 
        guides(fill=guide_colourbar(title="Deaths/100,000 Live Births", barheight=10)) + 
        theme_bw(base_size=10) +  
        labs(title=paste(title, sep=""))
  }

#Manipulations of data fields
borders@data<-copy(data.table(borders@data))
borders@data[, name_caps:=toupper(NAME)]
map_data<-copy(borders@data)
us<-copy(borders[borders@data$loc_id==102,])
proj4string(us)
