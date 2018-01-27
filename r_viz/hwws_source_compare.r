library(ggplot2)
library(haven)
library(data.table)

## Load in data
## file <- "J:/WORK/01_covariates/02_inputs/water_sanitation/hygiene/data/prevalence/hygiene_compiled.dta"
file <- "J:/WORK/05_risk/risks/wash_hygiene/data/exp/me_id/input_data/01_data_audit/compile/cw_subset.dta"
df <- data.table(read_stata(file))

## Label reference data factor
df <- df[, reference_data := factor(reference_data, levels=c(0,1), labels=c("DHS/MICS", "Literature"))]

## Assign colors to factors
ref.colors <- c("blue", "red")
ref.values <- c("DHS/MICS", "Literature")

## Graph
pdf("J:/WORK/05_risk/risks/wash_hygiene/diagnostics/version_2/scatter_DHSvLIT.pdf")

for (loc in unique(df$ihme_loc_id)) { 
print(loc)
 plot <- ggplot(df[ihme_loc_id==loc,]) +
          geom_point(aes(y=hwws_prev, x=year, color=reference_data)) +
          scale_colour_manual(drop=FALSE, name="Legend", values=setNames(ref.colors, ref.values)) +
          scale_x_continuous(limits=c(1990, 2015)) +
          scale_y_continuous(limits=c(0,1)) +
          ggtitle(loc)
 print(plot)
}

dev.off()


root <- "J:/"
path <- "WORK/01_covariates/"
paste0(root, path, "blah.pdf")