#launcher script to create monthly summaries of temperature from the reforcast data
rm(list=ls())
# source('/ihme/code/geospatial/temperature/era_interim/launch_era_make_daily_by_year.R', echo =T)

#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}
proj <- "era_c" #era_interim or era_c
data.dir = paste0(j,'temp/wgodwin/temperature/exposure/raw_data/downloaded/', proj, '/')
out.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/mean/', proj, '/')

#set variables for parallelization
code.dir = paste0('/snfs2/HOME/wgodwin/temperature/')
mycores = 30
minmax = F

#make folder structure
dir.create(save.dir, recursive = T)

args = paste(mycores, as.character(minmax), data.dir, out.dir, code.dir, proj)
rscript = paste0(code.dir, 'era_interim/era_make_daily_by_year.R')
rshell = paste0(code.dir, 'r_shell_fancy.sh')
errors = '-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors'
jname = 'calc_daily_era_mean'
sys.sub <- paste0("qsub -P proj_custom_models ", errors, " -N ", jname, " ", "-pe multi_slot ", mycores, " ", "-t 1:10") #array job, era that I've downloaded exists for 1980-1991
command =paste(sys.sub, rshell, rscript, args)

#launch jobs
system(command)


# 
#   
#   args = paste(location_id, mycores)
#   rscript <-  paste0(code.dir, "extract_map_covs_africa2.R")
#   rshell <- paste0('/ihme/code/general/dccasey/malaria/rshell_new.sh')
#   jname <- paste0(name_prefix,location_id,'_inc')
#   sys.sub <- paste0("qsub -P proj_custom_models -o /share/temp/sgeoutput/dccasey/output -e /share/temp/sgeoutput/dccasey/errors -N ", jname, " ", "-pe multi_slot ", mycores, " ", "-l mem_free=", mycores *2, "G ")
#   #
#   command =paste(sys.sub, rshell, rscript, args)
#   
#   #print(command)
#   system(command)
# 

