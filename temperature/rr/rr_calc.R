#Purpose: Generate relative risk functions by cause and age for temperature. Then save betas for PAF calculation
#source('/snfs2/HOME/wgodwin/temperature/risk/rr_calc.R', echo = T)
rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}
options(scipen=999)

#load libraries
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
pacman::p_load(data.table, parallel, magrittr, raster, stringr, RMySQL, snow, ncdf4, feather, rgdal, pglm, haven, plm, ggplot2)
arg <- commandArgs()[-(1:3)]

#Set incoming arg objects
cause <- arg[1]
rr.model <- arg[2]
out.dir <- arg[3]
version <- arg[4]
# age <- as.numeric(arg[2])
# age_bound <- data.table(x = c(1,2,3), lower = c(0,15,45), upper = c(14.999, 44.999, 120))
# age_lower <- age_bound[x == age, lower]
# age_upper <- age_bound[x == age, upper]

#Debugging args
cause <- "cvd_ihd"
rr.model <- "cubspline.sdi"
out.dir <- "/home/j/WORK/05_risk/risks/temperature/data/rr/rr_analysis/"
age <- "all"
version <- 3

#Set code directory and source helpful functions
code.dir <- "/snfs2/HOME/wgodwin/temperature/"
source(paste0(code.dir, "paf/lib/paf_helpers.R"))
source(paste0(code.dir, "paf/lib/functional_forms.R"))
fobject <- get(rr.model)
draws <- 1000
function.cores <- 6

##########################################################
#################PREP#####################################
##########################################################
#Read in prepped death/hospital data and age-specific populations
#dt <- read_dta(paste0(j, "temp/Jeff/temperature/mexAnalysis/analysisMerged_level3.dta")) %>% as.data.table
dt.nzl <- fread("/home/j/temp/Jeff/temperature/inputs/nza/analysisMerged_cvd_ihd.csv")
dt.nzl <- dt.nzl[!is.na(date)]
dt.nzl <- dt.nzl[!is.na(mmt)]
dt.nzl <- dt.nzl[!is.na(deaths)]
dt.nzl <- dt.nzl[, c("ehi_accl", "mmt", "year_id", "adm2_id_res", "location_id_res", "deaths", "date", "sdi", "population"), with = F]
dt.nzl[, date := as.Date(date, "%d%b%Y")]
#pop <- fread("/home/j/WORK/05_risk/risks/temperature/data/exp/pop/mex/age_broad/pop_full.csv")

#mexico data
dt <- fread("/share/epi/risk/temp/temperature/rr/cod/mex/level3_cvdihd_clean.csv")
# setnames(dt, c(paste0("sex_id", cause), paste0("age", cause), paste0("n_", cause)), c("sex_id", "age", "deaths"))
# 
# #Clean and subset the data to variables of interest
# dt <- dt[!is.na(date)]
# dt <- dt[!is.na(mmt)]
# keep_vars <- c("ehi_accl", "mmt", "year_id", "adm2_id_res", "location_id_res", "deaths", "date", "sdi", "population", "sex_id", "age")
# dt <- dt[,keep_vars, with = F]
# dt <- dt[!is.na(deaths)]
dt[, date := as.Date(date, "%d%b%Y")]
mem <- object.size(dt)/10e9
print(mem)
dt <- rbind(dt, dt.nzl, fill = T)

#Subset to the age of interest by converting all deaths outside age group of interest to 0
#dt <- dt[age_enteric_all >= 15, n__enteric_all := 0]

#Generate spline variables to serve as predictors in negative binomial regression
  #Mean monthly temperature
  mmt.knots <- c(10,15,20,25,30)
  mmt_spline_vars <- est.spline.var(knot.vec = mmt.knots, var.vec = dt$mmt) %>% as.data.table
  setnames(mmt_spline_vars, c("var1", "V2", "V3", "V4"), c("mmt_S1", "mmt_S2", "mmt_S3", "mmt_S4"))
  
  #Deviations from mmt
  dev.knots <- c(-5,0,5)
  dev_spline_vars <- est.spline.var(knot.vec = dev.knots, var.vec = dt$ehi_accl) %>% as.data.table
  setnames(dev_spline_vars, c("var1", "V2"), c("dev_S1", "dev_S2"))
  dt <- cbind(dt, mmt_spline_vars, dev_spline_vars)
  
#Set formula objects
#predictors <- c(paste0("dev_S", 1:2), paste0("mmt_S", 1:4), "sdi")
p1 <- paste0("mmt_S", 1:4, "*", "dev_S", 2:1, "*", "sdi", collapse = ")+(")
p2 <- paste0("mmt_S", 1:4, "*", "dev_S", 1:2, "*", "sdi", collapse = ")+(")
predictors <- paste0("(", p1, ")+(", p2, ")")
formu <- as.formula(paste0("death_rate ~ ", predictors))
dt2[, death_rate := deaths/population]

#p1 <- paste0("mmt_S", 1:1, "*", "dev_S", 1:1, "*", "sdi", collapse = ")+(")
#formu <- as.formula(paste0("n_", paste0(cause)," ~ ", p1," + offset(population)"))

###########################################################
####################MODEL##################################
###########################################################
  #Run specified model-negative binomial panel regression
  start_time <- Sys.time()
  mod.rate <- pglm(formu, data = dt2, family = negbin, model = "within", index = c("adm2_id_res", "date"))
  end_time <- Sys.time()
  time <- end_time - start_time
  print(time)

###########################################################
################MODEL OUTPUTS##############################
###########################################################
#Extract the SDI coefficients and convert to draws
# coefficient matrix
betas <- mod$estimate
var.covar <- vcov(mod)
beta.draws <- rmvnorm(n = 1000, mean = betas, sigma = var.covar) %>% as.data.table

#Clean and save them to be accessed by PAF calculator
write.csv(beta.draws, paste0(out.dir, "betas_mex_2009_2015_", cause, "_", version, ".csv"), row.names = F)

#Create template for predictions with every unique combo
mmt_seq <- seq(0,40,5)
dev_seq <- seq(-10,10)
template <- expand.grid(mmt = mmt_seq, ehi_accl = dev_seq, sdi = c(0.4,0.6,0.9)) %>% as.data.table

  #Generate template spline variables
  #Mean monthly temperature
  mmt.knots <- c(10,15,20,25,30)
  mmt_spline_vars <- est.spline.var(knot.vec = mmt.knots, var.vec = template$mmt) %>% as.data.table
  setnames(mmt_spline_vars, c("var1", "V2", "V3", "V4"), c("mmt_S1", "mmt_S2", "mmt_S3", "mmt_S4"))
  
  #Deviations from mmt
  dev.knots <- c(-5,0,5)
  dev_spline_vars <- est.spline.var(knot.vec = dev.knots, var.vec = template$ehi_accl) %>% as.data.table
  setnames(dev_spline_vars, c("var1", "V2"), c("dev_S1", "dev_S2"))
  template <- cbind(template, mmt_spline_vars, dev_spline_vars)

#Predict out for each unique mmt, deviation combination
draw.colnames <- c(paste0("pred_", 1:draws))
template[, c(draw.colnames) := mclapply(1:draws,
                                       mc.cores = function.cores,
                                       function(draw.number) {
                                         mort.pred <- fobject$eval(
                                            template[, mmt_S1],
                                            template[, mmt_S2],
                                            template[, mmt_S3],
                                            template[, mmt_S4],
                                            template[, dev_S1],
                                            template[, dev_S2],
                                            template[, sdi],
                                            beta.draws[draw.number])
                                         rr.pred <- exp(mort.pred - mean(mort.pred, na.rm = T))
                                        return(rr.pred)
                                     })]
#rr.pred <- exp(mort.pred - mean(mort.pred, na.rm = T))

ref.colnames <- c(paste0("ref_", 1:1000))
template[, c(ref.colnames) := lapply(.SD, mean), .SDcols = c(draw.colnames), by = "sdi"]
template[, c(draw.colnames) := lapply(1:1000, function(x){exp(get(paste0("pred_", x)) - get(paste0("ref_", x)))})]
#Generate reference mortality draws
# ref.colnames <- c(paste0("ref_", 1:1000))
# dt.ref <- copy(dt)
# dt.ref[, mmt_adm2 := lapply(.SD, mean, na.rm = T), .SDcols = "mmt", by = "adm2_id_res"]
# dt.ref[, ehi_adm2 := lapply(.SD, mean, na.rm = T), .SDcols = "ehi_accl", by = "adm2_id_res"]
# dt.ref[, sdi_adm2 := lapply(.SD, mean, na.rm = T), .SDcols = "sdi", by = "adm2_id_res"]
# dt.ref <- dt.ref[, lapply(.SD, mean, na.rm = T), .SDcols = c("sdi_adm2","ehi_adm2", "mmt_adm2"), by = c("adm2_id_res", "country","ehi_int", "mmt_int", "sdi_cat")]

#Calculate mean, SD of the draws and drop draws
template[, pred_mean := rowMeans(.SD), .SDcols = draw.colnames]
template[, pred_sd := apply(.SD, 1, sd), .SDcols = draw.colnames]
template[, pred_lower := apply(.SD, 1, quantile, .025), .SDcols = draw.colnames]
template[, pred_upper := apply(.SD, 1, quantile, .975), .SDcols = draw.colnames]
template <- template[, .(ehi_accl, mmt, pred_mean, pred_sd, sdi, pred_lower, pred_upper)]

#Format to merge on with RRs from data
template[, sdi_cat := cut(sdi, seq(0.35,0.95,0.2), labels = c("low", "med", "hi"))]
setnames(template, c("ehi_accl", "mmt"), c("ehi_int", "mmt_int"))
template[, mmt_int := as.factor(mmt_int)]

##########################################################
########################MORTALITY#########################
##########################################################
#Round the mmt and ehi variables to integer values
dt[, mmt_int := cut(round(mmt), seq(-2.5, 42.5, 5), labels=seq(0,40,5))]
dt[, ehi_int := round(ehi_accl)]
dt[, sdi_cat := cut(sdi, seq(0.3,0.9,0.2), labels = c("low", "med", "hi"))]

#calulate population and death counts by admin 2 location (since that's what model random effect does)
dt[, pop_adm2 := lapply(.SD, sum, na.rm = T), .SDcols = "population", by = "adm2_id_res"]
dt[, death_adm2 := lapply(.SD, sum, na.rm = T), .SDcols = "deaths", by = "adm2_id_res"]

#generate counts of where population and deaths aren't missing
dt[!is.na(pop_adm2), count_totalPop := 1]
dt[!is.na(death_adm2), count_totalCause := 1]
dt[!is.na(year_id), count := 1]

##Add on country variables
dt[adm2_id_res > 25, country := "MEX"]
dt[adm2_id_res < 25, country := "NZL"]

#collapse deaths, populations by adm2, ehi, mmt, and sdi category
dt <- dt[, lapply(.SD, sum, na.rm = T), .SDcols = c("death_adm2", "pop_adm2", "count_totalPop", "count_totalCause", "count", "population", "deaths"),
          by = c("adm2_id_res", "ehi_int", "mmt_int", "sdi_cat", "country")]
            #, "sdi_cat"
dt[, death_adm2 := death_adm2/count_totalCause]
dt[, pop_adm2 := pop_adm2/count_totalPop]
dt[, rr_mean := (deaths/population)/(death_adm2/pop_adm2)]
dt[!is.na(rr_mean), seCount := 1]
#dt[rr_mean > 1000, rr_mean := NA]

#collapse by temperature bins and sdi bins
dt2 <- dt[, lapply(.SD, mean, na.rm = T), .SDcols = "rr_mean", by = c("ehi_int", "mmt_int", "sdi_cat")]
dt3 <- dt[, lapply(.SD, sd, na.rm = T), .SDcols = "rr_mean", by = c("ehi_int", "mmt_int", "sdi_cat")]
setnames(dt3, "rr_mean", "rr_sd")
dt4 <- dt[, lapply(.SD, sum, na.rm = T), .SDcols = "seCount", by = c("ehi_int", "mmt_int", "sdi_cat")]
dt2 <- merge(dt2, dt3, by = c("ehi_int", "mmt_int", "sdi_cat"))
dt2 <- merge(dt2, dt4, by = c("ehi_int", "mmt_int", "sdi_cat"))

#Get standard error
dt2[, rr_se := rr_sd/sqrt(seCount)]
dt2[rr_mean == 0, rr_mean := NA]

##merge predictions with RRs from the data
dt.plot <- merge(template, dt2, by = c("ehi_int", "mmt_int", "sdi_cat"), all.x = T)

###################################################################
###############################ggplot##############################
###################################################################
#plot mortality by mmt, across different levels of ehi
t <- template[ehi_accl == 0,]
g <- ggplot(data = t, aes(x = mmt, y = pred_mean, color=as.factor(sdi))) +
  geom_line(aes(y=pred_mean))+
  labs(x="Mean Monthly Temperature",
       y="Log Mortality") +
  geom_ribbon(aes(ymin=pred_lower, ymax=pred_upper, linetype=NA), fill="lightgreen", alpha=0.2)
print(g)

#plot mortality by ehi, across different levels of mmt
t <- dt.plot[mmt_int == 20,]
g <- ggplot(data = dt.plot[rr_mean < 40], aes(x = ehi_int, y = pred_mean, color=as.factor(sdi))) +
  #geom_line(aes(y=pred_mean))+
  labs(x="Deviation from Mean Monthly Temperature",
       y="Relative Risk",
       title = "Using Mean Mort by SDI to Predict") +
  geom_point(aes(y = rr_mean, size = (1/rr_sd))) +
  #geom_ribbon(aes(ymin=pred_lower, ymax=pred_upper, linetype=NA), fill="lightgreen", alpha=0.2)+
  theme_bw()+
  facet_wrap(~mmt_int)
print(g)

##########################################################
########################SAVE##############################
##########################################################

#Write input file to 2D GPR
write.csv(out.dt, paste0(out.dir, "2D_GPR_input_", cause, "_", version, ".csv"), row.names = F)
