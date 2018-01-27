#load library
library(data.table)
library(netmeta)

#Sanitation
  dat.root <- "J:/WORK/05_risk/risks/wash_sanitation/data/rr/meta_analysis/"
  dt <- fread(paste0(dat.root, "sanitation_rr.csv"))
  #dt <- dt[reference !="Capun2"]
  dt <- dt[reference !="Capun3"]
  #dt <- dt[reference !="Capun4"]
  
  dt_san <- dt[, c("effectsize", "standard_error", "intervention_clean", "control_edit",
                  "reference")]
  dt_san <- dt[intervention_clean != "open_def" & control_edit != "."]
  #dt_san <- dt_san[reference !="Baker11"]
  #dt_san <- dt_san[reference !="Baker6"]
  #dt_san <- dt_san[reference !="Baker4"]
  #dt_san <- dt_san[reference !="Baker3"]
  dt_san <- dt_san[, log_rr := log(effectsize)]
  dt_san <- dt_san[, log_se := sqrt((standard_error^2) * (1/effectsize)^2)]
  
  net1 <- netmeta(log_rr, log_se, intervention_clean, control_edit,
                  reference, data = dt_san, sm = "RR", comb.random = T,
                  reference.group = "unimproved")
  net1
  forest(net1, ref="unimproved")


#Water
  #network meta-analysis
  dat.root <- "J:/WORK/05_risk/risks/wash_water/data/rr/meta_analysis/"
  dt <- fread(paste0(dat.root, "water_rr.csv"))
  dt <- dt[, log_rr := log(effectsize)]
  dt <- dt[, log_se := sqrt((standard_error^2) * (1/effectsize)^2)]
  #dt <- dt[added_2016 == 0,]
  dt <- dt[reference !="Capuno J3"]
  dt <- dt[reference !="Capuno J4"]
  dt_source <- dt[intervention_clean == "improved" | intervention_clean == "piped" |
                  intervention_clean == "hq_piped" |intervention_clean == "solar" |
                  intervention_clean == "filter", c("log_rr", 
                                                      "log_se",
                                                      "standard_error", 
                                                      "intervention_clean", 
                                                      "control_clean",
                                                      "reference")]
  
  net1 <- netmeta(log_rr, log_se, intervention_clean, control_clean,
                  reference, data = dt_source, sm = "RR", comb.random = T, 
                  reference.group = "unimproved")
  net1
  forest(net1, ref="unimproved")
  
  netconnection(control_group, intervention_clean, reference, data = dt)
 
## Scrap ##
  # #Solar/chlorine treatment-basic meta-regression
  # dt <- fread("J:/temp/wgodwin/meta_analysis/wash/water_rr1.csv")
  # dt <- dt[, log_rr := log(effectsize)]
  # dt <- dt[, log_se := sqrt((standard_error^2) * (1/effectsize)^2)]
  # dt_solar <- dt[intervention_clean == "solar",]
  # meta_solar <- metagen(log_rr, log_se, data = dt_solar,  backtransf = T, sm= "RR")
  # forest(meta_solar)
  # rr <- exp(meta_solar$TE.random)
  # lower <- exp(meta_solar$lower.random)
  # upper <- exp(meta_solar$upper.random)
  # 
  # #Filter/boil treatment- basis meta-regression
  # dt <- fread("J:/temp/wgodwin/meta_analysis/wash/water_rr1.csv")
  # dt <- dt[, log_rr := log(effectsize)]
  # dt <- dt[, log_se := sqrt((standard_error^2) * (1/effectsize)^2)]
  # dt_filter <- dt[intervention_clean == "filter",]
  # meta_filter <- metagen(log_rr, standard_error, data = dt_filter, backtransf = T, sm = "RR", comb.random = T)
  # filter_rr <- exp(meta_filter$TE.random)
  # filter_lower <- exp(meta_filter$lower.random)
  # filter_upper <- exp(meta_filter$upper.random)
  # 