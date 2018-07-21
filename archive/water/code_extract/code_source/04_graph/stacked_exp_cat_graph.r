## Filename: stacked_exp_cat_graph.r
##Purpose: Generate stacked bar graphs of exposure categories for WSH by GBD countries
##Date: 04/15/2014
##Author: Astha KC

##Load functions
library(foreign)
library(ggplot2)
library(RColorBrewer)

##set directories
graph_folder <- "J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/stacked/"

##Read into R
exp_data <- read.dta("J:/WORK/01_covariates/02_inputs/water_sanitation/graphs/stacked/stacked_graph_cats_08152014.dta")

##Generate Plots
	##extract locations list
	locations <- sort(unique(exp_data$location_name))
	
	##initialize pdf
	pdf(file=paste(graph_folder, "water_exp_stacked_08152014.pdf", sep=""), height = 7, width=10)
	
	##loop through each country
for (l in 1:length(locations)) {
	##Debugging only
	##l <- 3
	
	##limiting dataset to one location at a time
	location <- locations[l]
	plot_data <- exp_data[exp_data$location_name==location & !is.na(exp_data$year)& !is.na(exp_data$exp_prev),]
	
	##plot all 9 exposure categories
	p <- ggplot(plot_data, aes(x=year, y = exp_prev , fill = exp_cat, group = exp_cat, stat='stacked')) + geom_area() + scale_fill_manual(name = "Exposure Categories", values = rev(brewer.pal(9, "Blues"))) + ylim(0,1) +
		labs(x = "Year", y = "Proportion of households", title = paste("Access to Water", "-", location, sep=" "))
		
	plot(p)
	}
	
	dev.off()
	
##scale_fill_brewer(name = "Exposure Categories", palette = color) + 

##End of Code##