################################################################################
# SUPPLEMENTAL MATERIAL of the article:
#   "Mortality risk attributable to high and low ambient temperature:
#     a multi-country study"
#   Antonio Gasparrini and collaborators
#   The Lancet - 2015
#
# This code reproduces the analysis with the subset of data only including UK
#
# 17 March 2016
# * an updated version of this code, (hopefully) compatible with future
#   versions of the software, is available at the personal website of the
#   first author (www.ag-myresearch.com)
################################################################################

################################################################################
# PREPARE THE DATA
################################################################################

# LOAD THE PACKAGES
rm(list=ls())
library(dlnm) ; library(mvmeta) ; library(splines) ; library(tsModel) ; library(lubridate)
j <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")

# CHECK VERSION OF THE PACKAGE
if(packageVersion("dlnm")<"2.2.0")
  stop("update dlnm package to version >= 2.2.0")

# LOAD THE DATASET (INCLUDING THE 10 UK REGIONS ONLY)
#regEngWales <- read.csv("/home/j/temp/wgodwin/temperature/gasparrini_dlnm/regEngWales.csv",row.names=1)
#regEngWales$date <- as.Date(regEngWales$date)

#####################################################################
# Set toggle
startyear <- 2008
endyear <- 2016
prep_data <- F
country <- T
location <- "Mexico" #Mexico or Brazil
location_id <- 130 #130-MEX, 163-BRA

# Prep data
if(prep_data){
  data <- fread("/home/j/temp/Jeff/temperature/inputs/mex/mexCodPrepped.csv")
  data[, date := paste(month_id, day_id, year_id, sep = "/")]
  data[, date := mdy(date)]
  data <- data[order(date)]
  data <- data[!is.na(date),]
  data <- data[year_id > startyear,] ## drop all random deaths before 2008
  data[, deaths := 1]
  setkey(data, "date")
  data <- data[, .(deaths = sum(deaths)),
               by = .(adm2_name_res, adm2_id_res, date, location_name_res)] #will want to add in age, etc later
  
  #Read in temperature and prep for merge
  files <- list.files("/home/j/temp/wgodwin/temperature/exposure/prepped_data/mex", pattern = ".csv", full.names = T)
  temp.dt <- rbindlist(lapply(files, fread), fill = T)
  
  #Set date variable
  temp.dt[, date := paste(day, year_id, sep = "/")]
  temp.dt[, date := as.Date(date, format = "%j/%Y")]
  
  #format for merge with COD
  setnames(temp.dt, c("adm2_code", "temperature"), c("adm2_id_res", "temp"))
  temp.dt <- temp.dt[year_id > startyear & year_id < endyear,]
  data <- merge(data, temp.dt, by = c("date", "adm2_id_res"), all.y = T)
    
  #Clean and write to csv for future use
  data <- data[!is.na(temp)]
  data[is.na(deaths), deaths := 0]
  #data <- data[!is.na(adm2_name_res)]
  data[, time := as.numeric(date - date[1] + 1)]
  outpath <- paste0("/home/j/temp/wgodwin/temperature/cod/mex/all_cause_cod_temp.csv")
  write.csv(data, file = outpath, row.names = F)

  #If data has already been prepped, read in merged temperature and COD data
} else{
  data <- fread("/home/j/temp/wgodwin/temperature/cod/mex/all_cause_cod_temp.csv")
  data[, date := as.Date(date)]
  admin2 <- fread("/home/j/temp/wgodwin/temperature/cod/mex/admin2_map.csv")
  setnames(admin2, "adm2_id", "adm2_id_res")
  admin2[, adm2_id_res := as.numeric(adm2_id_res)]
  data <- merge(data, admin2, by="adm2_id_res", all.x = T)
  data[is.na(adm2_name_res), adm2_name_res := adm2_name]
  data[, adm2_name := NULL]
}

#Subset to first 10 municipalities for now
muni_ids <- data[, unique(adm2_id_res, na.rm = T)[1:10]]
munis <- data[, unique(adm2_name_res, na.rm = T)[1:10]]
data <- data[adm2_id_res %in% muni_ids,]
regEngWales <- copy(data)
setnames(regEngWales, c("adm2_name_res", "adm2_id_res", "temp", "year_id", "deaths"), 
                      c("regnames", "regids", "tmean", "year", "death"))
#####################################################################

# Toggle added in case just interested in full country analysis
if(country){
  regEngWales[, regnames := location]
  regEngWales[, regids := location_id]
}

# ARRANGE THE DATA AS A LIST OF DATA SETS
regions <- as.character(unique(regEngWales$regnames))
region_ids <- as.character(unique(regEngWales$regids))
dlist <- lapply(regions,function(x) regEngWales[regEngWales$regnames==x,])
names(dlist) <- regions

# METADATA FOR LOCATIONS
cities <- data.frame(
  city = region_ids,
  cityname = regions
  #cityname = c("North East","North West","Yorkshire & Humber","East Midlands", "West Midlands","East","London","South East","South West","Wales")
)

# ORDER
ord <- order(cities$cityname)
dlist <- dlist[ord]
cities <- cities[ord,]

# REMOVE ORIGINALS
rm(regEngWales,regions,ord)

################################################################################

# SPECIFICATION OF THE EXPOSURE FUNCTION
varfun = "bs" #beta spline or natural cubic
vardegree = 2 #degree of polynomial (cubic or quadratic)
varper <- c(10,75,90) #percentiles to set knots...i think

# SPECIFICATION OF THE LAG FUNCTION
lag <- 21
lagnk <- 3 #where knots are placed...i think

# DEGREE OF FREEDOM FOR SEASONALITY
dfseas <- 8

# COMPUTE PERCENTILES
per <- t(sapply(dlist,function(x) 
  quantile(x$tmean,c(2.5,10,25,50,75,90,97.5)/100,na.rm=T)))

# MODEL FORMULA
#formula <- death~cb+dow+ns(date,df=dfseas*length(unique(year)))
formula <- death~cb+ns(date,df=dfseas*length(unique(year)))

#
