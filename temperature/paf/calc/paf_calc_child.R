#PAF Calculation for temperature

#This script will bring in location_id args, then it will
#1. read in all exposure years, subsetting on the corresponding location_id each time
#2. Calculate 3 day mean, mmt, and ehi
#3. Merge on error terms by hemisphere and generate exposure draws
#4. Run PAF calculation

rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
  h = "H:/"
} else{
  j = "/home/j/"
  h = "/homes/wgodwin/"
}

########################################################################################
######################################SET UP############################################
########################################################################################
#load libraries
#pack_lib = '/snfs2/HOME/wgodwin/R'
pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
pacman::p_load(data.table, parallel, magrittr, feather, mvtnorm, zoo)
arg <- commandArgs()[-(1:3)]

#Set incoming arg objects
loc <- arg[1]
year <- as.numeric(arg[2])
in.dir <- arg[3]
sdi.dir <- arg[4]
pop.dir <- arg[5]
out.dir <- arg[6]
rr.model.version <- arg[7]
rr.functional.form <- arg[8]
out.version <- arg[9]
draws.required <- as.numeric(arg[10])
cores.provided <- as.numeric(arg[11])
  cores.provided <- ifelse(cores.provided>=40, 30, cores.provided)
  cores.provided <- ifelse(cores.provided<1, 1, cores.provided)
  message(cores.provided)
lag <- as.numeric(arg[12])
cause <- arg[13]
beta.dir <- arg[14]
config_path <- arg[15]
exp.se.dir <- arg[16]
suffix <- arg[17]
print(arg)

#Debugging
debug <- F
if(debug){
  loc <- 197
  year <- 2005
  in.dir <- paste0("/share/epi/risk/temp/temperature/exp/gridded/")
  sdi.dir <- paste0("/share/epi/risk/temp/temperature/exp/sdi/")
  pop.dir <- paste0(j, "WORK/05_risk/risks/temperature/data/exp/pop/paf/")
  rr.model.version <- 1
  rr.functional.form <- "cubspline.sdi.mmt3"
  out.version <- 20
  out.dir <- paste0("/share/epi/risk/temp/temperature/paf/", out.version) 
  draws.required <- 50
  cores.provided <- 6
  lag <- 30
  cause <- "sids"
  beta.dir <- paste0(j, "temp/Jeff/temperature/combinedAnalysis/")
  config_path <- "/home/j/WORK/05_risk/risks/temperature/data/rr/rr_analysis/rr_model_config.csv"
  exp.se.dir <- paste0("/share/epi/risk/temp/temperature/exp/standard_error/")
  suffix <- "_mmtDif_prPop_braMexNzl_knots25_season.csv"
}

#PAF functions#
paf.function.dir <- paste0(h, 'temperature/paf/lib/')  
paste0(paf.function.dir, "paf_helpers.R") %>% source

#RR functions#
rr.function.dir <- paste0(h, 'temperature/paf/lib/')  
paste0(rr.function.dir, "functional_forms.R") %>% source
fobject <- get(rr.functional.form)

#Function to collapse draws to summary values. And store the model config file
source("/share/code/coverage/functions/collapse_point.R")
config_path <- paste0(j, "WORK/05_risk/risks/temperature/data/rr/rr_analysis/rr_model_config.csv")

#Prep sdi to merge on-truncate SDI to be between 0.3 and 0.85 since those are the range values of our RR data
sdi.value <- ifelse(sdi.value < 0.3, 0.3, ifelse(sdi.value > 0.85, 0.85, sdi.value))

#Save cause_id as an object for save_results later
dt.cause <- fread(paste0(out.dir,"/causes.csv"))[acause == cause]
cause.id <- dt.cause[,cause_id]

#Prep knots specs
knots.dt <- read.csv(paste0(beta.dir, "knots/n_", cause, suffix), header = F)
knots.dt <- as.data.table(t(knots.dt))
names(knots.dt) <- c("mmt", "ehi")
knots.dt <- knots.dt[-1,]

########################################################################################
########################################################################################
###########Exposure Prep################################################################
########################################################################################
  #Read in exposures
  exp <- read_feather(paste0(in.dir,"loc_", loc, "_",  year, ".feather")) %>% as.data.table
  exp[, date := as.Date(date)]
  exp2 <- read_feather(paste0(in.dir,"loc_", loc, "_", paste(year - 1), ".feather")) %>% as.data.table
  exp2[, date := as.Date(date)]
  
  #Generate date cutoffs for the previous year
  first <- as.Date(paste0("01/", as.numeric(year)), format = "%j/%Y")
  cutoff <- as.Date(first - lag)
  exp2 <- exp2[date >= cutoff]
  exp <- rbind(exp, exp2)
  rm(exp2)
  exp <- exp[!is.na(tmean)]
  
  #Set date variable and sort from most recent day to oldest day (because that's the only way I could get rollmean to work for our needs)
  exp[, date := as.Date(date)]
  exp <- exp[order(-date)]
  
  #calculate moving 30 day average (day of and 29 days back) and moving 3 (day of and 2 days back) day average
  exp[, mmt := lapply(.SD, rollmeanr, k = 30, na.rm=T), by = c("lat", "long"), .SDcols="tmean"]
  exp[, tdm := lapply(.SD, rollmeanr, k = 3, na.rm=T), by = c("lat", "long"), .SDcols="tmean"]

  #difference between them
  exp[, ehi := tdm - mmt]
  
  #Drop unnecessary days now
  exp <- exp[date >= first]
  
  #Calculate mean annual temperature for each pixel
  exp[, temp_mean_ann := lapply(.SD, mean, na.rm = T), .SDcols = "tmean", by = c("long", "lat")]
  
  #mean monthly temperature TMREL, based on the gompertz curve relating mean annual temp to minimum mortatity temperature
  exp[, mmt_tmrel := 35.81728 * exp(-exp(-0.0630098 * (temp_mean_ann - 4.76978)))]
  exp[, mmt_dif := mmt - mmt_tmrel]
  
  #Truncate the mmt_dif by converting the extremes to log space
  exp[mmt_dif < -11.232, mmt_dif := -11.232] ##Taken from 1% of mmt-tmrel for all the country/years we have COD data for
  exp[mmt_dif > 1.995, mmt_dif := 1.995] ##Taken from 99% of mmt-tmrel for all the country/years we have COD data for
  
  #Indicate whether a pixel, day experienced cold effect or heat effect
  exp[mmt_dif > 0, heat_effect := 1]
  exp[mmt_dif < 0, heat_effect := 0]
  
  #Identify hemisphere of the location
  hemisph <- ifelse(exp[, mean(lat, na.rm = T)] > 20, "north", ifelse(exp[, mean(lat, na.rm = T)] < -20, "south", "tropics"))
   
  #Format to merge on standard error of the ERA interim estimates
  exp[, year_month := substr(date, 1, 7)]
  exp[, month_avg := substr(date, 6, 7)]
  exp[, month_avg := as.integer(month_avg)]
  
  #Merge on standard error of exposure
  #Pull in appropriate draws
  dt.se <- fread(paste0(exp.se.dir, hemisph, "_draws.csv"))
  if(exp[1, date] > as.Date("2011-12-31")){
      dt.se <- dt.se[average == 0]
      exp <- merge(exp, dt.se, by = "year_month", all.x = T)
   }else{
      dt.se <- dt.se[average == 1]
      exp <- merge(exp, dt.se, by = "month_avg", all.x = T)
   }
  
  #Add error term to mmt and ehi variables to generate appropriate distribution
    ##Mean monthly temperature
    mmt.colnames <- c(paste0("mmt_",1:draws.required))
    error.colnames <- c(paste0("error_", 1:draws.required))
    exp[, (mmt.colnames) := lapply(.SD, function(x){x + exp[, mmt_dif]}), .SDcols = error.colnames]
    
    ##Acclimatization index
    ehi.colnames <- c(paste0("ehi_",1:draws.required))
    exp[, (ehi.colnames) := lapply(.SD, function(x){x + exp[, ehi]}), .SDcols = error.colnames]
    
    #Keep necessary variables
    exp <- exp[, c("location_id", "date", "lat", "long", "tmean", "mmt", "ehi", "heat_effect", ehi.colnames, mmt.colnames), with = F]
    
  #Merge on population
  pop <- read_feather(paste0(pop.dir, "gridded_pop_", year, ".feather")) %>% as.data.table
  exp <- merge(exp, pop, by = c("lat", "long"), all.x = T)
  
  #Merge on pixel level sdi
  sdi.dt <- read_feather(paste0(sdi.dir, "gridded_sdi_", year, ".feather")) %>% as.data.table
  sdi.dt[, sdi := ifelse(sdi < 0.3, 0.3, ifelse(sdi > 0.85, 0.85, sdi))]
  exp <- merge(exp, sdi.dt, by = c("lat", "long"), all.x = T)
  
  #drop pixels of less than 20 people. If no pixels greater than 20, keep them all
  if(nrow(exp[pop>20]) > 0) exp <- exp[pop>20]
  if(unique(exp$location_id) == 23) exp <- exp[pop>200]
  message(paste0("total rows left: "), nrow(exp))
  
  #Prep RRs
  #rr.params <- prep.rr(cause = cause, path = beta.dir, version = rr.model.version)
  rr.params <- prep.rr(path = beta.dir, acause = cause, suff = suffix)
  
########################################################################################
###########Calculate PAFs###############################################################
########################################################################################
  #Calculate mortality PAFS using custom function
  message("beginning PAF calc...")
  #Break up dataset
  exp[, id := ceiling(rep(1:nrow(exp)/10000))]
  out.paf.mort <- data.table()
  out.rr.mort <- data.table()

  #Generate the RRs using the evaluation function
  for(chunk in unique(exp$id)){
    exp.temp <- exp[id == chunk]
    out.paf.rr.list <- calculatePAFs(exposure.object = exp.temp,
                                  rr.curves = rr.params,
                                  function.cores = cores.provided,
                                  ehi_ref = 0,
                                  mmt_ref = 0,
                                  config_path = config_path,
                                  rr_max = T,
                                  knots.dt = knots.dt)
    #exp[id == chunk, (new_cols) := whatever_function ]
    out.paf.mort <- rbind(out.paf.mort, out.paf.rr.list[[1]])
    out.rr.mort <- rbind(out.rr.mort, out.paf.rr.list[[2]])
  }
  
  #Population weight the PAFs
  out.paf.mort[, pop_weight := pop / sum(pop), by = "heat"]
  out.paf.mort <- out.paf.mort[, lapply(.SD, function(x){sum(x * pop_weight)}), by = "heat", .SDcols = paste0("V", 1:draws.required)]
  
  #Population weight the RRs and save for SEVs
  out.rr.mort[, pop_weight := pop / sum(pop), by = "heat"]
  out.rr.mort <- out.rr.mort[, lapply(.SD, function(x){sum(x * pop_weight)}), by = c("heat", "year_id", "location_id"), .SDcols = paste0("rr_", 1:draws.required)]
  dir.create(paste0(out.dir, "/rr_max/", cause), showWarnings = F, recursive = T)
  write.csv(out.rr.mort, paste0(out.dir, "/rr_max/", cause, "/rr_", loc, "_", year, "_", cause, ".csv"), row.names = F)

########################################################################################
###########Clean and Save###############################################################
########################################################################################
  # Call to a custom function to do some final formatting and generate a lite summary file with mean/CI
  mortality.outputs <- formatAndSummPAF(out.paf.mort, draws.required)

  #Save Mortality PAFs/RRs
    #summaries
    mort.summary <- mortality.outputs[["summary"]]
    mort.summary[, location_id := loc]
    mort.summary[, year_id := year]
    write.csv(mort.summary, 
              file.path(out.dir, "summary", 
                        paste0("paf_yll_", loc, "_", year, "_", cause, ".csv")), row.names = F)
    
    #full output
    mort.draws.all <- mortality.outputs[["draws"]]
    mort.draws.all[, location_id := loc]
    mort.draws.all[, year_id := year]
    #write.csv(mort.draws.all,  file.path(out.dir, "draws", 
                                     #paste0("paf_yll_", loc, "_", year, "_", cause, ".csv")), row.names = F)
  
  #Format for dalynator
  #Loop through heat and cold PAFS to save in separate directories
  for(t in c(1,0)){
    #Add necessary columns
    mort.draws <- mort.draws.all[heat == t]
    mort.draws[, acause := cause]
    mort.draws[, cause_id := cause.id]

    #for ages where there is a PAF
    ages <- c(seq(3,20),30,31,32,235)
    mort.draws[, age_group_id := 2]
    temp <- copy(mort.draws)
    
    #duplicate out for most detailed ages
    for (i in ages) {
      temp[, age_group_id := i]
      mort.draws <- rbind(mort.draws, temp)
    }
    
    #Duplicate out for most detailed sex and save
    for (sex.id in c(1,2)) {
      
      mort.draws[, sex_id := sex.id]
        
        write.csv(mort.draws, paste0(out.dir, "/save_results/", t, "/paf_yll_", loc, "_", year, "_", sex.id, "_", cause.id, ".csv"), row.names = F)
      }
    }
message("DONE")
