source("J:/WORK/05_risk/central/code/maps/global_map.R")
library(data.table)
df <- fread("J:/temp/wgodwin/diagnostics/hwws/final_new2.csv")
global_map(data=df, map.var="mean", plot.title="Prevalence of Handwashing", output.path="J:/temp/wgodwin/diagnostics/new_hwws/hwws_map_final_new3.pdf", years=c(1990, 1995, 2000, 2005, 2010, 2015), ages = 22, sexes=3, subnat=TRUE, scale="cont", col="easter_to_earth", col.rev=FALSE)
