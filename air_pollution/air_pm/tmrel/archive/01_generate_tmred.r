# Greg Freedman
# Generate TMRED for Ambient air pollution
# 1/11/2014

out.dir <- "J:/WORK/05_risk/01_database/02_data/air_pm/03_tmred/04_models/output"
seed <- 2846702
nsim <- 1000
set.seed(seed)
version <- "gbd2013"

# GBD 2010 
if (version == "gbd2010") tmred <- data.frame(tmred=runif(nsim, 5.8, 8.8))

# GBD 2013: Quote from EG report.
	# The GBD 2010 TMRED was based on Uniform uncertainty distribution with lower/upper bound equal to minimum and 5th percentile 
	# from the ACS study alone:  U(5.8, 8.8). For GBD 2013 we propose to use the same general approach but use similar information 
	# from additional cohort studies, besides the ACS, which are listed in Table 1.   However, we excluded three cohort studies for 
	# which their minimum exposure concentration was greater than the 5th percentile observed in the ACS of 8.8µg/m3 since they did 
	# not provide information on risk at concentrations for which we a priori believed there existed an association.   We thus excluded 
	# AHSMOG (minimum=12.9µg/m3), DSDC (minimum=23.0µg/m3), and the Japanese cohort (minimum=16.8µg/m3). 
	# We then averaged either the minimum or 5th percentile concentrations among the nine remaining studies resulting in average 
	# values of 5.9 and 8.7 respectively.
	# We thus define: TMRED ~ U(5.9, 8.7).
if (version == "gbd2013") tmred <- data.frame(tmred=runif(nsim, 5.9, 8.7))


write.csv(tmred, paste0(out.dir, "/tmred_", version, ".csv"), row.names=F)

