#### Normal Run Launcher ####
setwd('/share/code/geospatial/adesh/mbg/wash')
proj <- "-P proj_geospatial"
user <- "adesh"
indic_list <- c('w_imp',"w_piped",'w_unimp','w_surface')
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

#### Experimental Run Launcher ####
setwd('/share/code/geospatial/adesh/mbg/wash')
proj <- "-P proj_geospatial"
user <- "adesh"
indic_list <- c("w_piped_x")
for (indc in 1:length(indic_list)) { 
  jname <- paste0(indic_list[indc], "_parent")
  mycores <- 10
  sys.sub <- paste0("qsub ",proj,paste0(" -e /homes/adesh/cluster_errors"," -o /homes/adesh/cluster_output/ "),
                    "-cwd -N ", jname, " ", "-pe multi_slot ", mycores, " ")
  script <- "launch_x.R"
  r_shell <- "r_shell.sh"
  args <- paste(indic_list[indc])
  system(paste(sys.sub, r_shell, script, args)) 
}

#### Post Run Launcher ####
setwd('/share/code/geospatial/adesh/mbg/wash')
proj <- "-P proj_geospatial"
user <- "adesh"
indic_list <- c("w_piped")
run_date <- "2017_04_28_09_49_50"
for (indc in 1:length(indic_list)) { 
  jname <- paste0(indic_list[indc], "_parent")
  mycores <- 10
  sys.sub <- paste0("qsub ",proj,paste0(" -e /homes/adesh/cluster_errors"," -o /homes/adesh/cluster_output/ "),
                    "-cwd -N ", jname, " ", "-pe multi_slot ", mycores, " ")
  script <- "post_run.R"
  r_shell <- "r_shell.sh"
  args <- paste(run_date)
  system(paste(sys.sub, r_shell, script, args)) 
}

#### Post Run Launcher (Experimental) ####
setwd('/share/code/geospatial/adesh/mbg/wash')
proj <- "-P proj_geospatial"
user <- "adesh"
indic_list <- c("w_piped")
run_date <- "2017_04_28_17_38_26"
for (indc in 1:length(indic_list)) { 
  jname <- paste0(indic_list[indc], "_parent")
  mycores <- 10
  sys.sub <- paste0("qsub ",proj,paste0(" -e /homes/adesh/cluster_errors"," -o /homes/adesh/cluster_output/ "),
                    "-cwd -N ", jname, " ", "-pe multi_slot ", mycores, " ")
  script <- "post_run_x.R"
  r_shell <- "r_shell.sh"
  args <- paste(run_date)
  system(paste(sys.sub, r_shell, script, args)) 
}
