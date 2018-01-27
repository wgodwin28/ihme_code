################################################################################
## File Name: plot_prop_uncertain.r

## File Purpose: Plot the proportion of households that have an uncertain improvement status
## Author: Leslie Mallinger
## Date: 8/5/2011
## Edited on:

## Additional Comments: 
################################################################################

## set up R
rm(list=ls())
library(foreign)
library(RColorBrewer)

compiled_folder <- "C:/Users/asthak/Documents/Covariates/Water and Sanitation/data/Compiled/"
graph_folder <- "C:/Users/asthak/Documents/Covariates/Water and Sanitation/graphs/prevalence/"

  
## read in and format data
data <- read.dta(paste(compiled_folder, "prev_all_rough.dta", sep=""), convert.factor=F)
names(data)[names(data)=="iwater_uncertain"] <- "water"
names(data)[names(data)=="isanitation_uncertain"] <- "sanitation"


## set colors for plot types
colors <- brewer.pal(10, "Paired")
plot_types <- c("MICS", "DHS", "RHS", "LSMS", "Census", "IPUMS", "Other")
plot_colors <- data.frame(cbind(colors[1:7], plot_types), stringsAsFactors=F)
colnames(plot_colors) <- c("plot_color", "plot")
data <- merge(data, plot_colors)                                                                               


## specify the indicators and countries for graphing
indicators <- c("Water", "Sanitation")
countries <- sort(unique(data$countryname))


## plot
for (i in 1:length(indicators)) {
  indicator <- indicators[i]
  indicator_lower <- tolower(indicator)

  pdf(file=paste(graph_folder, "prop_uncertain_by_country_", indicator_lower, ".pdf", sep=""), height=7, width=10)
  for (c in 1:length(countries)) {
    country <- countries[c]
#    par(xaxs="i", yaxs="i")
    plot(x=data[data$countryname==country, "startyear"],
         y=data[data$countryname==country, indicator_lower], 
         main=paste("Proportion of Households with an Ambiguous", indicator, "Facility \n", country),
         xlab="Survey Year",
         ylab="Proportion",
         xlim=c(1980, 2010),
         ylim=c(0,1))
    points(x=data[data$countryname==country, "startyear"],
           y=data[data$countryname==country, indicator_lower],
           type="p",
           pch=16,
           cex=1.5,
           col=data$plot_color[data$countryname==country])
    legend("topleft", legend=plot_colors$plot, fill=plot_colors$plot_color)
  }
  dev.off()
}