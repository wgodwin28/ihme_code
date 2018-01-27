################################################################################
## File Name: plot_prev_all.r

## File Purpose: Plot the prevalence of improved water and improved sanitation by country
## Author: Leslie Mallinger
## Date: 8/9/2011
## Edited on:

## Additional Comments: 
################################################################################

## set up R
rm(list=ls())
library(foreign)
library(RColorBrewer)

compiled_folder <- "C:/Users/lmalling.IHME/Documents/Water and Sanitation/Data Audit/Data/Compiled/"
graph_folder <- "C:/Users/lmalling.IHME/Documents/Water and Sanitation/Graphs/Prevalence/"


## specify prevalence types and indicators for plotting
prevtypes <- c("rough", "final")
indicators <- c("Water", "Sanitation", "Combined")


## loop through prevalence types
for (prevtype in prevtypes) {
#  prevtype <- prevtypes[p]

  ## read in and format data
  data <- read.dta(paste(compiled_folder, "prev_all_", prevtype, ".dta", sep=""), convert.factor=F)
  names(data)[names(data)=="iwater_mean"] <- "water"
  names(data)[names(data)=="isanitation_mean"] <- "sanitation"
  names(data)[names(data)=="icombined_mean"] <- "combined"
  
  
  ## set colors and styles for plot types
  colors <- brewer.pal(10, "Paired")
  colors <- c(colors[1:8], colors[10])
  plot_types <- c("MICS", "DHS", "RHS", "LSMS", "Census", "IPUMS", "Other", "Report", "JMP")
  plot_styles <- c(rep(16,6), 15, 17, 2)
  plot_settings <- data.frame(cbind(colors, plot_types, plot_styles), stringsAsFactors=F)
  colnames(plot_settings) <- c("plot_color", "plot", "plot_style")
  plot_settings$plot_style <- as.numeric(plot_settings$plot_style)
  data <- merge(data, plot_settings)
  
  
  ## specify the indicators and countries for graphing
  
  countries <- sort(unique(data$countryname))
  
  
  ## plot
  for (i in 1:length(indicators)) {
    indicator <- indicators[i]
    indicator_lower <- tolower(indicator)
  
    pdf(file=paste(graph_folder, "prevalence_", indicator_lower, "_", prevtype, ".pdf", sep=""), height=7, width=10)
    for (c in 1:length(countries)) {
      country <- countries[c]
      #par(xaxs="i", yaxs="i")
      par(lab=c(9,6,7))
      plot(x=data[data$countryname==country, "startyear"],
           y=data[data$countryname==country, indicator_lower], 
           main=paste(country, "\nImproved", indicator),
           xlab="Year",
           ylab="Prevalence",
           xlim=c(1970, 2010),
           ylim=c(0,1),
           type="n")
      points(x=data[data$countryname==country, "startyear"],
             y=data[data$countryname==country, indicator_lower],
             type="p",
             pch=data$plot_style[data$countryname==country],
             cex=1.5,
             col=data$plot_color[data$countryname==country])
      points(x=data[data$countryname==country & (data$nopsu=="1" | data$noweight=="1" | 
                      data$subnational==1 | data$plot=="Subnational"), 
                    "startyear"],
             y=data[data$countryname==country & (data$nopsu=="1" | data$noweight=="1" | 
                      data$subnational==1 | data$plot=="Subnational"),
                    indicator_lower],
             type="p",
             pch=4,
             col="black")
      legend("topleft", 
             legend=c(plot_settings$plot, "Subnat."),
             pch=c(plot_settings$plot_style, 4),
             col=c(plot_settings$plot_color, "black"))
    }
    dev.off()
  }
}
