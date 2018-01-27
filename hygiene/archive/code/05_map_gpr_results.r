## Install  the following packages if necessary
  # install.packages("RColorBrewer")
  # install.packages("maptools")
  # install.packages("gpclib")


## load the function
rm(list=ls())
##source("J:/Project/COMIND/Water and Sanitation/Graphs/Code/map_function.r")
source("J:/DATA/SHAPE_FILES/IHME_OFFICIAL/GLOBAL/GBD v2/GIS_WITH_INSETS/GBD_WITH_INSETS_MAPPING_FUNCTION.r")
library(foreign)
library(RColorBrewer)

  
## read in and format data
data_full <- read.dta("J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/output/maps/gpr_results_for_mapping.dta", convert.factor=F)

  
## specify the indicators and years to map for
types <- c("1980", "1990", "2005", "2010", "2013")
indicators <- c("hwws")

## loop through measurement types
for (j in 1:length(types)) {
  ## loop through indicators
  for (i in 1:length(indicators)) {
    ## set parameters
    type <- types[j]
    indicator <- indicators[i]
  	indicator_var <- paste(tolower(indicator), "_", type, sep="")
	if (grepl("hw", indicator)) graph <- "Hygiene" 
    
    ## reduce to the variables that need to be mapped
    data <- data_full[, c("iso3", indicator_var)]
    colnames(data) <- c("iso3", "mapvar")
    data$mapvar <- as.numeric(data$mapvar)
    data$mapvar[is.na(data$mapvar)] <- 0
      
    ## set limits based on type
    if (type == types[j]) {
      limit_vec = c(0, 10, 15, 20, 30, 40, 100)
      label_vec = c("<10%", "10%-15%", "15%-20%", "20%-30%", "30%-40%", ">40%")
      ##title_vec = paste("Access to Improved ", indicator, " in ", type, sep="")
	  title_vec = paste( indicator, " in ", type, sep="")
    } ##else if (type == "change") {
      ##limit_vec = c(-100, 0, 10, 20, 30, 100)
      ##label_vec = c("<0%", "0%-10%", "10%-20%", "20%-30%", ">30%") 
      ##title_vec = paste("Absolute Change in Access to Improved ", indicator, " , 1990-2011", sep="")
    ##} ##else if (type == "rate") {
      ##limit_vec = c(-100, 0, 1, 2, 2.77, 100)
      ##label_vec = c("<0", "0-1", "1-2", "2-2.77", ">2.77 (on track)")
      ##title_vec = paste("Annualized Rate of Decline in Lack of Access to Improved ", indicator, " , 1990-2011", sep="")
    ##}    
      
    ## make map
    colors <- brewer.pal(8, "BrBG")
    colors <- colors[c(1:3,5,6,7)]
    if (i == 1) {
#      tiff(paste("C:/Users/asthak/Documents/Covariates/Water and Sanitation/graphs/maps/", type, ".tif", sep=""), 
#           width=7, height=9, units="in", res=600)

      ##pdf(paste("J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/maps/", type,"_water.pdf", sep=""),
          ##width=7, height=9)
	  
	  pdf(paste("J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/output/maps/", type,"_hygiene.pdf", sep=""),
          width=7, height=9)
		  
      par(mfrow=c(2,1),lwd=0.075, bg="white", mai=c(.01,.1,.1,.1))
    }
    gbd_map(data = data,
            limits = limit_vec, 	# change to whatever bins make sense for your data
            label = label_vec, 		# label bins in the legend
            col = colors, 			# choose palette
            col.reverse = FALSE, 	#reverse palette if you want
            title = graph, 			# map title
    )
  }
  dev.off()
}
