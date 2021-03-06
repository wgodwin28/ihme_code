################################################################################
## File Name: plot_smoothing.r

## File Purpose: Plot the prevalence of improved water and improved sanitation by
##   country
## Author: Leslie Mallinger
## Date: 8/9/2011
## Edited on:

## Additional Comments: 
################################################################################

## set up R
rm(list=ls())
library(foreign)
library(RColorBrewer)

## set directories
gpr_output_folder <- "C:/Users/tomflem/Documents/Covariates/Updates/water_sanitation/model/gpr_output/"
spacetime_output_folder <- "C:/Users/tomflem/Documents/Covariates/Updates/water_sanitation/model/st_output/"
graph_folder <- "C:/Users/tomflem/Documents/Covariates/Updates/water_sanitation/model/graphs/"


## specify and loop through models to plot
models <- c("w_covar", "s_covar")
for (model in models) {  
    ## read in and format data
    ## GPR and spacetime estimates, with non-outlier data included
    data <- read.dta(paste(gpr_output_folder, "gpr_results_", model, 
                           "_with_orig_data.dta", sep=""), convert.factor=F)
    data <- data[, c("iso3", "countryname", "region", "super_region", "year", 
                     "actual_prev", "step1_prev", "step2_prev", "gpr_lower", 
                     "gpr_mean", "gpr_upper", "national", "plot")]
  
    ## outlier data
    if (grepl("w", model)) indicator <- "Water" else indicator <- "Sanitation"
    indicator_lower <- tolower(indicator)
    outliers <- read.dta(paste(spacetime_output_folder, indicator_lower, 
                               "_outliers.dta", sep=""), convert.factor=F)
    outliers <- outliers[, c("iso3", "countryname", "gbd_region", 
                             "gbd_super_region_name", "year", "actual_prev", "national", 
                             "plot")]
    names(outliers)[names(outliers)=="gbd_region"] <- "region"
    names(outliers)[names(outliers)=="gbd_super_region_name"] <- "super_region"
    vars_to_add <- c("step1_prev", "step2_prev", "gpr_lower", "gpr_mean", 
                     "gpr_upper")
    for (var in vars_to_add) {
      outliers[,var] <- NA
    }
    
    ## combine
    data <- rbind(data, outliers)
    
#    ## normalize x-axis data to fit within 0:1 plotting frame
#    data$year <- (data$year-1980)/(2015-1980)
    
  
  ## set colors and styles for plot types
    ## types
    plot_types <- c("MICS", "DHS", "RHS", "LSMS", "Census", "IPUMS", "Other", 
                    "Report", "JMP", "Subnat.", "Outlier")
  
    ## colors
    colors <- brewer.pal(10, "Paired")
    colors <- c(colors[1:8], colors[10], "black", "red")
    
    ## styles
    plot_styles <- c(rep(16,6), 15, 17, 2, 3, 4)
    
    ## combine settings
    plot_settings <- data.frame(cbind(colors, plot_types, plot_styles), 
                                stringsAsFactors=F)
    colnames(plot_settings) <- c("plot_color", "plot", "plot_style")
    plot_settings$plot_style <- as.numeric(plot_settings$plot_style)
  
    ## add to full dataset
    data <- merge(data, plot_settings, all=T)
    data <- data[order(data$countryname, data$year),]
    
  
  ## plot
    ## extract country list
    countries <- sort(unique(data$countryname))
    
    ## initialize pdf
    pdf(file=paste(graph_folder, model, "_plots_R.pdf", sep=""), height=7, 
        width=10)
    
    ## loop through countries
    for (c in 1:length(countries)) {
#   c <- 1
      country <- countries[c]
      
      ## set graph layout
      layout(matrix(c(1,2), nrow=2), heights=c(8,2))
      
      ## set graph structure
      par(mar=c(2,4,4,2))
      plot(x=seq(from=1980, to=2015, length.out=10),
           y=seq(from=0, to=1, length.out=10),
           main=paste("Improved", indicator, "\n", country),
           xlab="Year",
           ylab="Prevalence",
           type="n")
      
     # plot.new()
#      title(main=paste("Improved Water\n", country),
#            xlab="Year",
#            ylab="Prevalence")
#      axis(side=1,
#           at=seq(from=0, to=1, length.out=8),
#           labels=seq(from=1980, to=2015, length.out=8))
#      axis(side=2,
#           at=seq(from=0, to=1, by=.1),
#           las=1)
#      box()
           
      ## add polygon for confidence interval
      polygon(x=c(data[data$countryname==country & !is.na(data$gpr_lower), "year"],
                  rev(data[data$countryname==country & !is.na(data$gpr_lower), "year"])),
              y=c(data[data$countryname==country & !is.na(data$gpr_lower), "gpr_lower"],
                  rev(data[data$countryname==country & !is.na(data$gpr_lower), "gpr_upper"])),
              col="gray90",
              border=F)
              
      ## add OLS estimate
      lines(x=data[data$countryname==country & !is.na(data$step1_prev), 
                   "year"], 
            y=data[data$countryname==country & !is.na(data$step1_prev), 
                   "step1_prev"],
            lty="dotted",
            lwd=1.5,
            col="black")
            
      ## add spacetime estimate
      lines(x=data[data$countryname==country & !is.na(data$step2_prev), 
                   "year"],
            y=data[data$countryname==country & !is.na(data$step2_prev), 
                   "step2_prev"],
            lty="dashed",
            lwd=1.5,
            col="black")
            
      ## add GPR estimates
      lines(x=data[data$countryname==country & !is.na(data$gpr_mean), 
                   "year"],
            y=data[data$countryname==country & !is.na(data$gpr_mean), 
                   "gpr_mean"],
            lty="solid",
            lwd=2,
            col="black")
           
      ## add normal data points
      points(x=data[data$countryname==country, "year"],
             y=data[data$countryname==country, "actual_prev"],
             type="p",
             pch=data$plot_style[data$countryname==country],
             cex=1.5,
             col=data$plot_color[data$countryname==country])
             
      ## mark subnational data points
      points(x=data[data$countryname==country & (data$nopsu=="1" | 
                    data$noweight=="1" | data$subnational==1 | 
                    data$plot=="Subnational"), "year"],
             y=data[data$countryname==country & (data$nopsu=="1" | 
                    data$noweight=="1" | data$subnational==1 | 
                    data$plot=="Subnational"), "water"],
             type="p",
             pch=4,
             col="black")
             
      ## add legend
      par(mar=c(0.5,0.5,0.5,0.5))
      plot(x=1, y=1, type="n", bty="n", xaxt="n", yaxt="n") 
      legend("center",
             legend=c(plot_settings$plot, "Stage 1", "Stage 2", "Stage 3"),
             pch=c(plot_settings$plot_style, rep(NA, 3)),
             lty=c(rep(NA, length(plot_settings$plot_style)), "dotted", "dashed",
                   "solid"),
             lwd=c(rep(NA, length(plot_settings$plot_style)), 1.5, 1.5, 2),
             col=c(plot_settings$plot_color, "black", "black", "black"),
             ncol=4)
    }
    dev.off()
}  