#Rasterize gbd 2017 shapefiles to appropriate formate for paf calculation
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}
options(scipen=999)

#load libraries
pack_lib = '/home/j/temp/dccasey/temperature/packages/'
.libPaths(pack_lib)
library('parallel')
library('sp')
library('rgdal', lib.loc = '/home/j/temp/geospatial/packages')
for(ppp in c('raster','ncdf4','data.table')){
  library(ppp, lib.loc = pack_lib, character.only =T)
}

#necessary sourcing and directory objects
source(paste0(j,'/temp/central_comp/libraries/current/r/get_location_metadata.R'))
output.dir = paste0(j,'/temp/wgodwin/temperature/shapes/gbd_shapes/')

#grid options
grids = c('cru_spline_interp', 'era_mean')

#load gbd shapefile
gbd_shape = readOGR(paste0(j,'/DATA/SHAPE_FILES/GBD_geographies/master/GBD_2017/master/shapefiles'), 'GBD2017_analysis_final')

#load list of cod locations
cod_locs = get_location_metadata(location_set_id = 35)
ll_locs = as.vector(cod_locs[is_estimate == 1,location_id])

#loop through grip options
for(ggg in grids){
  print(ggg)
  data.dir = paste0('/share/geospatial/temperature/estimates/',ggg,'/')
  temp_grid = brick(paste0(data.dir,list.files(path = data.dir, pattern = as.character(2000))))[[1]]
  
  #check for rotation
  rotate_me = ifelse(extent(temp_grid)[2] >183, T, F)
  if(rotate_me) temp_grid = rotate(temp_grid)
  
  #begin rasterizing
  prefix = substr(ggg, 1, 3)
  rasterize(gbd_shape[gbd_shape$level == 3,], temp_grid, 'loc_id', filename = paste0(output.dir,prefix,'admin0.tif'))
  rasterize(gbd_shape[gbd_shape$loc_id %in% ll_locs,], temp_grid, 'loc_id', filename = paste0(output.dir,prefix,'isestimate.tif'))
}