#Make monthly temperature data

library('ncdf4')
library('raster')

#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
  work.dir = 'C:/Users/dccasey/Documents/ihme_work/temperature/data/'
  task_id = 1
} else{
  j = '/home/j/'
  work.dir = '/share/geospatial/temperature/data/'
}


#load command args
temperature_file = 'C:/Users/dccasey/Documents/ihme_work/temperature/data/tmp_2m_gaussian_c00_19890101_20161221_daniD1Ll12.nc' #as.character(commandArgs()[3])
task_id <- Sys.getenv("SGE_TASK_ID")


#load the temperature data and the governing grid
load(paste0(work.dir, 'yymm_grid.Rdata'))


#load the temperature dataset and get its names
dailyt = brick(temperature_file)
days = names(dailyt)


#calculate the monthly mean temperature
monthly_mean = function(year, month, days, tbrick){
  m_days = grep(paste0(year,'.',month), days, value = T)
  tbrick = tbrick[[m_days]]
  mm_ras = mean(tbrick)
  
  #convert to celcius
  mm_ras = mm_ras- 273.15
  
  names(mm_ras) = paste0('y',year,'m',month)
  return(mm_ras)
}

mm_rasters = lapply(1:nrow(yymm), function(x) monthly_mean(yymm[x,year],yymm[x,month],days,dailyt))

#open cru data
cru = brick(paste0(work.dir, 'cru_ts/cru_ts3.24.2001.2010.tmp.dat.nc'))


#open reanalysis data
rean = brick(paste0(work.dir, 'air.2m.gauss.2005.nc'))
