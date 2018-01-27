#----HEADER----------------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 07/14/2015
# Purpose: Create graphs of HAP/SHS/AS RRs and Exposure in order to investigate what is driving changes to the PAF after code update
# source("")
# to submit: qsub -N graph_exposure -pe multi_slot 5 -l mem_free=10G "/home/j/WORK/05_risk/01_database/02_data/air_hap/02_rr/04_models/code/rshell.sh" "/home/j/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/code/dev/02_graph.R" 5

#********************************************************************************************************************************

#----CONFIG----------------------------------------------------------------------------------------------------------------------
if (Sys.info()["sysname"] == "Linux") {
  root <- "/home/j" 
  arg <- commandArgs()[-(1:3)]  # First args are for unix use only
} else { 
  root <- "J:"
  arg <- c(1)
}

cores.provided <- arg[1]

# load packages

require("ggplot2")
require("gridExtra")
require("RColorBrewer")
require("scales")
require("reshape2")
require("plyr")
require("data.table")
require("parallel")

# load functions

addline_format <- function(x,...){
  gsub('\\s','\n',x)
}

simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1, 1)), substring(s, 2),
        sep = "", collapse = " ")
}

# Define general directories in objects
graph.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/graphs/")

# SECONDHAND SMOKE
# Define risk-specific directories in objects
risks <- c("AS", "SHS")

exposureHist <- function(risk, metric.type) {
  
  if (risk == "SHS") {
    
    risk.long = "smoking_shs" 
    risk.version = 10
    
  } else if (risk == "AS") {
    
    risk.long = "smoking_direct"
    risk.version = 3
  
  } 

rr.dir <- paste0(root, "/WORK/05_risk/01_database/02_data/", risk.long, "/02_rr/04_models/")
prepped.data <- paste0(rr.dir, "data/prepped/clean.Rdata")
load(prepped.data)
exposure <- eval(parse(text=paste0(risk,".global.exp")))
rr.summary <- fread(paste0(rr.dir, "output/all_", metric.type, "_summary_v", risk.version, ".csv"))
rr.lite <- fread(paste0(rr.dir, "output/all_", metric.type, "_lite_v", risk.version, ".csv"))
countries <- unique(rr.summary$iso3)
causes <- unique(rr.summary$cause)

# exposure histogram - 2013

pdf(paste0(graph.dir, risk, "_exposure_histogram.pdf"), width=11,height=8)

for (country in countries) {
  
  print(paste0(risk, "-", country))
  
  data <- exposure[iso3 == country & year == 2013]
  exposure.max <- max(data$exposure)
  range <- range(data$exposure)[2] - range(data$exposure)[1]
  
  print(
  ggplot(data=data, aes(exposure)) + 
                geom_histogram(binwidth=2,
                               col="black", 
                               fill="chartreuse3", 
                               alpha = .5) + 
#                 geom_vline(x=7.328414,
#                           col="red") +
                labs(title=paste0(risk, ": Draws of PM Exposure \n Country= ", country," / Year = 2013")) +
                labs(x="PM2.5 Exposure", y="Count") +
                # xlim(0, round_any(exposure.max+5, 10)) +
                theme_bw())


  
}

dev.off()

}

mclapply(risks, FUN=exposureHist, metric.type = "yll", mc.cores = cores.provided)

exposureHist(risk="AS", metric.type="yll")



