#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}
options(scipen=999)

#Collect arguments
argue = commandArgs(trailingOnly = T)
task_id <- as.numeric(Sys.getenv("SGE_TASK_ID"))
slots= as.numeric(argue[1])
year = as.numeric(argue[2])
temperature_product = as.character(argue[3]) #'era_mean' #
admin_level = as.character(argue[4])#'admin0' #'isestimate'
the_cause = as.character(argue[5]) #'diabetes'#make sure to do the memory math, in qsub, use 30+ slots
paf_version = as.character(argue[6]) #'test'
tmrel_version = as.character(argue[7]) #'test'
risk_version = as.character(argue[8]) #test'
convert_kelvin = as.logical(argue[9]) #T

#set conditional variables
draw = task_id -1
data.dir = paste0('/share/geospatial/temperature/estimates/', temperature_product,'/')
cores_to_use = ifelse(grepl('Intel', system("cat /proc/cpuinfo | grep \'name\'| uniq", inter = T)), floor(slots * .86), floor(slots*.64))
pop.dir = paste0(j,'WORK/01_covariates/02_inputs/population_counts/outputs/full_ts_1980_2015/')
data_product = substr(temperature_product, 1,regexpr('\\_', temperature_product)-1)

#check to make sure things passed properly
print(commandArgs())
print(paste(task_id, draw, slots, year, temperature_product,admin_level, the_cause, paf_version, tmrel_version,risk_version,convert_kelvin))

#load libraries
pack_lib = '/home/j/temp/dccasey/temperature/packages/'
.libPaths(pack_lib)
library('parallel')
for(ppp in c('data.table','raster','ncdf4', 'sp', 'rgdal', 'pryr','profvis')){
  suppressMessages(library(ppp, lib.loc = pack_lib, character.only =T))
}

source(paste0('/home/j/temp/central_comp/libraries/current/r/get_location_metadata.R'))

#set raster options
num_cells = round(((slots*2)-20)/7) * 1e9 #leave some overhead for other memory
rasterOptions(maxmemory = num_cells) #1e9 is like 7 gigs I think

#find and load the proper dataset
expo = brick(paste0(data.dir,list.files(path = data.dir, pattern = as.character(year))))
#convert to degrees C
if(convert_kelvin) expo = expo -273.15

#decide if things need rotation. If xmax is >183 (180, but with a lil offset), rotate things
rotate_me = ifelse(extent(expo)[2] >181, T, F)
if(rotate_me) expo = rotate(expo)

#find and load relevant population grid
pop = raster(paste0(pop.dir, 'glp',year,'ag.tif'))

#crop expo to the pop grid
expo = crop(expo, pop)

#find and load relevant rasterized locations
locs = raster(paste0(j,'/temp/dccasey/temperature/data/rasterized_shapefiles/',data_product, admin_level,'.tif')) #should be more flexible to get era interim working
locs = crop(locs, pop)

#aggregate population to the exposure cell size
pop_fact = round(dim(pop)[1:2] / dim(expo)[1:2])
pop = aggregate(pop, pop_fact)
pop = resample(pop, expo)

#load tmrel brick
load(paste0('/share/geospatial/temperature/estimates/tmrel/tmrel_', tmrel_version,'.Rdata'))
#for now, tmrel is a single draw/value tmrel = tmrel[[draw + 1]] #tmrel is index 1-1000 I think

#resample TMREL is the bricks don't match
tmrel = crop(tmrel, expo)
tmrel = resample(tmrel,expo)

#load risk brick
load(paste0('/share/geospatial/temperature/estimates/risk/temperature_risks_', risk_version, '.Rdata'))

#keep relevant draw
risk = risk_grid[acause == the_cause,.(acause, age_group_id, sex_id, element, measure, risk = get(paste0('pc_',draw)))]
rm(risk_grid)

#convert relevant objects to arrays and matrixces
expo = as.array(expo)
pop = as.matrix(pop)
tmrel = as.matrix(tmrel)
locs = as.matrix(locs)

print(lapply(list(expo, pop, tmrel, locs), function(x) dim(x)))

#preserve the dimensions of expo
expo_dim = dim(expo)

make_deg_thresh = function(exp_mat, tmrel_mat, hot = T){
    exp_mat = exp_mat - tmrel_mat

    #do heat/cold 0ing out
    if(hot){
       exp_mat[exp_mat<0] = 0
    } else{
        exp_mat[exp_mat>0] = 0
        exp_mat = abs(exp_mat)
    }

    return(exp_mat)
}

#convert the exposure into degrees from threshold
deg_thresh_hot = array(apply(expo,3, function(x) make_deg_thresh(x,tmrel, T)),expo_dim)
deg_thresh_cold = array(apply(expo,3, function(x) make_deg_thresh(x,tmrel, F)),expo_dim)

rm(expo)

convert_deg_to_risk = function(exp_mat, risk_val, adj=.01){
    #assumes risk val is in percent change; returns RR
    risk_mat = 1+(exp_mat * (risk_val)*adj)
}

select_proper_exp_mat = function(name_hot, name_cold, return_hot = T){
    if(return_hot){
        return(get(name_hot))
    } else {
        return(get(name_cold))
    }
}

mem_used()

#create a risk grid per age, sex, measure, element, for the selected-cause draw
#each array is about .6 gigs. Expect nrow(risk) * .6 memory
risk_arrays = mclapply(1:nrow(risk), function(row_num) array(convert_deg_to_risk(
                exp_mat = select_proper_exp_mat('deg_thresh_hot', 'deg_thresh_cold', risk[row_num, element]=='heat'),
                risk_val = risk[row_num,risk]),expo_dim),mc.preschedule=F, mc.cores = cores_to_use)

rm(deg_thresh_hot)
rm(deg_thresh_cold)

#create a simple version of zonal sums to work with matrices
extract_mat = function(valmat, gmat, gvalue){
    #valmat: matrix of values we want to extract
    #gmat: matrix whose values represent the group
    #gvalue: the value in gmat we want to get the zonal sum for
    #returns a dataframe with 1 row

    maskmat = gmat==gvalue
    aggval = sum(valmat * maskmat,na.rm=T)
    return(aggval)
}

#get the country list
location_list = unique(as.vector(locs))
location_list= location_list[!is.na(location_list)]

Sys.time()
mem_used()
#collapse risk from daily to yearly and split by num/denom for paf calculation. Give the node some wiggle room
yr_denom = lapply(risk_arrays, function(r_a) apply(r_a, 1:2, function(x) sum(x, na.rm =T)))
mem_used()
risk_arrays = lapply(risk_arrays, function(x) x-1) #subtract one to get excess risk
mem_used()
yr_num   = lapply(risk_arrays, function(r_a) apply(r_a, 1:2, function(x) sum(x,na.rm=T)))
mem_used()
Sys.time()

rm(risk_arrays)
mem_used()
gc()

#for each country, find the population weighted risk/PAF for each cause
#this should be improved
Sys.time()
pafs = lapply(location_list, function(loc_id)
            mclapply(1:nrow(risk), function(row_id)
                extract_mat(yr_num[[row_id]] * pop, locs, loc_id)/extract_mat(yr_denom[[row_id]] * pop, locs, loc_id),
                mc.cores = cores_to_use, mc.preschedule=F))
Sys.time()

#convert to data tables
pafs = lapply(pafs, function(x) cbind(risk, data.table(paf = as.numeric(x))))

#add location id
pafs = lapply(1:length(location_list), function(x) cbind(pafs[[x]], location_id = location_list[[x]]))

#rbind everything together
pafs = rbindlist(pafs)

setnames(pafs, 'paf', paste0('paf_',draw))
pafs[,year_id := year]

write.csv(pafs, file = paste0('/share/geospatial/temperature/estimates/paf/',temperature_product,'/',paf_version,'/',the_cause, '_', year,'_',draw,'.csv'))

warnings()

message('The End')


