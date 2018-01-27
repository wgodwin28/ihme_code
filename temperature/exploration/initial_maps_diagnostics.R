rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
  #pack_lib = 'J:/temp/wgodwin/r_viz/packages'
  pack_lib = 'C:/Users/wgodwin/Documents/R/win-library/3.4'
} else{
  j = '/home/j/'
  #pack_lib = '/snfs2/HOME/wgodwin/R'
}

#test toggle
test <- T
proj <- "era_c"
map.dir = paste0(j,'temp/wgodwin/temperature/exposure/diagnostics/')
data.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/mean/', proj, "/")

#install pacman library
if("pacman" %in% rownames(installed.packages())==FALSE){
  library(pacman,lib.loc="/homes/wgodwin/R")
}

# load packages, install if missing  
#pacman::p_load(data.table, fst, ggplot2, parallel, magrittr, maptools, raster, rgdal, rgeos, sp, splines, stringr, RMySQL, snow, ncdf4)
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
for(ppp in c('parallel', 'rgdal', 'sp', 'raster','ncdf4','data.table', 'ggplot2', 'magrittr')){
  library(ppp, lib.loc = pack_lib, character.only =T)
}

#Functions
coeff_var <- function(data){
  coeff <- cellStats(data, 'sd')/cellStats(data, 'mean') * 100
  return(coeff)
}
#test_coef <- coeff_var(data = data)

#test
if(test){
brik <- brick(paste0(data.dir, "2016_mean_meanmethod.nc"))
data <- raster(paste0(data.dir, "2016_mean_meanmethod.nc")) #just the first layer (Day)
}


#loop through years and map standard deviations of temp at the pixel
pdf(paste0(map.dir, "map_sd_years3.pdf"))
for(year in seq(1989, 2016)){
  temp.brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"), value = T)
  temp.sd <- calc(temp.brik, fun = sd)
  plot(temp.sd, main = paste0("Standard Deviation of Temperature (K) in ", year))
  print(paste0("Finished plotting ", year))
}
dev.off()

#loop through months, calculate means, and make histograms/density plots
dt.final <- data.table()
for(year in seq(1989, 1997)){
  brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"), value = T)
  brik.temp <- brik[[1:30]]
  r.temp <- overlay(brik.temp, fun = mean)
  dt.temp <- as.data.table(rasterToPoints(r.temp))
  dt.temp <- dt.temp[, year_id := year]
  dt.final <- rbind(dt.final, dt.temp)
  print("finished binding on ", year)
}

###############################################
###compute sd and plot for monthly and seasonal
###############################################
monthly <- F
dt.final <- data.table()
for(year in c(1990, 2005, 2016)){
  brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"), value = T)
  ifelse(monthly, int <- seq(1,305,30), int <- seq(1,305, 80)) # change for seasonal/monthly sd
  ifelse(monthly, indices <- seq(1,10), indices <- seq(1,3))
  for(index in indices){
    start_time <- Sys.time()
      brik.temp <- brik[[int[index]:int[index+1]]]
      r.temp <- overlay(brik.temp, fun = sd)
      dt.temp <- as.data.table(rasterToPoints(r.temp))
      dt.temp <- dt.temp[, year_id := year]
      dt.temp <- dt.temp[, time := index]
      dt.final <- rbind(dt.final, dt.temp)
    print(paste("finished binding on", year, index))
    end_time <- Sys.time()
    print(end_time - start_time)
  }
}

#Now density plots on the massive data table
intervals <- unique(dt.final$time)
inside <- "gold1"
line <- "goldenrod2"
pdf(paste0(map.dir, "density_sd_seasonal.pdf"))
for(i in intervals){
  dt.temp <- dt.final[time == i,]
  gg <-ggplot(dt.temp, aes(x = layer)) +
    geom_density(fill = inside, color = line) +
    ggtitle(paste0("Temperature Standard deviation distributions ", -i)) +
    labs(x = "Temperature Standard Deviation-80 days") +
    facet_wrap(~year_id)
  print(gg)
}
dev.off()


#########################################################################
###Compute monthly averages and overlay distributions for different years
#########################################################################
monthly <- F
dt.final <- data.table()
for(year in c(1990, 2005, 2016)){
  brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"), value = T)
  ifelse(monthly, int <- seq(1,305,30), int <- seq(1,305, 76)) # change for seasonal/monthly sd
  ifelse(monthly, indices <- seq(1,10), indices <- seq(1,4))
  for(index in indices){
    start_time <- Sys.time()
      brik.temp <- brik[[int[index]:int[index+1]]]
      r.temp <- overlay(brik.temp, fun = mean)
      dt.temp <- as.data.table(rasterToPoints(r.temp))
      dt.temp <- dt.temp[, year_id := year]
      dt.temp <- dt.temp[, time := index]
      dt.final <- rbind(dt.final, dt.temp)
    print(paste("finished binding on", year, index))
    end_time <- Sys.time()
    print(end_time - start_time)
  }
}
##run gg on the distributions
intervals <- unique(dt.final$time)
inside <- "gold1"
line <- "goldenrod2"
pdf(paste0(map.dir, "density_mean_seasonal.pdf"))
for(i in intervals){
  dt.temp <- dt.final[time == i,]
  gg <- ggplot(dt.temp, aes(x = layer, fill = as.factor(year_id))) + 
    geom_density(position="identity", alpha=0.4) +
    ggtitle(paste0("Temperature Mean Seasonal distributions ", -i)) +
    labs(x = "Temperature Mean") +
    scale_fill_brewer(palette="Accent") +
    theme_classic() +
    labs(fill = "Year")
    print(gg)
}
dev.off()
  
###################ggplot################
dt <- as.data.table(rasterToPoints(data))
setnames(dt, c("x", "y", "variable"), c("Longitude", "Latitude", "Temperature"))
ggplot(data=dt, aes(y=Latitude, x=Longitude)) +
  geom_raster(aes(fill=Temperature)) +
  theme_bw() +
  coord_equal() +
  scale_fill_gradient('Temperature', limits=c(220,380)) +
  theme(axis.title.x = element_text(size=16),
  axis.title.y = element_text(size=16, angle=90),
  axis.text.x = element_text(size=14),
  axis.text.y = element_text(size=14),
  panel.grid.major = element_blank())

####################ERA_C prep and maps###################
    brik <- NULL
    for(year in seq(1901,1909)){
    brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
    r2 <- overlay(brik, fun = mean)
    assign(paste0("ras", year), r2)
    print(year)
    }
    
    era <-  brick(paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/mean/era_interim/2015_mean_meanmethod.nc'))
    era2 <- overlay(era, fun = mean)
    dt1900 <- rotate(dt1900)
    era2 <- rotate(era2)
    par(mfrow = c(2,1))
    plot(dt1900, main = "1900", zlim=c(215, 308))
    legend("bottomright")
    plot(era2, main = "2015", zlim=c(215, 308))
    
    ###ggplot###
    era <- as(era2, "SpatialPixelsDataFrame") %>% as.data.table
    era[, year_id := 2015]
    
    old <- as(dt1900, "SpatialPixelsDataFrame") %>% as.data.table
    old[, year_id := 1900]
    
    both <- rbind(era, old)
    both[, layer := layer - 273.15]
    globe <- readOGR(paste0(j, "WORK/11_geospatial/06_original shapefiles/GAUL_admin/admin0/g2015_2014_0/g2015_2014_0.shp"))
    
    
    ##############By day scatter prep##############
    #historical data
    compile <- NULL
    for(year in seq(1900,1909)){
      brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
      r2 <- cellStats(brik, mean)
      compile <- cbind(compile, r2)
      print(year)
    }
    old.means <- rowMeans(compile)
    old.means[, years := "1900-1910"]
    old.means[, day := 1:nrow(old.means)]
    
    #Present day temps
    compile <- NULL
    data.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/mean/era_interim/')
    for(year in seq(2005,2015)){
      brik <- brick(paste0(data.dir, year, "_mean_meanmethod.nc"))
      r2 <- cellStats(brik, mean)
      compile <- cbind(compile, r2)
      print(year)
    }
    new.means <- rowMeans(compile) %>% as.data.table
    new.means[, years := "2005-2015"]
    new.means[, day := 1:nrow(new.means)]
    
    #Compile together and convert from kelvin
    both <- rbind(old.means, new.means)
    both[, mean := mean - 250.15]
    
    ##gg
    gg <- ggplot(both, 
                 aes(x = day, 
                     y = mean, 
                     color = years,
                     group = years)) +
      geom_line() +
      xlab("Day of Year") +
      ylab("Temperature (C)")
    print(gg)
    
    
##gg##
ggplot() +  
  geom_tile(data=both, aes(x=x, y=y, fill=layer), alpha=0.8) + 
  geom_polygon(data=globe, aes(x=long, y=lat, group=group), 
               fill=NA, color="grey50", size=0.25) +
  scale_fill_manual(values = c("blue", "green", "red")) +
  coord_equal() +
  #theme_map() + 
  facet_wrap(~year_id, nrow = 2)
#good functions to know
m <- cellStats(data, 'mean') # calculates mean temp across cells for each layer (day) of brick so produces vector of temps
r2 <- overlay(brik, fun = mean) #Outputs raster layer with results of function done across layers for each pixel