library(raster)

w_piped <- brick("H:/mbg_results/water/feb-13-17/w_piped.tif")
w_imp <- brick("H:/mbg_results/water/feb-13-17/w_imp.tif")
w_unimp <- brick("H:/mbg_results/water/feb-13-17/w_unimp.tif")
w_surface <- brick("H:/mbg_results/water/feb-13-17/w_surface.tif")

w_total_list <- list()
for (i in 1:4) {
  
  w_total_list[[i]] <- w_piped[[i]] + w_unimp[[i]] + w_imp[[i]] + w_surface[[i]]
  
}

w_piped_rescale <- list()
w_imp_rescale <- list()
w_unimp_rescale <- list()
w_surface_rescale <- list()
for (i in 1:4) {
  
  w_piped_rescale[[i]] <- w_piped[[i]]/w_total_list[[i]]
  w_imp_rescale[[i]] <- w_imp[[i]]/w_total_list[[i]]
  w_unimp_rescale[[i]] <- w_unimp[[i]]/w_total_list[[i]]
  w_surface_rescale[[i]] <- w_surface[[i]]/w_total_list[[i]]
}


w_piped_rescale1 <- stack(w_piped_rescale)
w_imp_rescale1 <- stack(w_imp_rescale)
w_unimp_rescale1 <- stack(w_unimp_rescale)
w_surface_rescale1 <- stack(w_surface_rescale)


writeRaster(w_piped_rescale1, file = 'H:/mbg_results/water/feb-13-17/w_piped_rescale.tif', format = 'GTiff',overwrite = T)
writeRaster(w_imp_rescale1, file = 'H:/mbg_results/water/feb-13-17/w_imp_rescale.tif', format = 'GTiff',overwrite = T)
writeRaster(w_unimp_rescale1, file = 'H:/mbg_results/water/feb-13-17/w_unimp_rescale.tif', format = 'GTiff',overwrite = T)
writeRaster(w_surface_rescale1, file = 'H:/mbg_results/water/feb-13-17/w_surface_rescale.tif', format = 'GTiff',overwrite = T)


