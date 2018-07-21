library(ggplot2)
library(haven)
library(data.table)

## Load in data
file <- "J:/WORK/05_risk/risks/wash_water/data/exp/me_id/uploaded/rough_output/allcat_prev_water_03142016.dta"
df <- data.table(read_stata(file))
date <- 03242016

##Generate Plots
##extract locations list
locations <- sort(unique(df$location_name))

##initialize pdf
pdf("J:/WORK/05_risk/risks/wash_water/diagnostics/version_6/water_stacked_03242016.pdf")

##loop through each country
for (l in 1:length(locations)) {
  ##Debugging only
  ##l <- 3
  
  ##limiting dataset to one location at a time
  location <- locations[l]
  plot_data <- df[df$location_name==location & !is.na(df$year)& !is.na(df$exp_prev),]
  
}