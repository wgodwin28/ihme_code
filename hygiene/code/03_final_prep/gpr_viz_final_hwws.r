rm(list=ls())
source("J:/WORK/05_risk/central/code/custom_model_viz/gpr_viz.r")
gpr_viz("J:/temp/wgodwin/save_results/wash_hwws/rough_output/hwws_viz_04152016.csv", "J:/WORK/05_risk/risks/wash_hygiene/diagnostics/version_1_final/hwws_04152016.pdf", sex.age.agg=TRUE, add.regions = TRUE, add.gpr2013=TRUE)