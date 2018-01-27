library(tmap)
library(raster)
library(ggplot2)
library(RColorBrewer)

date <- "feb-13-17"
group <- "water"
years <- c('2000','2005','2010','2015')
indi <- c('w_piped','w_imp','w_unim','w_surface')
my_pal <- brewer.pal(n = 11, name = "RdYlBu")
africa <- shapefile("C:/Users/adesh/Documents/junk/africa.shp")

w_list <- list()
for (i in 1:length(indi)) {
  w_list[[i]] <- brick(paste0("H:/mbg_results/", group, "/",date,"/",indi[i],".tif"))
}

for(i in 1:4) {
  ras_brick <- w_list[[i]]
  for (j in 1:4) {
    message(paste(indi[i], years[j]))
    png(filename = paste0("H:/mbg_results/", group, "/",date,"/",indi[i],"_",years[j],".png"), width = 1000, height = 1280)
    raster1 <- ras_brick[[j]]
    plot(africa)
    plot(raster1, col = my_pal, main = paste(indi[i], years[j], sep = "_"), add = T)
    plot(africa, add = T)
    dev.off()
    
    }
}


