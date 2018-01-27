rm(list=ls())
source("J:/WORK/05_risk/central/code/custom_model_viz/gpr_viz.r")
gpr_viz("J:/temp/wgodwin/gpr_output/water_piped_output_full_0408_col.csv", "J:/WORK/05_risk/risks/wash_water/diagnostics/version_8/water_piped_570_243_col.pdf", sex.age.agg=TRUE, add.regions=TRUE, add.gpr2013=TRUE)