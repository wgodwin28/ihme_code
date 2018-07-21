#launcher script to extract pixel level temps and generate national level temperature averages by day
rm(list=ls())
# source('/snfs2/HOME/wgodwin/temperature/era_interim/launch_make_national_estimates.R', echo =T)

#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

data.dir = paste0(j,'temp/wgodwin/temperature/exposure/raw_data/')
out.dir = paste0(j,'temp/wgodwin/temperature/exposure/prepped_data/')
shapefile.dir = paste0(j, "DATA/SHAPE_FILES/GBD_geographies/master/GBD_2017/master/shapefiles")

#set variables for parallelization
code.dir = paste0('/snfs2/HOME/wgodwin/temperature/')
mycores = 20
minmax = F
save.dir = paste0(out.dir, 'era_', ifelse(minmax, 'minmax/', 'mean/')) **


#make folder structure
dir.create(save.dir, recursive = T)

args = paste(data.dir, save.dir, shapefile.dir)
rscript = paste0(code.dir, 'era_interim/era_make_daily_by_year.R') **
rshell = paste0(code.dir, 'r_shell.sh')
errors = '-o /share/temp/sgeoutput/wgodwin/output -e /share/temp/sgeoutput/wgodwin/errors'
jname = 'calc_national_era_mean'

