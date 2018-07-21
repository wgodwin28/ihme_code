### Generate RR for unsafe water
### Combine RR for source water and HWT in prep for GBD 2016

# clear memory
rm(list=ls())

# runtime configuration
if (Sys.info()["sysname"] == "Linux") {
  j_root <- "/home/j" 
  h_root <- "/home/h"
} else { 
  j_root <- "J:"
  h_root <- "H:"
}

## Setup
library(data.table)
library(parallel) # Useful for mclapply function

###############################################################
###1. Generate a 1000 draws of water source interventions###
###############################################################

# effect of improving water sources
## improved community source
  rr_improved <- log(0.89)
  upper_improved <- 0.78
  lower_improved <- 1.01
  sd_improved <- (log(lower_improved) - log(upper_improved))/(2 * qnorm(.975))
  improved <- exp(rnorm(1000, mean = rr_improved, sd = sd_improved))

## piped water supply in low/middle income countries; defined as "basic piped supply" by Wolf et al 2014.   
    rr_piped_lmi <- log(0.77)
    upper_piped_lmi <- 0.64
    lower_piped_lmi <- 0.92
    sd_piped_lmi <- (log(lower_piped_lmi) - log(upper_piped_lmi))/(2 * qnorm(.975))
    piped_lmi <- exp(rnorm(1000, mean = rr_piped_lmi, sd = sd_piped_lmi))
    
## piped water supply in high income countries (for our analysis - this applies to central/eastern europe and high income latin america)
    rr_piped_hi <- log(0.19)
    upper_piped_hi <- 0.07
    lower_piped_hi <- 0.50
    sd_piped_hi <- (log(lower_piped_hi) - log(upper_piped_hi))/(2 * qnorm(.975))
    piped_hi <- exp(rnorm(1000, mean = rr_piped_hi, sd = sd_piped_hi))
  
##################################################################
###2. Merge together draws for water sources##################
##################################################################
    
dt_source <- as.data.table(cbind(improved, piped_lmi, piped_hi))
    
    
    for (i in 6:21) {
    pop.merged.data[age==i, hiv_deaths2:=(hiv_deaths/spectrum_pop)*pop]
  }
  