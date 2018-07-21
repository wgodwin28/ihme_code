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
# CREATE THE OBJECTS TO STORE THE RESULTS

# COEFFICIENTS AND VCOV FOR OVERALL CUMULATIVE SUMMARY
coef <- matrix(NA,nrow(cities),length(varper)+vardegree,
  dimnames=list(cities$city))
vcov <- vector("list",nrow(cities))
names(vcov) <- cities$city


################################################################################
# RUN THE LOOP

# LOOP
time <- proc.time()[3]
for(i in seq(length(dlist))) {

  # PRINT
  cat(i,"")
  
  # EXTRACT THE DATA
  data <- dlist[[i]]

  # DEFINE THE CROSSBASIS
  argvar <- list(fun=varfun,knots=quantile(data$tmean,varper/100,na.rm=T),
    degree=vardegree)
  cb <- crossbasis(data$tmean,lag=lag,argvar=argvar,
    arglag=list(knots=logknots(lag,lagnk)))
  #summary(cb)
  
  # RUN THE MODEL AND OBTAIN PREDICTIONS
  # NB: NO CENTERING NEEDED HERE, AS THIS DOES NOT AFFECT COEF-VCOV
  model <- glm(formula,data,family=quasipoisson,na.action="na.exclude")
  pred <- crosspred(cb,model, cen = 22)
  
  #Quick diagnostics
  pdf("/home/j/temp/wgodwin/temperature/gasparrini_dlnm/figure1_agua_stage1.pdf")
  plot.crosspred(pred, "overall", ci = "lines", ylim = c(0.5, 6.9), xlab = "Temperature",
                 ylab = "RR", main = "Overall MEX effect")
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
  plot.crosspred(pred, "slices", var = 10, ci = "n", ylim = c(0.95, 1.22),
                  lwd = 1.5, col = 2)
  for(i in 1:2) lines(pred, "slices", var = c(20, 25)[i], col = i + 2,
                      lwd = 1.5)
  legend("topright", paste("Temperature =", c(10, 20, 25)), col = 2:4, lwd = 1.5)
  
  plot(pred, "slices", var = c(10, 15, 25), lag = c(0, 5, 20), #Play around with these lag and temp settings
        ci.level = 0.99, xlab = "Temperature",
        ci.arg = list(density = 20, col = grey(0.7)))
  
  # REDUCTION TO OVERALL CUMULATIVE
  red <- crossreduce(cb,model)
  coef[i,] <- coef(red)
  vcov[[i]] <- vcov(red)
  
}
dev.off()
proc.time()[3]-time

#
