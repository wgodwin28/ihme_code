##Filename: pm2.5_lmer.r
##PURPOSE: RUN MIXED EFFECT MODEL IN R
##DATE: APRIL 10 2015
##AUTHOR: ASTHA KC
## Edited by Yi Zhao on 4May2016 to reflect change of filepaths and variable names 
## Edited by Joey Frostad on 5Aug2016 to remove the country random effect at request of Mehrdad

#Housekeeping
rm(list = ls())

# disable scientific notation
options(scipen = 999)

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  
  j_root <- "/home/j" 
  h_root <- "/homes/jfrostad"
  
} else { 
  
  j_root <- "J:"
  h_root <- "H:"
  
}

# set working directories
home.dir <- file.path(j_root, "WORK/05_risk/risks/")
setwd(home.dir)

#load packages
pacman::p_load(data.table, Hmisc, lme4, magrittr, MASS, stringr)

#set seed for draws
set.seed=32523523

#IER curve settings
rr.data.version <- 7
rr.model.version <- "power2_simsd_source"
rr.functional.form <- "power2"
rr.dir <- file.path(home.dir, '/air_pm/data/rr/output/', paste0(rr.data.version, rr.model.version))

#output max RRs for sev
output.version <- 2 #second SEV created in this new folder. the SEV for GBD2015 resubmission
out.dir <- file.path(home.dir, "air_hap/products/sev", output.version)
  dir.create(out.dir, recursive = T)
#----FUNCTIONS----------------------------------------------------------------------------------------------------------  
##function lib##
#PAF functions#
paf.function.dir <- file.path(h_root, '_code/risks/air_pm/paf/_lib')  
file.path(paf.function.dir, "paf_helpers.R") %>% source

#RR functions#
rr.function.dir <- file.path(h_root, '_code/risks/air_pm/rr/_lib') 
file.path(rr.function.dir, "functional_forms.R") %>% source
fobject <- get(rr.functional.form)  

#AiR PM functions#
air.function.dir <- file.path(h_root, '_code/risks/air_pm/_lib')
# this pulls the miscellaneous helper functions for air pollution
file.path(air.function.dir, "misc.R") %>% source()

#general functions#
central.function.dir <- file.path(h_root, "_code/_lib/functions/")
# this pulls the general misc helper functions
file.path(central.function.dir, "misc.R") %>% source
# this pulls the current locations list
file.path(central.function.dir, "get_locations.R") %>% source
# other tools created by covs team for querying db
file.path(central.function.dir, "db_tools.R") %>% source

#get pop and collapse to country year
pop <- get_populations(35, 1970, 2015) %>% as.data.table
setkeyv(pop, c("year_id", "location_id"))
pop[, tot_pop := sum(pop_scaled), by=c("year_id", "location_id")]
all.pop <- pop[, c("year_id", "location_id", "tot_pop"), with=F] %>% unique

#read in the exposure covariate for SEV
hap <- get_covariates("pollution_indoor_total_prev")

#READ IN the DATASET
input.date <- "5Aug2016"
data <- file.path("J:/WORK/05_risk/risks/air_hap/02_rr/02_output/PM2.5 mapping/lit_db/", paste0("lmer_input_", input.date, ".csv")) %>% fread

#new regression after chris email 5aug2016
lm.re <- lmer(logpm ~ cooking + as.factor(region_id) + (1|location_id), data = data)
summary(lm.re)

#new regression after steve email 8aug2016
lm.re <- lmer(logpm ~ cooking + (1|super_region_id/region_id), data = data)
summary(lm.re)

#new regression after steve email 8aug2016
lm.re <- lmer(logpm ~ cooking + (1|super_region_id), data = data)
summary(lm.re)

#create matrix of 1000 draws of fixed effects using variance/covariance matrix:
fixed.fx <- mvrnorm(1000, mu=fixef(lm.re), Sigma=vcov(lm.re)) %>% as.data.table
intercept <- fixed.fx[, "(Intercept)", with=F] %>% unlist #store the intercept draws as a vector

#Extract RE by analytical superregion
superregion_re <- ranef(lm.re, condVar=T)[[1]]
superregion_var <- as.vector(attr(superregion_re, "postVar"))
superregion_sims <- cbind(data.frame(super_region_id = rownames(superregion_re)), matrix(NA, nr=length(rownames(superregion_re)), nc = 1000))

# as.data.frame(matrix(NA, nr=nrow(data), nc=1000))
for (s in 1:length(rownames(superregion_re))) {
  superregion_sims[s, 2:1001] <- rnorm(1000, as.vector(unlist(superregion_re))[s], sqrt(superregion_var[s]))
}

superregion_sims <- superregion_sims %>% as.data.table
setnames(superregion_sims, paste0(1:1000), paste0("super_region_rfx_", 1:1000))
superregion_sims[, super_region_id := as.character(super_region_id) %>% as.numeric]

#create vectors of draws
super.region.colnames <- paste0("super_region_rfx_", 1:1000)
pred.colnames <- paste0("draw_", 1:1000)

#merge the region.fx onto the data for prediction
predict.data <- merge(data, superregion_sims, by="super_region_id", all.x=TRUE)
predict.data[is.na(super_region_rfx_1), (super.region.colnames) := 0] #fill in the region_fx as 0 if missing (not present in regression)

#manually predict 1000 draws for each country year
#note we are only using the region fixed effect and the constant to predict
predict.data[, (pred.colnames) := lapply(1:1000, function(draw) (intercept[[draw]] + super.region.colnames[draw] %>% get) %>% exp)]

#cleanup and deduplicate
#note that year is not necessary as there are no temporal covariates and hence no variation
setkeyv(predict.data, c('ihme_loc_id'))
predict.data <- predict.data[, c("region_id", "location_id", "super_region_id", "ihme_loc_id", "year_id", pred.colnames), with=F] %>% unique

fwrite(predict.data, paste0("J:/WORK/05_risk/risks/air_hap/02_rr/02_output/PM2.5 mapping/lit_db/lmer_pred_", input.date, ".csv"))

#generate SEV
sev.exp <- merge(predict.data, all.pop, by=c("year_id", "location_id"), all.x=T)
sev.exp <- merge(sev.exp, hap, by=c("year_id", "location_id"), all.x=T)

#generate draws of the weighted p99 of exp(weighted by total population)
sev.exp[, (pred.colnames) := lapply(1:1000, function(draw) wtd.quantile(pred.colnames[draw] %>% get, weights=(tot_pop*pollution_indoor_total_prev), probs=c(.99)))]

#keep 1 row of sev.exp, as all the rows are the same now
sev.exp <- sev.exp[1]

#now run IER to calculate the max RRs for SEV

# Make a list of all cause-age pairs that we have.
age.cause <- ageCauseLister(full.age.range = T) 
# Prep the RR curves into a single object, so that we can loop through different years without hitting the files extra times.
all.rr <- lapply(1:nrow(age.cause), prepRR, rr.dir=rr.dir)

#currently only calculating the max RR using the mortality ratio
ratio <- 1

#create a vector of column names to store RR estimates
rr.colnames <- paste0("rr_", 1:1000)

ageWrapper <- function(age.cause.number) {
  
  cause.code <- age.cause[age.cause.number, 1]
  age.start <- age.cause[age.cause.number, 2]
  
  message("Cause:", cause.code, " - Age:", age.start)
  
  # Prep out datasets
  sev <- as.data.table(matrix(as.integer(NA), nrow=1, ncol=3)) 
  
  # Set up variables
  sev[, 1 := cause.code]
  sev[, 2 := as.numeric(age.start)] 

  #calculate the RR for each grid using the IER curve for this a/c
  sev.exp[,(rr.colnames) := lapply(1:1000, 
                               function(draw.number) ratio * fobject$eval(pred.colnames[draw.number] %>% get,
                                                                          all.rr[[age.cause.number]][draw.number, ]) - ratio + 1)]
  sev.exp[,rr := rowMeans(.SD), .SDcols=rr.colnames]
      
  sev[, 3 := sev.exp$rr %>% as.numeric]

  
  setnames(sev, c("cause", "age","rr_p99"))
  
  return(sev)
  
}

output <- mclapply(1:nrow(age.cause), ageWrapper, mc.cores=1) %>% rbindlist

write.csv(output, file.path(out.dir, "sev_max_rr.csv"))

#######################################################################
##SCRAP##

#   ci <- confint(lm.re)  
#   
#   # Extract draws of coefficients for cooking fixed effect (study cov) and intercept
#   cooking_sims <- matrix(rnorm(1000, fixef(lm.re)[2], (ci[4,2]-ci[4,1])/3.92), nr=1, nc=1000, byrow=F)
#   constant_sims <- matrix(rnorm(1000, fixef(lm.re)[1], (ci[3,2]-ci[3,1])/3.92), nr=1, nc=1000, byrow=F)
#   
#   write.csv(cooking_sims,"J:/WORK/05_risk/risks/air_hap/02_rr/02_output/PM2.5 mapping/lit_db/cooking_sims.csv")
#   write.csv(constant_sims, "J:/WORK/05_risk/risks/air_hap/02_rr/02_output/PM2.5 mapping/lit_db/const_sims.csv")
#   
#   #Extract fixed effect by analytical region
#   region_effect <- matrix(rnorm(1000, fixef(lm.re)[3:9], (ci[5:11,2]-ci[5:11,1])/3.92), nr=7, nc=1000, byrow=F)
#   region_names <- data[!is.na(logpm), region_id] %>% unique %>% sort
#   #note i cut out the first region name, as this one is the reference group (no FE)
#   region_sims <- data.table(region_id = region_names[-1], region_effect)
#   
#   setnames(region_sims, paste0("V",1:1000), paste0("region_fe", 0:999))
#   
#   write.csv(region_sims, "J:/WORK/05_risk/risks/air_hap/02_rr/02_output/PM2.5 mapping/lit_db/region_fe_sims.csv")

# #trying another regression
# lm.re <- lmer(logpm ~ measure_std + cooking + (1|region_id), data = data[!(orig_mean<30 | orig_mean >10000)], weights= 1/(orig_se/ orig_mean)^2)
# 
# #logpm - _b[measure_std]*measure_std - _b[personal_exp]*personal_exp - _b[cooking]*cooking
# data[, xlogpm := logpm - coef(lm.re)[3]*measure_std - coef(lm.re)[2]*personal_exp - coef(lm.re)[4]*cooking]
# 
# 
# data[, xlogpm := logpm - fixef(lm.re)[2]*measure_std - fixef(lm.re)[3]*cooking]


# #Read in selected covariates and merge
# id.vars <- c("location_id", "year_id")
# 
# ldi <- get_cov_estimates("ldi_pc") %>% as.data.table
# setnames(ldi, "mean_value", "ldi")
# ldi <- ldi[, c(id.vars, "ldi"), with=F]
# edu <- get_cov_estimates("educ_yrs_age_std_pc") %>% as.data.table
# setnames(edu, "mean_value", "edu")
# edu <- edu[, c(id.vars, "edu"), with=F]
# temp <- get_cov_estimates("mean_temperature") %>% as.data.table
# setnames(temp, "mean_value", "temp")
# temp <- temp[, c(id.vars, "temp"), with=F]
# temp[temp <= 0, temp := 0.0001 ] #prep for logspace
# 
# #merge
# reg.data <- merge(data, ldi, by = id.vars)
# reg.data <- merge(reg.data, temp, by = id.vars)
# reg.data <- merge(reg.data, edu, by = id.vars)


# #store the region draws and then parse them for merge
# region.fx <- fixed.fx[, -c("(Intercept)", "cooking"), with=F] %>% melt(variable.factor = F)
# #parse region id
# region.fx[, region_id := as.data.table(str_split_fixed(variable, fixed("as.factor(region_id)"), 2)[,2])]
# region.fx[, region_id := as.numeric(region_id)]
# 
# #create draw# varnames 
# region.fx[, index := seq_len(.N), by = list(region_id)]
# region.fx[, draw := paste0("region_fx_", index %>% as.character)]

# #cleanup
# region.fx[, c("variable", "index") := NULL, with=F]
# #cast draws wide
# region.fx <- dcast(region.fx, region_id~draw)
