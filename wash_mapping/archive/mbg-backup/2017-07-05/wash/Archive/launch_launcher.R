setwd('/share/code/geospatial/adesh/mbg/wash')

proj <- "-P proj_geospatial"
user <- "adesh"
indic_list <- c("w_piped")

for (indc in 1:length(indic_list)) { 
  jname <- paste0(indic_list[indc], "_parent")
  mycores <- 10
  sys.sub <- paste0("qsub ",proj,paste0(" -e /homes/adesh/cluster_errors"," -o /homes/adesh/cluster_output/ "),
                    "-cwd -N ", jname, " ", "-pe multi_slot ", mycores, " ")
  script <- "launch.R"
  r_shell <- "r_shell.sh"
  args <- paste(indic_list[indc])
  system(paste(sys.sub, r_shell, script, args)) 
}