# Clear environment
rm(list = ls())

# Diagnostics for WaSH exposure data
library(data.table)
library(ggplot2)

#Set root for windows or cluster
root <- ifelse(Sys.info()[1]=="Windows", "J:/", "/snfs1/")

#Pull in pt and poly data
piped <- fread(paste0(root, "WORK/05_risk/risks/wash_water/data/exp/01_data_audit/tabulated_2017_09_26.csv"))
piped <- piped[ ,.(nid, iso3, survey_series, year_start, piped, se_piped)]
piped_noimp <- fread(paste0(root, "WORK/05_risk/risks/wash_water/data/exp/01_data_audit/tabulated_2017_09_26_noimput_cw.csv"))
piped_noimp <- piped_noimp[ ,.(nid, iso3, survey_series, year_start, piped, se_piped)]
piped_noimp_cw <- fread(paste0(root, "WORK/05_risk/risks/wash_water/data/exp/01_data_audit/tabulated_2017_09_26_noimput_nocw.csv"))
piped_noimp_cw <- piped_noimp_cw[ ,.(nid, iso3, survey_series, year_start, piped, se_piped)]
piped_poly <- fread(paste0(root, "WORK/05_risk/risks/wash_water/data/exp/01_data_audit/tabulated_2017_09_27_poly.csv"))
piped_poly <- piped_poly[ ,.(nid, iso3, survey_series, year_start, piped, se_piped)]
piped_poly_noimp <- fread(paste0(root, "WORK/05_risk/risks/wash_water/data/exp/01_data_audit/tabulated_2017_09_28_poly_noimpute.csv"))
piped_poly_noimp <- piped_poly_noimp[ ,.(nid, iso3, survey_series, year_start, piped, se_piped)]

#Pull in GBD 2015 to compare
piped_old <- fread(paste0(root, "temp/wgodwin/gpr_input/run1/wash_water_piped3.csv"))
piped_old <- piped_old[, .(nid, ihme_loc_id, data, year_id, variance)]
piped_old <- piped_old[!is.na(data),]
setnames(piped_old, "ihme_loc_id", "iso3")

#Merge together files in prep for visualizing
setnames(piped_noimp, c("piped", "se_piped"), c("piped_noimp_var", "se_noimp_var"))
comp_imp_dt <- merge(piped, piped_noimp, by = c("nid", "year_start", "iso3", "survey_series"), all = F)
plot(comp_imp_dt$piped, comp_imp_dt$piped_noimp_var)

setnames(piped_noimp_cw, c("piped", "se_piped"), c("piped_noimp_var", "se_noimp_var"))
comp_imp_cw_dt <- merge(piped, piped_noimp_cw, by = c("nid", "year_start", "iso3", "survey_series"), all = F)
plot(comp_imp_cw_dt$piped, comp_imp_cw_dt$piped_noimp_var)


#Create data coverage map from point and poly datasets
source("J:/DATA/SHAPE_FILES/GBD_geographies/master/GBD_2015/inset_maps/noSubs/GBD_WITH_INSETS_MAPPING_FUNCTION.r")
both <- rbind(piped, piped_poly)
both[, mapvar := 1]
setnames(both, "iso3", "ihme_loc_id")
both <- aggregate(mapvar ~ ihme_loc_id, data = both, FUN = sum)
gbd_map(data = both, limits = c(1,5,10,15,20,25,30), 
        title = "Piped Water Input Data Coverage",
        fname = paste0(root, "WORK/05_risk/risks/wash_water/data/exp/01_data_audit/piped_data_coverage.pdf"))

#deal with sources that erroneously appear in both point and polygon datasets by deleting the polygon sources
dt_overlap <- merge(piped, piped_poly, by= c("nid", "iso3"), all = F)
ex_nids <- dt_overlap$nid
piped_poly <- piped_poly[!piped_poly$nid %in% ex_nids,]
piped_poly_noimp <- piped_poly_noimp[!piped_poly_noimp$nid %in% ex_nids,]

# append togther point and polygon data for means that used imputation and means that didn't
both <- rbind(piped, piped_poly)
both_noimp <- rbind(piped_noimp_cw, piped_poly_noimp)

# merge together imputed and non-imputed aggregated values
dt_scatter <- merge(both, both_noimp, by = c("nid", "iso3", "year_start", "survey_series"))

#generate pct change var and label for plotting code to only label points with >5% change
dt_scatter[, pct_change := abs((se_piped.y-se_piped.x)/se_piped.x)*100]
dt_scatter[, ihme_loc_id_lab := ifelse(pct_change<=5,"", iso3)]
dt_scatter <- dt_scatter[se_piped.x < .2,] #excluding one source w/ really high variance that's messing with plot axis

#plot
gg <- ggplot(dt_scatter,
             aes(x=se_piped.x,
                 y=se_piped.y,
                 label=ihme_loc_id_lab)) +
      geom_point() +
      geom_text(aes(label=ihme_loc_id_lab),hjust=0, vjust=0) +
      labs(x = "Variance w imputation",
          y = "Variance w/o imputation")

#merge with 2015 piped estimates
dt_scatter_old <- merge(piped_poly, piped_old, by = c("nid", "iso3"), all = F)
dt_scatter_old[, pct_change := abs((piped-data)/data)*100]
dt_scatter_old[, ihme_loc_id_lab := ifelse(pct_change<=20,"", iso3)]
dt_scatter_old <- dt_scatter_old[piped!= 0,]

#plot
gg <- ggplot(dt_scatter_old,
             aes(x=data,
                 y=piped,
                 label=ihme_loc_id_lab)) +
  geom_point() +
  geom_text(aes(label=ihme_loc_id_lab),hjust=0, vjust=0) +
  labs(x = "Mean in GBD 2016",
       y = "Mean from latest tabulation")

##########################
#########Exploration######
##########################
sdi <- fread("C:/Users/wgodwin/Desktop/sdi.csv")
imp <- fread("J:/temp/wgodwin/gpr_input/run1/wash_water_imp_bra_subnat.csv")
locs <- fread("J:/temp/wgodwin/diagnostics/loc_metadata.csv")
locs <- locs[, .(location_id, location_name, level)]
sdi <- merge(sdi, locs, by="location_name")
dt <- merge(imp, sdi, by = c("location_id", "year_id"))
setnames(dt, "mean_value", "sdi")
nat_dt <- dt[level == 3]

#Plot lowess
plot(nat_dt$sdi, nat_dt$data, main = "Lowess Improved Water")
lines(lowess(nat_dt$sdi, nat_dt$data))
lines(lowess(nat_dt$sdi, nat_dt$data, f= .2), col = 3)
lines(lowess(nat_dt$sdi, nat_dt$data, f= .1), col = 4)
lines(lowess(nat_dt$sdi, nat_dt$data, f= .5), col = 5)

#Improved sanitation
imp_san <- fread("J:/temp/wgodwin/gpr_input/run1/wash_sanitation_imp_ubcov.csv")
dt <- merge(imp_san, sdi, by = c("location_id", "year_id"))
setnames(dt, "mean_value", "sdi")
nat_dt <- dt[level == 3]
plot(nat_dt$sdi, nat_dt$data, main = "Lowess Improved Sanitation")
lines(lowess(nat_dt$sdi, nat_dt$data))
