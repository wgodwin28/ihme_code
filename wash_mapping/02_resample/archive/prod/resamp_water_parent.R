
proj <- "-P proj_geospatial"
user <- "adesh"

setwd('/homes/adesh/wash_code')

hw_indic <- c("water")

for (indic in hw_indic) {
  load(paste0('/home/j//WORK/11_geospatial/wash/resampling/water/',indic, '/poly_df/water_poly_f.RData'))
  
  for (shp in unique(water_poly_f$shapefile)) { 
    jname <- paste(indic, shp, sep = "_")
    mycores <- 1
    sys.sub <- paste0("qsub ",proj,paste0(" -e /share/temp/sgeoutput/",user,"/errors -o /share/temp/sgeoutput/",user,"/output "),
                      "-cwd -N ", jname, " ", "-pe multi_slot ", mycores, " ")
    script <- "resamp_water_child_v2.R"
    r_shell <- "r_shell.sh"
    args <- paste(shp, indic)
    system(paste(sys.sub, r_shell, script, args)) 
  }
}