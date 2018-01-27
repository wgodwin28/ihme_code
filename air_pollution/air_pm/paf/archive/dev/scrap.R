# Author: Joseph Frostad, and I am a hoarder
# 
# Date: 6/22/2015
# Project: GBD MAPS CHINA COAL BURDEN
# Use: Scrap code from previous iterations of this project
# --------------------------------------------------------------------------------------------------------------------------------


# -----------------------------------------------------------------------------------------------------------
# # read in industry coal, then intersect with project coordinates and melt into a coherent data file
# industry.coal.matrix <- as.matrix(read.table(paste0(data.directory,"/industry_coal_contribution.txt")))
# colnames(industry.coal.matrix) <- project.coordinates[1,-1]
# rownames(industry.coal.matrix) <- project.coordinates[-1,1]
# industry.coal <- melt(industry.coal.matrix)
# names(industry.coal) <- c("y","x","industrial")
# 
# # read in powerplant coal, then intersect with project coordinates and melt into a coherent data file
# powerplant.coal.matrix <- as.matrix(read.table(paste0(data.directory,"/powerplant_coal_contribution.txt")))
# colnames(powerplant.coal.matrix) <- project.coordinates[1,-1]
# rownames(powerplant.coal.matrix) <- project.coordinates[-1,1]
# powerplant.coal <- melt(powerplant.coal.matrix)
# names(powerplant.coal) <- c("y","x","powerplant")
# 
# # read in domestic coal, then intersect with project coordinates and melt into a coherent data file
# domestic.coal.matrix <- as.matrix(read.table(paste0(data.directory,"/domestic_coal_contribution.txt")))
# colnames(domestic.coal.matrix) <- project.coordinates[1,-1]
# rownames(domestic.coal.matrix) <- project.coordinates[-1,1]
# domestic.coal <- melt(domestic.coal.matrix)
# names(domestic.coal) <- c("y","x","domestic")
# 
# # merge subsectors of coal to create one comprehensive dataset
# total.coal <- merge(total.coal,industry.coal,by=c("y","x"))
# total.coal <- merge(total.coal,powerplant.coal,by=c("y","x"))
# total.coal <- merge(total.coal,domestic.coal,by=c("y","x"))
#   
#   # #Create an id column
#   #   total.coal$id <- 1:length(total.coal$x)
#   #   # Make a raster of the id column
#   #   total.coal.sp <- total.coal[, c("x", "y", "id")]
#   #   coordinates(total.coal.sp) = ~x+y
#   #   proj4string(total.coal.sp)=CRS("+init=epsg:4326")
#   gridded(total.coal.sp) = TRUE # this doesnt work, i believe because as Mike noted the grid centroids are 2/3 degree by longitude and 1/2 degree by latitude, so not an even grid? keep looking into this and the "rasterize" command
# #   total.coal.sp <- raster(total.coal.sp[, c("id")])
# 
# total.coal.raster <- raster()
# extent(total.coal.raster) <- getExtent(total.coal)
# total.coal.raster <- rasterize(total.coal[,2:1], total.coal.raster, total.coal[,3], fun=mean)
# pm.raster <- rasterize(country.year.exp[,c("x","y")], total.coal.raster, country.year.exp[,"calib"], fun=mean)
# pm.raster <- rasterize(pollution[,c("x","y")], total.coal.raster, pollution[,"fus_2011"], fun=mean)
# total.coal.resampled <- resample(total.coal.raster, pm.raster, method="bilinear")
# 
# total.coal.resampled <- resample(total.coal.raster, pollution.sp, method="bilinear")
# 
# # older version of this function: create raster layers of coal data at the resolution of the air PM data
# rasterBuilder <- function(subsector, coal.source.file, pollution.source.file){
#   
#   # create a blank raster
#   blank.raster <- raster()  
#   
#   # find the dimensions from the coal source data
#   xMIN <- min(coal.source.file[,"x"])
#   xMAX <- max(coal.source.file[,"x"])
#   yMIN <- min(coal.source.file[,"y"])
#   yMAX <- max(coal.source.file[,"y"])
#   
#   # find the dimensions from the pollution data
#   xMIN <- min(pollution.source.file[,"x"])
#   xMAX <- max(pollution.source.file[,"x"])
#   yMIN <- min(pollution.source.file[,"y"])
#   yMAX <- max(pollution.source.file[,"y"])    
#   
#   # set the rasters extent to clip it to these dimensions
#   raster.extent <- c(xMIN,xMAX,yMIN,yMAX) 
#   blank.raster <- setExtent(blank.raster,raster.extent,keepres=TRUE)
#   
#   # create a raster from the coal data
#   raw.coal.raster <- rasterize(coal.source.file[,c("x","y")], blank.raster, coal.source.file[,subsector], fun=mean)
#   
#   # create a raster from the air PM (calibrated PM) data
#   pm.raster <- rasterize(pollution.source.file[,c("x","y")], blank.raster, pollution.source.file[,"fus"], fun=mean)
#   pm.raster <- rasterFromXYZ(pollution.source.file[,c("x","y","fus")])
#   
#   # create a raster from the air PM (population) data
#   #       pop.raster <- rasterize(pollution.source.file[,c("x","y")], blank.raster, pollution.source.file[,"pop"], fun=mean) 
#   pop.raster <- rasterFromXYZ(pollution.source.file[,c("x","y","pop")])
#   
#   # resample the coal raster down to the resolution of the air PM data
#   resampled.raster <- resample(raw.coal.raster, pm.raster, method="bilinear")
#   
#   # combine the resampled coal raster and the pm raster into a list and output both of them
#   output <- list("coal" = resampled.raster, "fused_pm" = pm.raster, "pop" = pop.raster)
#   
#   return(output)
#   
# }
# 
# #requires the rasterVis package, which requires the zoo package and I am having trouble downloading
# theme_set(theme_bw())
# gplot(raster.stack) + geom_tile(aes(fill = value)) +
#   facet_wrap(~ variable) +
#   scale_fill_gradient(low = 'white', high = 'blue') +
#   coord_equal()
# 
# params <- rr.curves[[paste0(ccc, "_", aaa)]][1, ]
# 
# plot(ifelse(values(stack[[3]]) > params$tmred, 1+(params$alpha*(1-exp(-params$beta*((values(stack[[3]])-params$tmred)/1e10)^params$gamma))), 1))
# 
# RR <- fobject$eval(stack[[1]], rr.curves[[paste0(ccc, "_", aaa)]][1, ])
# 
# coal.data <- as.data.frame(llply(subsectors, 
#                                  readCoordinates, 
#                                  coordinate.file = project.coordinates))
# 
# raster.list <- llply(subsector, 
#                      rasterBuilder, 
#                      coal.source.file = coal.data, 
#                      pm.raster = pollution.sp,
#                      .inform=TRUE)
# 
# # take the list of rasters returned by rasterBuilder (above) and layer them to create a rasterStack object
# rasterStacker <- function(raster.list){
#   
#   #create first layer of stack
#   master.raster <- stack(raster.list[[1]])
#   
#   #add each additional coal layer to raster stack 
#   for(i in 2:length(raster.list)){
#     
#     master.raster <- addLayer(master.raster, raster.list[[i]])
#     
#   }
#   
#   return(master.raster)
#   
# }
# 
# # create a list of coal subsectors to loop through and rasterize
# subsectors <- c("total","industrial","powerplant","domestic")
# 
# 
# # out.paf[age.cause.number, 1:1000] <- lapply(1:1000, function(draw.number) (sum((RR[,draw.number] - 1)*exposure.data$pop) / sum(RR[,draw.number]*exposure.data$pop)))
# 
# 
# system.time(RR1 <- lapply(1:1000, function(draw.number) fobject$eval(exposure.data[, get(paste0("calib_",draw.number))], rr.curves[[paste0(cause.code, "_", age.code)]][draw.number, ])))
# 
# 

# iso.codes <- read.csv(paste0(root, "/Project/COAL/correspondence/china_location_id_to_province_name.csv"))

# # Prep iso name for subnational data (used to insheet the burden data, saved by subnational name)
# iso.codes <- iso.codes[,c("location_id","location_name")]
# iso.codes$iso3 <- paste0("CHN_", iso.codes$location_id)
# country.name <- iso.codes[iso.codes$iso3==this.country, c("location_name")]
# 
# # Prep the burden data for this subnational unit
# country.burden <- data.table(read.csv(paste0(burden.dir,"/",country.name,".csv")))
# 
# # replace the verbose cause names in the burden file with cause codes
# # first supply the values you want to find/replace as vectors
# old.causes <- c('Cerebrovascular disease', 
#                 'COPD', 
#                 'Ischemic heart disease', 
#                 'Lower respiratory infections', 
#                 'Lung cancer')    
# 
# replacement.causes <- c('cvd_stroke', 
#                         'resp_copd', 
#                         'cvd_ihd', 
#                         'lri', 
#                         'neo_lung')
# 
# # then pass to your custom function
# country.burden <- findAndReplace(country.burden,
#                                  old.causes,
#                                  replacement.causes,
#                                  "cause",
#                                  "cause")
# 
# # replace the age names in the burden file with age codes
# # first supply the values you want to find/replace as vectors
# age.names <- c('EN', 
#                'LN', 
#                'PN', 
#                'All')  
# 
# age.codes <- c('0.00', 
#                '0.01', 
#                '0.10', 
#                '99')    
# 
# # then pass to your custom function
# country.burden <- findAndReplace(country.burden,
#                                  age.names,
#                                  age.codes,
#                                  "age_start",
#                                  "age") #change the name of this variable to reflect the data I want to merge onto later
# 
# # convert age names to characters with 2 decimal places to prep for eventual merge
# country.burden <- country.burden[, age:=round(as.numeric(age), digits=2)]

# deaths.dir <- paste0(root, "/Project/COAL/data/deaths")
# ylds.dir <- paste0(root, "/Project/COAL/data/epi")

# # Bring in and prep country disease burden files
# country.deaths <- fread(paste0(deaths.dir,"/CHN_deaths_compiled.csv"))
# country.deaths$cause <- country.deaths$acause #change to match your variable naming structure (potentially revisit to reduce complexity)
# country.ylds <-fread(paste0(ylds.dir,"/CHN_ylds_compiled.csv"))
# country.ylds$cause <- country.ylds$acause #change to match your variable naming structure (potentially revisit to reduce complexity)

# # Merge on and calculate attributable disease deaths (Deaths * PAF)
# country.deaths <- merge(country.deaths[iso3==this.country], out.paf.mort, by=c("age","cause"), allow.cartesian=T)
# 
# # create a list of draw names based on the required number of draws for this run
# draw.colnames <- c(paste0("draw_",0:(draws.required-1)))
# 
# # calculate attributable deaths (deaths * PAF)
# invisible(lapply(1:draws.required, function(draw.number) {
#   
#   country.deaths[, draw.colnames[draw.number] := country.deaths[, draw.colnames[draw.number], with=FALSE] * country.deaths[, paf.draw.colnames[draw.number], with=FALSE]]
#   
# }))
# 
# # generate mean and CI for summary figures
# country.deaths[,deaths_lower := quantile(.SD ,c(.025)), .SDcols=draw.colnames, by=list(sex,cause,age,subsector)]
# country.deaths[,deaths_mean := rowMeans(.SD), .SDcols=draw.colnames, by=list(sex,cause,age,subsector)]
# country.deaths[,deaths_upper := quantile(.SD ,c(.975)), .SDcols=draw.colnames, by=list(sex,cause,age,subsector)]
# 
# # Save summary version of output for experts 
# country.deaths.summary <- country.deaths[, c("age",
#                                              "sex",
#                                              "cause",
#                                              "subsector",
#                                              "deaths_lower",
#                                              "deaths_mean",
#                                              "deaths_upper"), 
#                                          with=F]
# 
# #Order columns to your liking
# country.deaths.summary <- setcolorder(country.deaths.summary, c("cause", 
#                                                                 "age",
#                                                                 "sex",
#                                                                 "subsector",
#                                                                 "deaths_lower", 
#                                                                 "deaths_mean", 
#                                                                 "deaths_upper"))
# 
# # Save Deaths 
# if (write.burden == TRUE) {
#   
#   write.csv(country.deaths, paste0(out.burden.dir, "/", output.version, "/draws/deaths_", this.country, "_", this.year, "_", subsector,".csv"))   
#   write.csv(country.deaths.summary, paste0(out.burden.dir, "/", output.version, "/summary/deaths_", this.country, "_", this.year, "_", subsector,".csv"))  
#   
# }

# # Merge on and calculate attributable morbidity (YLD * PAF)
# country.ylds <- merge(country.ylds[iso3==this.country], out.paf.morb, by=c("age","cause"), allow.cartesian=T)
# 
# # create a list of draw names based on the required number of draws for this run
# draw.colnames <- c(paste0("draw_",0:(draws.required-1)))
# 
# # calculate attributable burden (YLD * PAF)
# invisible(lapply(1:draws.required, function(draw.number) {
#   
#   country.ylds[, draw.colnames[draw.number] := country.ylds[, draw.colnames[draw.number], with=FALSE] * country.ylds[, paf.draw.colnames[draw.number], with=FALSE]]
#   
# }))
# 
# # generate mean and CI for summary figures
# country.ylds[,ylds_lower := quantile(.SD ,c(.025)), .SDcols=draw.colnames, by=list(sex,cause,age,subsector)]
# country.ylds[,ylds_mean := rowMeans(.SD), .SDcols=draw.colnames, by=list(sex,cause,age,subsector)]
# country.ylds[,ylds_upper := quantile(.SD ,c(.975)), .SDcols=draw.colnames, by=list(sex,cause,age,subsector)]
# 
# # Save summary version of output for experts 
# country.ylds.summary <- country.ylds[, c("age",
#                                          "sex",
#                                          "cause",
#                                          "subsector",
#                                          "ylds_lower",
#                                          "ylds_mean",
#                                          "ylds_upper"), 
#                                      with=F]
# 
# #Order columns to your liking
# country.ylds.summary <- setcolorder(country.ylds.summary, c("cause", 
#                                                             "age",
#                                                             "sex",
#                                                             "subsector",
#                                                             "ylds_lower", 
#                                                             "ylds_mean", 
#                                                             "ylds_upper"))
# 
# # Save ylds 
# if (write.burden == TRUE) {
#   
#   write.csv(country.ylds, paste0(out.burden.dir, "/", output.version, "/draws/ylds_", this.country, "_", this.year, "_", subsector,".csv"))    
#   write.csv(country.ylds.summary, paste0(out.burden.dir, "/", output.version, "/summary/ylds_", this.country, "_", this.year, "_", subsector,".csv"))  
#   
# }


# # calculate the amount of PM from the given coal subsector
# fus.from.coal.colname = paste0("fus_",subsector)
# exposure.data[, (fus.from.coal.colname) := fus*get(subsector)]


# Subset data to country in question
# country.exp <- exp[exp$iso3_child == this.country,]
# country.exp$calib <- exp(0.41765+log(country.exp$fus)*0.86953)

# calculate calibrated exposure (note this stage must occur before merging onto the coal data, because that merge causes the data to resort. due to the error listed below, this resort causes small deviations in the PAF due to the way the error manifests, disregarding the covariance. To elaborate, the X.intercepts are applied across columns instead of across rows. If the data is resorted before this happens, it will change the result. Once you get clearance to fix this bug, you can do this after the merge.)
# country.year.exp[, calib.draw.colnames] <- exp(reg.draws$X.Intercept. + outer(log(country.year.exp$fus), reg.draws$log.fused.)) #OLD METHOD: toggle if using advanced regression (this is an old way of calculating the calibrated exposure, I have determined that it applies the x.intercepts incorrectly and therefore does not take covariance into account correctly. this leads to inaccurate confidence intervals. For now we are sticking with this method to maintain consistence, fix it in the future)