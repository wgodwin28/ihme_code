#launcher script to create monthly summaries of temperature from the reforcast data

# source('/ihme/code/geospatial/temperature/era_interim/launch_era_make_daily_by_year.R', echo =T)

#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

data.dir = paste0(j,'/temp/dccasey/temperature/era_interim/')
out.dir = '/share/geospatial/temperature/'

#set variables for parallelization
code.dir = paste0('/ihme/code/geospatial/temperature/era_interim/')
mycores = 30
minmax = T
save.dir = paste0(out.dir, 'estimates/', ifelse(minmax, 'minmax/', 'mean/'))


#make folder structure
dir.create(save.dir, recursive = T)

args = paste(mycores, as.character(minmax), save.dir)
rscript = paste0(code.dir, 'era_make_daily_by_year.R')
rshell = paste0('/ihme/code/geospatial/temperature/r_shell.sh')
errors = '-o /share/temp/sgeoutput/dccasey/output -e /share/temp/sgeoutput/dccasey/errors'
jname = 'calc_daily_era'
sys.sub <- paste0("qsub -P proj_geospatial ", errors, " -N ", jname, " ", "-pe multi_slot ", mycores, " ", "-t 1:28") #array job, era that I've downloaded exists for 1989-2016
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

