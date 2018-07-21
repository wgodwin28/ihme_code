rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

#install pacman library
#if("pacman" %in% rownames(installed.packages())==FALSE){
 # library(pacman,lib.loc="/homes/wgodwin/R/x86_64-pc-linux-gnu-library/3.3")
#}

# load packages, install if missing
pack_lib = '/snfs2/HOME/wgodwin/R'
#pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
pacman::p_load(data.table, parallel, magrittr, raster, stringr, RMySQL, snow, ncdf4)

serial <- T
#Collect arguments
if(serial){
  task_id <- 1
  slots = 6
  minmax = F
  proj = "era_interim"
  mean_calc <- T
  data.dir = paste0(j,'temp/wgodwin/temperature/exposure/raw_data/downloaded/', proj, '/')
  ifelse(mean_calc, out.dir <- paste0(j,'WORK/05_risk/risks/temperature/data/exp/prepped/mean/', proj, '/'),
         out.dir <- paste0(j,'WORK/05_risk/risks/temperature/data/exp/prepped/min_max/', proj, '/'))
  code.dir = paste0('/snfs2/HOME/wgodwin/temperature/')
} else {
  task_id <- as.numeric(Sys.getenv("SGE_TASK_ID"))
  slots = as.numeric(commandArgs()[2])
  minmax = as.logical(commandArgs()[3])
  data.dir = as.character(commandArgs()[4])
  save.dir = as.character(commandArgs()[5])
  code.dir = as.character(commandArgs()[6])
  proj = as.character(commandArgs()[7])
  mean_calc <- F
}

for(year in seq(1990,2017)) {
#set year
#year = task_id + 1899 # starts at 1980

  #check to make sure things passed properly
  if(serial){
   cores_to_use <- 6
   print(paste(task_id, slots, year, minmax, proj, data.dir, out.dir))
  } else {
    print(commandArgs())
    print(paste(task_id, slots, year, minmax, save.dir))
    
    cores_to_use = ifelse(grepl('Intel', system("cat /proc/cpuinfo | grep \'name\'| uniq", inter = T)), floor(slots * .86), floor(slots*.64))
  }

  
  #set raster options
  #num_cells = round(((slots*2)-20)/7) * 1e9 #leave some overhead for other memory
  num_cells <- 1e11
  rasterOptions(maxmemory = num_cells) #1e9 is like 7 gigs I think
  
  #load the landsea mask, convert into a matrix, change everything on sea into NA, then convert back to raster
  landsea = raster(paste0(data.dir,grep('landsea_grib',list.files(data.dir),value = T)))
  landsea[landsea==0] = NA
  
  #find the proper dataset
  pos_files = list.files(data.dir, pattern = proj)
  selected_file = substr(gsub('\\D',"", pos_files),3,100)
  which_file = sapply(selected_file, function(x) any(year %in% as.numeric(substr(x,1,4)):as.numeric(substr(x,5,8))))
  
  #load the proper dataset
  era = brick(paste0(data.dir, pos_files[which_file]))
  #era = brick(paste0(data.dir, "era_int_1987_88.nc"))
  era = era[[grep(year, names(era))]]
  #era = era[[!grepl(1900, names(era))]]
  source(paste0(code.dir, 'functions/era_functions.R'))
  
  if(mean_calc){
    #functions to calculate daily mean
    era = era_daily_mean(ras = era, ls_mask = landsea, minmax = minmax, cores = cores_to_use)
    
    #write the results
    writeRaster(era, paste0(out.dir,year,'_mean_', ifelse(minmax, 'minmaxmethod','meanmethod'),'.ncdf'), overwrite = T)
    print(paste0("Saved daily mean for ", year))
  }else{
    #Subset to minimum(6:00am) and maximum(12:00pm)
    min <- c(06,07)
    max <- c(12,13)
    for(value in c("min", "max")) {
      r <- era[[grep(paste(get(value), collapse = "|"),substr(names(era), 13, 14))]]
      r <- mask_sea(ras = r, ls_mask = landsea, cores = cores_to_use)
      writeRaster(r, paste0(out.dir, "global_dwpt_", year,"_",value, '.ncdf'), overwrite = T)
      print(paste("Saved daily minmax for", year, value))
    }
  }
}
#end script
