rm(list=ls())
run <- 813
cat <- "piped"
source("J:/WORK/05_risk/central/code/custom_model_viz/gpr_viz.r")
input_data <- paste0("J:/temp/wgodwin/gpr_output/run1/wash_water_piped_", run, "_1.csv")
output_graph <- paste0("J:/temp/wgodwin/diagnostics/water/run_", run, "_", cat, ".pdf")
gpr_viz(input_data, output_graph, sex.age.agg=TRUE, add.regions = TRUE, add.gpr2013=F)

gpr_viz("J:/temp/wgodwin/diagnostics/sanitation/san_piped_compare_run_59.csv", "J:/WORK/05_risk/risks/wash_sanitation/diagnostics/version_7/sanitation_piped_compare_run_59.pdf", sex.age.agg=TRUE, add.regions = TRUE, add.gpr2013=TRUE)
