rm(list=ls())
source("J:/WORK/05_risk/central/diagnostics/custom_model_viz/custom_model_pdf_function.r")
custom_model_pdf_function("J:/WORK/05_risk/risks/wash_water/data/exp/me_id/input_data/gpr_output/water_itreat_piped_output_nat5.csv", "J:/WORK/05_risk/risks/wash_water/diagnostics/version_3/water_itreat_piped_plot2.pdf", sex.age.agg=TRUE, add.regions = TRUE)