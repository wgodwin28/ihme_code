## Leslie Cornaby
## 12/18/2017
## Causal Criteria: BETA validation
## ------------------------------------------------------------------------------------------##
library(openxlsx)
library(dplyr)

## ------------------------------------------------------------------------------------------##
rm(list = ls())
if (Sys.info()["sysname"] == "Darwin") j_drive <- "/Volumes/snfs"
if (Sys.info()["sysname"] == "Linux") j_drive <- "/home/j"
if (Sys.info()["sysname"] == "Windows") j_drive <- "J:"


if (Sys.info()["sysname"] == "Darwin") i_drive <- "/Volumes/IHME"
if (Sys.info()["sysname"] == "Linux") i_drive <- "/home/i"
if (Sys.info()["sysname"] == "Windows") i_drive <- "I:"

## Setting work directory so you can access the function
work_dir <- paste0(i_drive,"/RTs_and_Projects/GBD/Teams/Pooled cohorts and CC/Causal criteria/cleaning and analysis/Validation/")
setwd(work_dir)

#path <- "/WORK/05_risk/risks/wash_hygiene/data/rr/causation_criteria/CC_wgodwin_handwashing_Feb2_2017.xlsm"
path <- "/WORK/05_risk/risks/wash_sanitation/data/rr/causation_criteria/CC_wash_sanitation_wgodwin_Jan2_2017_valid.xlsm"

#no cleaning of extraction sheet needed, just make sure your extraction sheet is labeled 'extraction'
extraction_sheet <- read.xlsx(paste0(j_drive, path), sheet="extraction", colNames=TRUE) #replace file pathway
extraction_sheet <- extraction_sheet[-c(1, 2),] #drop descriptive rows
extraction_sheet[extraction_sheet=="N/A"] <-NA
extraction_sheet <- extraction_sheet[!(is.na(extraction_sheet$location_name) | extraction_sheet$location_name==""),]

source("required_columns.R")
required_columns(extraction_sheet)
