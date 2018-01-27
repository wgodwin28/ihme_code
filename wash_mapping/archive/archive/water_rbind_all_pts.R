library(dplyr)

indic_list <- c("piped", "improved", "unimproved", "surface")
indic2_list <- c("piped", "improved", "unimproved", "surface")

for (i in 1:4) {
  
  setwd(paste0("J:/WORK/11_geospatial/wash/resampling/water/", indic_list[i], "/poly_df"))
  fake_pts <- lapply(list.files(), read.csv)
  fake_pts_df <- do.call(rbind, fake_pts)
  fake_pts_df <- dplyr::select(fake_pts_df, -X)
  load(paste0("J:/WORK/11_geospatial/wash/resampling/water/", indic_list[i], "/master_pt.RData"))
  input_data <- rbind(data_pt, fake_pts_df)
  write.csv(input_data, paste0("J:/WORK/11_geospatial/wash/resampling/water/", indic_list[i], "/", indic2_list[i], ".csv"))
  
}