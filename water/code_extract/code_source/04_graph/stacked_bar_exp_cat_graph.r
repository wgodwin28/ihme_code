## Filename: stacked_exp_cat_graph.r
##Purpose: Generate stacked bar graphs of exposure categories for WSH by GBD countries
##Date: 04/15/2014
##Author: Astha KC

##houskeeping
rm(list = ls()) 

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
	pdf(file=paste(graph_folder, "water_exp_stackedbar_08152014_2.pdf", sep=""), height = 7, width=10)
	
	##loop through each country
for (l in 1:length(locations)) {
	##l <- 3
	
	##limiting dataset to one location at a time
	location <- locations[l]
	plot_data <- exp_data[exp_data$location_name==location & !is.na(exp_data$year) & !is.na(exp_data$exp_cat1),]
	
	##plot all 9 exposure categories
	sequential <- brewer.pal(9, "BuGn") 
	
	p <- barplot(t(plot_data[,4:12]))
	##p <- ggplot(plot_data, aes(x=year, y = exp_prev , fill = exp_cat, group = exp_cat, stat='stacked')) + geom_bar() + scale_fill_brewer(name = "Exposure Categories", palette="Blues") + 
		##labs(x = "Year", y = "Proportion of households", title = paste("Access to Water", "-", location, sep=" "))
		
	plot(p)
	}
	dev.off()
	
##End of Code##