setwd('/home/j//WORK/11_geospatial/05_survey shapefile library/Shapefile directory')
svy_shp <- list.files(pattern = "*.shp")
svy_shp <- sub(".shp.xml", ".xml", svy_shp)
svy_shp <- svy_shp[grep(".shp",svy_shp)]

proj <- "-P proj_geospatial"
user <- "adesh"

setwd('/homes/adesh/wash_prep')


for (shp in 1:length(svy_shp)) { 
  jname <- paste0("shp_",shp, "_", round(shp/length(svy_shp)*100, digits = 2))
  mycores <- 2
  sys.sub <- paste0("qsub ",proj,paste0(" -e /share/temp/sgeoutput/",user,"/errors -o /share/temp/sgeoutput/",user,"/output "),
                    "-cwd -N ", jname, " ", "-pe multi_slot ", mycores, " ")
  script <- "creating_ur_shp_parallel.R"
  r_shell <- "r_shell.sh"
  args <- paste(shp)
  system(paste(sys.sub, r_shell, script, args)) 
}

