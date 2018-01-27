#Housekeeping
rm(list = ls())

pacman::p_load(data.table, lme4, magrittr, MASS)
GBDdata <- as.data.table(read.csv("J:/temp/wgodwin/matt_hap/PM_lmer_input.csv",header=T,quote = "",sep=","))
location_hier <- fread("J:/temp/wgodwin/matt_hap/location_hierarchy.csv")

#convert stove type from wide to long
GBDStove=reshape(GBDdata, 
                 varying = c("traditional", "ics", "gasstove"), 
                 v.names = "stove_yes",
                 timevar = "stovetype", 
                 times = c("traditional", "ics", "gasstove"), 
                 direction = "long")
GBDStove1=subset(GBDStove, stove_yes==1)


GBDFuel=reshape(GBDStove1,
                varying = c("wood", "gas","kerosene","dung","coal","charcoal","crop_residue","biomass"), 
                v.names = "fuel_yes",
                timevar = "fueltype", 
                times = c("wood", "gas","kerosene","dung","coal","charcoal","crop_residue","biomass"),
                new.row.names=1:(8*nrow(GBDStove)),
                direction = "long")

GBDFuel1=subset(GBDFuel, fuel_yes==1)


GBDHierarchy=merge(GBDFuel1, location_hier, by=c("location_id","super_region_id","region_id"))

#Transformations and prep
  GBDdata <- GBDFuel[, log_pm := log(pm_mean)]
# Model Calls
# region random effect. Random slope on stove_type?
  re_mod <- lmer(log_pm~stovetype+fueltype+rural+(1+stovetype|region_name),data=GBDdata)
  summary(re_mod)
  
# super region and region re
  lmer(log_pm~stovetype+fueltype+rural+(1+stovetype|region_name)+(1+stovetype|super_region_name),data=GBDdata)

