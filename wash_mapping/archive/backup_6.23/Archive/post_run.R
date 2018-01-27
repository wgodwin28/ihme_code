# Load regional rasters and save as master results raster
# Aniruddha Deshpande

# YOU SHOULD HAVE NOTHING BUT THE MODEL REGION RASTERS IN THE
# FOLDER TO ENSURE THIS CODE DOESN'T PRODUCE ERRONEOUS RESULTS

# Load library and set global parameters
library(raster)
run_date <- "mar-27-17"
setwd(paste0('H:/mbg_results/water/',run_date))
indicators <- c("w_piped","w_imp","w_surface","w_unimp")

## Import Rasters and Name them ##
for (i in 1:4) {
  rasters <- list.files(pattern = indicators[i])
  for (j in 1:length(rasters)) {
    assign(paste0(indicators[i],j), brick(rasters[j]))
  }
}

# Merge regions into single raster brick
for (i in 1:4) {
  temp_list <- list()
  for (j in 1:4) {
  temp_list[[j]] <- get(ls(pattern = indicators[i])[j])
  }
  m <- do.call(raster::merge, temp_list)
  assign(paste0(indicators[i],"_mean_raster"),m)
}

# Output mean rasters
for (i in 1:4) {
  writeRaster(get(paste0(indicators[i],"_mean_raster")),
              filename = paste0(indicators[i],"_mean_raster"),
              format = 'GTiff', overwrite = T)
}

# Create PNGs of mean rasters for presentations
years <- c(2000:2015)
for (i in 1:length(plot_names)) {
  plot_data <- get(ls(pattern = paste0(indicators[i],"_mean_raster")))
  for (j in 1:16) {
    png(filename = paste0(indicators[i],"_",years[j],"_mean_raster.jpg"), 
        width = 1080, height = 720)
    plot(plot_data[[j]], main = paste(indicators[i],years[j]))
    dev.off()
  }
}

total_raster <- w_piped_mean_raster + w_imp_mean_raster + w_unimp_mean_raster + w_surface_mean_raster
w_pipe_rescale <- w_piped_mean_raster/total_raster
w_imp_rescale <- w_imp_mean_raster/total_raster
w_unimp_rescale <- w_unimp_mean_raster/total_raster
w_surface_rescale <- w_surface_mean_raster/total_raster

years <- c(2000:2015)
rescale_list <- list(w_pipe_rescale, w_imp_rescale, w_surface_rescale, w_unimp_rescale)
for (i in 1:4) {
  plot_data <- rescale_list[[i]]
  for (j in 1:16) {
    png(filename = paste0(indicators[i],"_",years[j],"_rescale_raster.jpg"), 
        width = 1080, height = 720)
    plot(plot_data[[j]], main = paste(indicators[i],years[j]))
    dev.off()
  }
}

for (i in 1:16) { print(plot(plot_data[[i]]))
  
}

summary(w_pipe_rescale[[1]]/w_piped_mean_raster[[1]])
