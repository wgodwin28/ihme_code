rm(list=ls())
source("J:/WORK/05_risk/central/code/custom_model_viz/gpr_viz.r")
gpr_viz("J:/temp/wgodwin/diagnostics/hwws/hwws_final_new2.csv", "J:/temp/wgodwin/diagnostics/new_hwws/hwws_final_scatter2.pdf", sex.age.agg=TRUE, add.regions = TRUE)
