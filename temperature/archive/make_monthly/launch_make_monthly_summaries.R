#launcher script to create monthly summaries of temperature from the reforcast data
library('ncdf4')
library(raster)

#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
  work.dir = 'C:/Users/dccasey/Documents/ihme_work/temperature/data/'
  daily_temp_fp = 'C:/Users/dccasey/Documents/ihme_work/temperature/data/tmp_2m_gaussian_c00_19890101_20161221_daniD1Ll12.nc'
} else{
  j = '/home/j/'
  work.dir = '/share/geospatial/temperature/data/'
  daily_temp_fp = '/share/geospatial/temperature/data/tmp_2m_gaussian_c00_19890101_20161221_daniD1Ll12.nc'
}

#set variables for parallelization
code.dir = paste0('/ihme/code/geospatial/temperature/malaria/africa_covs/')
mycores=40

#get the months required from the netcdf file
dailyt = brick(daily_temp_fp)
days = names(dailyt)

rm(dailyt)

#notation appears to be YYYY.MM.DD.HH.MM.SS with X as a prefix
#create a grid of months and years to aggregate
years = 1989:2015
months = 1:12

yymm = data.table(expand.grid(year = years,month = months))
yymm[,month:= sprintf("%02d", month)]

#order by year - month
setorder(yymm, year,month)

#save the grid
save(yymm, file = paste0(work.dir, 'yymm_grid.Rdata'))


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

