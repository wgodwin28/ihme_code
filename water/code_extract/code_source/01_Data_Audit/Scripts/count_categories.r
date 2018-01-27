################################################################################
## File Name: count_categories.r

## File Purpose: Count the number of water and sanitation categories from surveys
## Author: Leslie Mallinger
## Date: 8/5/2011
## Edited on:

## Additional Comments: 
################################################################################

## set up R
rm(list=ls())
library(foreign)
library(RColorBrewer)

label_key_folder <- "J:/Project/COMIND/Water and Sanitation/Data Audit/Data/Label Keys/"
label_key_date <- "08082011"
  
## read in data
label_key_water <- read.csv(paste(label_key_folder, "label_key_water_validated_", label_key_date, ".csv", sep=""))
label_key_sanitation <- read.csv(paste(label_key_folder, "label_key_sanitation_validated_", label_key_date, ".csv", sep=""))

## loop through columns and count the number of entries
count <- 0
for (var in names(label_key_water)) {
  count <- count + length(unique(label_key_water[, var]))
}
paste("Number of water categories:", count)

count <- 0
for (var in names(label_key_sanitation)) {
  count <- count + length(unique(label_key_sanitation[, var]))
}
paste("Number of sanitation categories:", count)