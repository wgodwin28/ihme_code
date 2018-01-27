# Greg Freedman
# Ambient Air Pollution RR function generation
# 1/11/2014

library(ggplot2)
library(grid)

# working directory
data <- 'C:/Users/jfrostad/Desktop/RISK_LOCAL/air_pm/STAN/data/oap_shift/'

causes <- c("resp_copd", "neo_lung", "lri", "cvd_ihd", "cvd_stroke")

for (ccc in causes) {
  if (ccc == "resp_copd") {
    age.list <- c(99)
    seed <- 1926429
  } else if (ccc == "neo_lung") {
    age.list <- c(99)
    seed <- 1458021
  } else if (ccc == "lri") {
    age.list <- c(99)
    seed <- 1647938
  } else if (ccc == "cvd_ihd") {
    age.list <- seq(25, 80, by=5)
    seed <- 521741
  } else if (ccc == "cvd_stroke") {
    age.list <- seq(25, 80, by=5)
    seed <- 175367
  }
  
  
  
  for (aaa in age.list) {
    
    print(ccc)
    print(aaa)
    
    arg <- c("power2", ccc, aaa, "gbd2013_mean_updated", "J:/WORK/05_risk_old/01_database/02_data/air_pm/02_rr/01_lit/02_download/", 
             "J:/WORK/05_risk_old/01_database/02_data/air_pm/02_rr/04_models/output/", "J:/WORK/05_risk_old/01_database/02_data/air_pm/03_tmred/04_models/output/tmred_gbd2013.csv", 
             "J:/WORK/05_risk_old/01_database/02_data/air_pm/02_rr/04_models/code/functional_forms_updated.r", 1458021)
    ## Read in arguments passed in by shell script.
    # 	arg <- commandArgs()[-(1:3)]                  # First args are for unix use only
    functional.form <- arg[1]                     # Functional form name
    cause <- arg[2]                               # Cause name
    age <- as.numeric(arg[3])                     # Age (99 means all age)
    version <- arg[4]                             # Version name
    data.dir <- arg[5]                            # Directory that holds data
    out.dir <- arg[6]                             # Directory that holds results
    tmred.file <- arg[7]                          # A file with the draws TMRED level of pm2.5
    functions.file <- arg[8]                      # A file which defines the functional forms
    seed <- as.numeric(arg[9])                    # Random seed
    
    set.seed(seed)
    
    # Other useful arguments
    terminal.age <- 110   # age at which age-specific causes no longer are at risk for cause

    # Prep tmred data
    tmred.list <- read.csv(tmred.file)
    tmred <- (5.9 + 8.7)/2
    tmred <- 8.12757 # took the first draw of tmred draws for gbd2013 fitting
    
    # Prep rr study data
    input <- read.csv(paste0(data.dir, "rr_", version, ".csv"))
    names(input) <- tolower(names(input))
    input <- input[input$cause == cause, ]
      # input <- input[input$source != "ActSmok",] # just run this for sensitivity testing to remove the AS data
    input$conc_den <- ifelse(is.na(input$conc_den), 0, input$conc_den)
    
    # Calculate sd from CI if sd is missing
    input$logrrsd <- ifelse(is.na(input$logrrsd), (input$logrrupper - input$logrrlower)/3.92, input$logrrsd)
    
    # Put means in first row to calculate point estimate
    input$rr <- exp(input$logrr)
    
    # Shift OAP RRs, because the RR is actually the RR per 1 micrograms of PM2.5. So we assume essentially a 
    # log-linear relationship of RR up to the study mean level PM2.5
    # New for GBD2013: We now have zdenominators for OAP studies, so we should only shift to max of denominator or tmred, 
    # between the 5th and 95th percentiles of exposure in study.
    shift.bottom <- outer(input[input$source == "OAP", "conc_den"], tmred, function(x, y) pmax(x, y))
    shift <- input[input$source == "OAP", "conc"] - shift.bottom
    input[input$source == "OAP", paste0("rr")] <- 
      exp(log(input[input$source == "OAP", paste0("rr")]) * shift)
    
    # Create a separate data.frame so we can make some modifications to the values.
    
    # Tmred
    draw.data <- data.frame(tmred=rep(tmred, length(input$conc)))
    
    
    # We hold the IER curve to be 1 when it is below the tmred, but the 
    # function would actually go below 1. Therefore, we set the z to be the
    # tmred when it goes below. 
    draw.data$z.num <- ifelse(input$conc < draw.data$tmred, draw.data$tmred, input$conc)
    draw.data$z.den <- ifelse(input$conc_den < draw.data$tmred, draw.data$tmred, input$conc_den)
    
    ### For age specific RRs, interpolate all-age log RR to terminal age to
    ### get RR estimates. Implement Steve's approach:
    ### Force x-intercept to be equal to terminal age. That is
    ### 0 = \beta_0 + \beta_1*term.age
    ### and in general
    ### log(RR_age) = \beta_0 + \beta_1*age
    ### So, we have that
    ### \beta_1 = (log(RR_age) - 0) / (age - term.age)
    ### And log(RR_age)= \beta_1(age - term.age)
    if (age == 99) {
      draw.data$rr <- input[, paste0("rr")]
    } else {
      slopes <- (log(input[, paste0("rr")]) - 0) / (input$medage - terminal.age)
      draw.data$rr <- exp(slopes * (age - terminal.age))
    }
    
    # Add on source type and weight variables
    draw.data$weights = 1/(input$logrrsd^2)
    draw.data$zsource = input$source
    draw.data$cause = cause
    draw.data$logrr <- input$logrr
    draw.data$logrrsd <- input$logrrsd
    draw.data$study <- input$study
    
    save(draw.data, file=paste0(data, ccc, "_", aaa, ".Rdata"))
    
  }
}
    