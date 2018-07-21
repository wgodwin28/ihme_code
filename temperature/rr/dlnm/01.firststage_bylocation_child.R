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
# FIRST-STAGE ANALYSIS: RUN THE MODEL IN EACH CITY, REDUCE AND SAVE
################################################################################

################################################################################
# LOAD THE PACKAGES
rm(list=ls())
pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
library(dlnm) ; library(mvmeta) ; library(splines) ; library(tsModel) ; library(data.table) ; library(zoo)
j <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")
source("/homes/wgodwin/temperature/functions/heat_index_functions.R")

#Specify incoming args
print(commandArgs())
args <- commandArgs()
path <- as.character(args[4])
cause <- as.character(args[5])
diag.dir <- as.character(args[6])
location <- as.character(args[7])
country <- as.character(args[8])
state <- args[9]
ehi <- as.logical(args[10])
distr_lag <- as.logical(args[11])

ifelse(length(commandArgs()) > 7, debug <- F, debug <- T)
if(debug){
  path <- "/home/j/temp/wgodwin/temperature/cod/mex/causes/cvd_ihd_cod_temp.csv"
  cause <- "cvd_ihd"
  diag.dir <- "/home/j/temp/wgodwin/temperature/gasparrini_dlnm/diagnostics/mex/5"
  location <- "mex"
  country <- "Mexico"
  state <- 4643
  ehi <- T
  distr_lag <- F
}
print(paste(path, cause, diag.dir, location, state))

# SPECIFICATION OF THE EXPOSURE FUNCTION
varfun = "bs" #quadratic spline or natural cubic
vardegree = 2 #degree of polynomial (quadratic or cubic)
varper <- c(25,75,90) #percentiles to set knots. play around with this. move knot to 25

# SPECIFICATION OF THE LAG FUNCTION
lag <- 21
lagnk <- 3 #where knots are placed...i think

# DEGREE OF FREEDOM FOR SEASONALITY
dfseas <- 8

# COMPUTE PERCENTILES
#per <- t(sapply(cause.list,function(x) 
 # quantile(x$temp,c(2.5,10,25,50,75,90,97.5)/100,na.rm=T)))

# MODEL FORMULA
#formula <- death~cb+dow+ns(date,df=dfseas*length(unique(year)))
if(distr_lag){
  formula <- death ~ cb + lights + offset(log(population))
  family <- "quasipoisson"
}else {
  formula <- death ~ ns(tmean, knots = 3) * ns(mmt, knots = 3) + lights + offset(log(population))
  family <- "poisson"
}
print(formula)

############################################################################
# READ IN DATA AND CREATE THE OBJECTS TO STORE THE RESULTS
###########################################################################
# EXTRACT THE DATA
data <- fread(path)
data <- data[location_id == state]
data[, date := as.Date(date)]

#key_cols <- c("date", "adm2_id_res")
#setkeyv(data, key_cols)
#data[, mmt := lapply(.SD, rollmean, k = 30, na.pad = T), by = key_cols, .SDcols = "tmean"]

#Apply heat index transformations if desirable
if(ehi){
  #generating previous 30 day mean temperature
  data[, mmt := sapply(1:nrow(data), mean_lag_30)]
  #generating previous 3 day mean temp
  data[, tdm := sapply(1:nrow(data), mean_lag_3)]
  #difference between them
  data[, tmean := tdm - mmt]
}

# ARRANGE THE DATA AS A LIST OF DATA SETS
munis <- as.character(unique(data$adm2_id_res))
mlist <- lapply(munis,function(x) data[adm2_id_res==x,])
muni_names <- as.character(unique(data$adm2_name_res))
names(mlist) <- muni_names

#TEMPERATURE RANGES FOR META-ANALYSIS
ranges <- t(sapply(mlist, function(x) range(x$tmean,na.rm=T)))
bound <- colMeans(ranges)
bounds <- paste(as.character(round(bound, digits = 2)), collapse = "-")
avg <- data[, round(mean(tmean), digits = 2)]

# COEFFICIENTS AND VCOV FOR OVERALL CUMULATIVE SUMMARY
coef <- matrix(NA,length(munis),length(varper)+vardegree,
               dimnames=list(muni_names))
vcov <- vector("list",length(munis))
names(vcov) <- muni_names

################################################################################
# RUN THE LOOP
################################################################################
time <- proc.time()[3]

# LOOP
for(i in seq(length(mlist))) {

  # PRINT
  #print(paste0("reading ", path, " for ", state))
  data <- mlist[[i]]
  
  ##Subset to 2006-2015 for now since R cannot handle all years
  #if(location == "bra"){data <- data[year > 2005,]}

  # DEFINE THE CROSSBASIS
  if(distr_lag){
    argvar <- list(fun=varfun,knots=quantile(data$tmean,varper/100,na.rm=T),
      degree=vardegree)
    cb <- crossbasis(data$tmean,lag=lag,argvar=argvar,
      arglag=list(knots=logknots(lag,lagnk)))
  }
  #summary(cb)

  # RUN THE MODEL AND OBTAIN PREDICTIONS
  # NB: NO CENTERING NEEDED HERE, AS THIS DOES NOT AFFECT COEF-VCOV
  print(paste0("runnning model-", cause, " ", i))
  model <- glm(formula, data, family=family, na.action="na.exclude")

  # Save for later
  #save(pred, file = paste0(diag.dir, "/", cause, "_predictions.RData"))
  #load(paste0(diag.dir, "/", cause, "_predictions.RData"))
  
  # REDUCTION TO OVERALL CUMULATIVE
  if(distr_lag){
    pred <- crosspred(cb,model, cen = 20)
    red <- crossreduce(cb, model, cen = 20)
    coef[i,] <- coef(red)
    vcov[[i]] <- vcov(red)
  }
}
(proc.time()[3]-time)/60

#save the matrices
#####################################################################
#META-ANALYSIS
#####################################################################
locations <- fread(paste0(j, "temp/wgodwin/temperature/cod/locations.csv"))
st_name <- locations[location_id == state, location_name]

# OVERALL CUMULATIVE SUMMARY FOR THE MAIN MODEL
method <- "reml"
mvstate <- mvmeta(coef~1,vcov,method=method)
summary(mvstate)

# CREATE BASES FOR PREDICTION

# BASES OF TEMPERATURE AND LAG USED TO PREDICT, EQUAL TO THAT USED FOR ESTIMATION
# COMPUTED USING THE ATTRIBUTES OF THE CROSS-BASIS USED IN ESTIMATION
xvar <- seq(bound[1],bound[2],by=0.1)
bvar <- do.call("onebasis",c(list(x=xvar),attr(cb,"argvar")))
xlag <- 0:210/10
blag <- do.call("onebasis",c(list(x=xlag),attr(cb,"arglag")))

####################################################################
# REGION-SPECIFIC FIRST-STAGE SUMMARIES
cpmuni <- lapply(seq(nrow(coef)),function(i) crosspred(bvar,coef=coef[i,],
                                                       vcov=vcov[[i]],model.link="log",cen=17))

# OVERALL CUMULATIVE SUMMARY ASSOCIATION FOR MAIN MODEL
cpstate <- crosspred(bvar,coef=coef(mvstate),vcov=vcov(mvstate),
                   model.link="log",by=0.1,from=bound[1],to=bound[2],cen=20)


#####################################################################
#PLOTS
#####################################################################
#Cumulative, state-level plot
pdf(paste0(diag.dir,"/", st_name, "_effects.pdf"))
plot(cpstate,ylab="RR",col=2,lwd=2,ylim=c(.8,2),xlab="Temperature (C)")
#lines(cstate2,col=3,lty=2,lwd=2)
#lines(cstate3,col=4,lty=4,lwd=2)
mtext(paste0("Overall effect for ", cause, " in ", st_name, "\n",
             " Range:", bounds, ", Mean:", avg),cex=1)
legend ("top",c("B-spline of lag 0-21 (with 95%CI)"))
#                ,"Constant of lag 0-3",
#               "Constant of lag 0-21"),lty=c(1,2,4),lwd=1.5,col=2:4,bty="n",inset=0.05,
#       cex=0.8,title="Function for the lag space:")

#Individual muni effects plot
#par(mar=c(5,4,1,1)+0.1,cex.axis=0.9,mgp=c(2.5,1,0))
#layout(matrix(1:2,ncol=2))

plot(cpstate,type="n",ylab="RR",ylim=c(.8,2),xlab="Temperature (C)")
for(i in seq(cpmuni)) lines(cpmuni[[i]],ptype="overall",col=grey(0.5),lty=2)
abline(h=1)
lines(cpstate,col=2,lwd=2)
mtext(paste0("Main model: first-stage and pooled estimates-", st_name),cex=1)
legend ("top",c("Pooled (with 95%CI)","First-stage admin 2-specific"),
        lty=c(1,2),lwd=1.5,col=c(2,grey(0.7)),bty="n",inset=0.1,cex=0.8)

#Finish plotting
dev.off()

#
  ######SCRAP#######
  #Quick diagnostics
  # pdf(paste0(diag.dir, "/", cause, "_stage1.pdf"))
  # plot.crosspred(pred, "overall", ci = "lines", ylim = c(0, 3), xlab = "Temperature",
  #                ylab = "RR", main = paste0("Overall ", country,  " effect"))
  # #plot.crosspred(pred, "slices", type = "p", pch = 19, cex = 1.5, var = 0, 
  # #              ci = "bars", ylab = "RR", main = "Lag-specific effects at temp 0 degrees")
  # lags <- c(0,10,18,28)
  # for(lag in lags) {
  #   plot.crosspred(pred, "slices", type = "p", pch = 19, cex = 1.5, var = lag,
  #                  ci = "bars", ylab = "RR", main = paste("Lag-specific effects at temp", lag, "degrees (reference-22 C)"))
  # }
  # plot.crosspred(pred, xlab = "Temperature", theta = 240, phi = 40, ltheta = -185, 
  #                zlab = "RR", main = "3D graph")
  # #plot.crosspred(pred, "contour", plot.title = title(xlab = "Temperature", 
  # #               ylab = "Lag", main = "Contour graph"), key.title = title("RR"))
  # plot.crosspred(pred, "slices", var = 12, ci = "n", ylim = c(0.95, 1.22),
  #                lwd = 1.5, col = 2)
  # for(i in 1:2) lines(pred, "slices", var = c(20, 25)[i], col = i + 2,
  #                     lwd = 1.5)
  # legend("topright", paste("Temperature =", c(10, 20, 25)), col = 2:4, lwd = 1.5)
  # 
  # plot(pred, "slices", var = c(10, 18, 28), lag = c(0, 5, 20), #Play around with these lag and temp settings
  #      ci.level = 0.99, xlab = "Temperature",
  #      ci.arg = list(density = 20, col = grey(0.7)))
  # dev.off()
  # sink(paste0(diag.dir, "/", cause, "_stage1_summary.csv"), append = T)
  # print(summary(model))
  # sink()
  