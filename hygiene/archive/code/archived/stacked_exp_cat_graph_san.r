## Filename: stacked_exp_cat_graph.r
##Purpose: Generate stacked bar graphs of exposure categories for WSH by GBD countries
##Date: 04/15/2014
##Author: Astha KC

##Load functions
library(foreign)
library(ggplot2)
library(RColorBrewer)

##set directories
graph_folder <- "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/output/graphs/"

##Read into R
exp_data <- read.dta("J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/output/graphs/stacked_graph_cats_10032014.dta")

##Generate Plots
	##extract locations list
	locations <- sort(unique(exp_data$location_name))
	
	##initialize pdf
	pdf(file=paste(graph_folder, "san_exp_stacked_10032014.pdf", sep=""), height = 7, width=10)
	
	##loop through each country
for (l in 1:length(locations)) {
	##Debugging only
	##l <- 3
	
	##limiting dataset to one location at a time
	location <- locations[l]
	plot_data <- exp_data[exp_data$location_name==location & !is.na(exp_data$year)& !is.na(exp_data$exp_prev),]
	
	##plot all 9 exposure categories
	p <- ggplot(plot_data, aes(x=year, y = exp_prev, fill = exp_cat, group = exp_cat, stat='stacked')) + geom_area() + scale_fill_manual(name = "Exposure Categories", values = rev(brewer.pal(6, "RdYlBu"))) + ylim(0,1) + labs(x = "Year", y = "Proportion of households", title = paste("Access to Sanitation", "-", location, sep=" "))
		
	plot(p)
	}
	
	dev.off()
	
##scale_fill_brewer(name = "Exposure Categories", palette = color) + 

##End of Code##