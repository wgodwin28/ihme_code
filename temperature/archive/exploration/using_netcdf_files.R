library('ncdf4')
library('raster')
nc_file_path = "C:/Users/dccasey/Documents/ihme_work/temperature/data/tmp_2m_gaussian_c00_19890101_20161221_daniD1Ll12.nc"
test = brick(nc_file_path,varname = 'Temperature_height_above_ground')


mycdf = nc_open(nc_file_path)
timedata <- ncvar_get(mycdf,'intTime')
lat = ncvar_get(mycdf,'lat')
lon = ncvar_get(mycdf,'lon')


#create a grid from the lat and long




temper = ncvar_get(mycdf, 'Temperature_height_above_ground', count = c(-1,-1,1))

#convert to degrees F
temper = temper * 9/5 - 459.67


ras = raster(t(temper))
