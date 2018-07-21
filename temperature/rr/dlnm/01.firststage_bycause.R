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
#source("/snfs2/HOME/wgodwin/temperature/risk/dlnm/01.firststage_bycause.R", echo =T)
################################################################################
# LOAD THE PACKAGES
rm(list=ls())
pack_lib = '/home/j/temp/wgodwin/r_viz/packages'
.libPaths(pack_lib)
library(dlnm) ; library(mvmeta) ; library(splines) ; library(tsModel) ; library(data.table)
j <- ifelse(Sys.info()[1]=="Windows", "J:/", "/home/j/")

#Set toggles if prepped already
prepped <- T
if(prepped){
  location <- "mex"
  version <- 1 # first run
  version <- 2 # second run, changed knots from (10, 75, 90) to (25, 60, 90), also added dow to formula
  diag.dir <- paste0(j, "temp/wgodwin/temperature/gasparrini_dlnm/diagnostics/", location, "/", version, "/")
  dir.create(diag.dir)
  cause.meta <- fread(paste0(diag.dir, "cause.meta.csv"))
  causes <- cause.meta[, cause]
}
# SPECIFICATION OF THE EXPOSURE FUNCTION
varfun = "bs" #beta spline or natural cubic
vardegree = 2 #degree of polynomial (quadratic or cubic)
varper <- c(25, 60, 90) #percentiles to set knots. play around with this. move knot to 25

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
formula <- death~cb+dow+ns(date,df=dfseas*length(unique(year)))

# CREATE THE OBJECTS TO STORE THE RESULTS

# COEFFICIENTS AND VCOV FOR OVERALL CUMULATIVE SUMMARY
coef <- matrix(NA,nrow(cause.meta),length(varper)+vardegree,
               dimnames=list(cause.meta$cause))
vcov <- vector("list",nrow(cause.meta))
names(vcov) <- cause.meta$cause

################################################################################
# RUN THE LOOP

# LOOP
time <- proc.time()[3]
#for(i in seq(length(dlist))) {
for(i in causes){
  # PRINT
  print(paste0("reading ", i))
  path <- cause.meta[cause == i, path]

  # EXTRACT THE DATA
  data <- fread(path)
  data[, date := as.Date(date)]

  # DEFINE THE CROSSBASIS
  argvar <- list(fun=varfun,knots=quantile(data$tmean,varper/100,na.rm=T),
    degree=vardegree)
  cb <- crossbasis(data$tmean,lag=lag,argvar=argvar,
    arglag=list(knots=logknots(lag,lagnk)))
  #summary(cb)

  # RUN THE MODEL AND OBTAIN PREDICTIONS
  # NB: NO CENTERING NEEDED HERE, AS THIS DOES NOT AFFECT COEF-VCOV
  print(paste0("runnning model-", i))
  model <- glm(formula, data, family=quasipoisson,na.action="na.exclude")
  pred <- crosspred(cb,model, cen = 18)

  # Save for later
  save(pred, file = paste0(diag.dir, "/", i, "_predictions.RData"))
  #load(paste0(diag.dir, "/", cause, "_predictions.RData"))
  
  #Quick diagnostics
  pdf(paste0(diag.dir, "/", i, "_stage1.pdf"))
  plot.crosspred(pred, "overall", ci = "lines", ylim = c(0, 6), xlab = "Temperature",
                 ylab = "RR", main = paste0("Overall ", location,  " effect"))
  #plot.crosspred(pred, "slices", type = "p", pch = 19, cex = 1.5, var = 0, 
   #              ci = "bars", ylab = "RR", main = "Lag-specific effects at temp 0 degrees")
  plot.crosspred(pred, "slices", type = "p", pch = 19, cex = 1.5, var = 10,
                 ci = "bars", ylab = "RR", main = "Lag-specific effects at temp 10 degrees")
  plot.crosspred(pred, "slices", type = "p", pch = 19, cex = 1.5, var = 22,
                 ci = "bars", ylab = "RR", main = "Lag-specific effects at temp 22 degrees")
  plot.crosspred(pred, "slices", type = "p", pch = 19, cex = 1.5, var = 28,
                 ci = "bars", ylab = "RR", main = "Lag-specific effects at temp 28 degrees")
  plot.crosspred(pred, xlab = "Temperature", theta = 240, phi = 40, ltheta = -185, 
                 zlab = "RR", main = "3D graph")
  #plot.crosspred(pred, "contour", plot.title = title(xlab = "Temperature", 
   #               ylab = "Lag", main = "Contour graph"), key.title = title("RR"))
  plot.crosspred(pred, "slices", var = 12, ci = "n", ylim = c(0.95, 1.22),
                  lwd = 1.5, col = 2)
  for(i in 1:2) lines(pred, "slices", var = c(20, 25)[i], col = i + 2,
                      lwd = 1.5)
  legend("topright", paste("Temperature =", c(10, 20, 25)), col = 2:4, lwd = 1.5)
  
  plot(pred, "slices", var = c(10, 18, 28), lag = c(0, 5, 20), #Play around with these lag and temp settings
        ci.level = 0.99, xlab = "Temperature",
        ci.arg = list(density = 20, col = grey(0.7)))
  dev.off()
  sink(paste0(diag.dir, i, "_stage1_summary.csv"), append = T)
  print(summary(model))
  sink()

  # REDUCTION TO OVERALL CUMULATIVE
  #red <- crossreduce(cb,model)
  #coef[i,] <- coef(red)
  #vcov[[i]] <- vcov(red)
  
}
(proc.time()[3]-time)/60

#
