setwd('/share/code/geospatial/adesh/mbg/wash')

proj <- "-P proj_geospatial"
user <- "adesh"
indic_list <- c("w_piped", "w_unimp","w_imp", "w_surface")

for (indc in 1:length(indic_list)) { 
  jname <- paste0(indic_list[indc], "_parent")
  mycores <- 1
  script <- "launch_stack_nocv.R"
  args <- paste(indic_list[indc])
  if (indc == length(indic_list)) {
  system(paste("Rscript", script, args)) 
  } else {system(paste("nohup Rscript", script, args, "&"))}
}

