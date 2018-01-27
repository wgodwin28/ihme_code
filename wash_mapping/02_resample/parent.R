nodes <- 'geos'
proj <- ifelse(nodes == 'geos',
        '-P proj_geo_nodes -l gn=TRUE',                      		
        '-P proj_geospatial')
user <- "adesh"

setwd('/share/code/geospatial/adesh/wash_mapping/02_resample/')
indicators <- c("water")
run_date <- Sys.Date()
load('/home/j/LIMITED_USE/LU_GEOSPATIAL/collapsed/wash/polydat_2017_09_06_clean.RData')


for (indic in indicators) {
  for (shp in unique(polydat$shapefile)) { 
    jname <- paste(indic, shp, sep = "_")
    mycores <- 4
    sys.sub <- paste0("qsub ",proj,paste0(" -e /share/temp/sgeoutput/",user,"/errors -o /share/temp/sgeoutput/",user,"/output "),
                      "-cwd -N ", jname, " ", "-pe multi_slot ", mycores, " ")
    script <- "child.R"
    r_shell <- ifelse(nodes == 'geos',
                      'r_shell_geos.sh',                      		
                      'r_shell.sh')
    
    args <- paste(shp, indic, run_date)
    system(paste(sys.sub, r_shell, script, args)) 
  }
}