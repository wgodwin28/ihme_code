rm(list=ls())
source("J:/WORK/05_risk/central/diagnostics/custom_model_viz/custom_model_pdf_function.r")
custom_model_pdf_function("J:/WORK/05_risk/risks/wash_sanitation/data/exp/me_id/input_data/gpr_output/sanitation_imp_output_nat.csv", "J:/WORK/05_risk/risks/wash_sanitation/data/exp/me_id/input_data/graphs/sanitation_imp_plot.pdf", sex.age.agg=TRUE, add.regions = TRUE)