#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

data.dir = paste0(j,'temp/dccasey/temperature/data/era_interim/')

#Collect arguments
task_id <- as.numeric(Sys.getenv("SGE_TASK_ID"))
slots=as.numeric(commandArgs()[3])
minmax = as.logical(commandArgs()[4])
save.dir = as.character(commandArgs()[5])
#set year
year = task_id + 1988

#check to make sure things passed properly
print(commandArgs())
print(paste(task_id, slots, year, minmax, save.dir))

cores_to_use = ifelse(grepl('Intel', system("cat /proc/cpuinfo | grep \'name\'| uniq", inter = T)), floor(slots * .86), floor(slots*.64))

#load libraries
pack_lib = '/home/j/temp/dccasey/temperature/packages/'
.libPaths(pack_lib)
library('parallel')
library('sp')
library('rgdal', lib.loc = '/home/j/temp/geospatial/packages')
for(ppp in c('raster','ncdf4','data.table')){
  library(ppp, lib.loc = pack_lib, character.only =T)
}

#set raster options
num_cells = round(((slots*2)-20)/7) * 1e9 #leave some overhead for other memory
rasterOptions(maxmemory = num_cells) #1e9 is like 7 gigs I think

#load the landsea mask and convert into a matrix
landsea = raster(paste0(data.dir,grep('land',list.files(data.dir),value = T)))
landsea = as.matrix(landsea)
landsea[landsea==0] = NA

#find the proper dataset
pos_files = list.files(data.dir, pattern = 'era_interim_4xdaily_temp2m')
selected_file = substr(gsub('\\D',"", pos_files),3,100)
which_file = sapply(selected_file, function(x) any(year %in% as.numeric(substr(x,1,4)):as.numeric(substr(x,5,8))))

#load the proper dataset
era = brick(paste0(data.dir, pos_files[which_file]))
era = era[[grep(year, names(era))]]

#functions to calculate daily mean
source(paste0('/ihme/code/geospatial/temperature/functions/era_functions.R'))
era = era_daily_mean(ras = era, ls_mask = landsea, minmax = minmax, cores = cores_to_use)

#write the results
writeRaster(era, paste0(save.dir,year,'_mean_', ifelse(minmax, 'minmaxmethod','meanmethod'),'.ncdf'), overwrite = T)

#end script
