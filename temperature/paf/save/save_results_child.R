# Author: WG
# Date: 02/16/2018
# Purpose: Child script for save_results
#********************************************************************************************************************************

#----CONFIG----------------------------------------------------------------------------------------------------------------------
# clear memory
rm(list=ls())

#Set incoming arg objects
arg <- commandArgs()[-(1:3)]
heat <- as.numeric(arg[1])
dir <- arg[2]
me_id <- as.numeric(arg[3])
best <- arg[4]
descript <- arg[5]
#years <- as.numeric(arg[6])

print(heat)
print(dir)
print(me_id)
print(best)
print(descript)
#Run save_results
source(paste0("/home/j/temp/central_comp/libraries/current/r/save_results_risk.R"))
save_results_risk(input_dir = dir,
                  input_file_pattern = "paf_{measure}_{location_id}_{year_id}_{sex_id}_{cause_id}.csv",
                  modelable_entity_id = me_id,
                  description = "PAFs with BRA RR curves for most causes",
                  risk_type = "paf",
                  measure_id = "4",
                  year_id = c(1990,2005,2017),
                  mark_best= best)

#END