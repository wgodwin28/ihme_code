dt <- data.2015.oap[!(outcome=="incidence" & cause %like% "cvd"), list(nid, study, cause, outcome, conc_mean, conc_sd, conc_5, conc_95, rr, rr_lower, rr_upper, conc_increment, deaths, sample_size)]

old.causes <- c('cvd_ihd',
                'cvd_stroke',
                'resp_copd',
                'neo_lung',
                'lri')   

replacement.causes <- c('IHD', 
                        "CEV",
                        "COPD",
                        "LC",
                        "ALRI")

# then pass to your custom function
dt <- findAndReplace(dt,
                    old.causes,
                    replacement.causes,
                    "cause",
                    "cause")

dt[, Study := simpleCap(study), by=study]
dt[!is.na(conc_sd), conc_mean_sd := paste0(conc_mean, " (", conc_sd, ")")]
dt[is.na(conc_sd), conc_mean_sd := conc_mean]
dt[, conc_5_95 := paste0(conc_5, "/", conc_95)]
dt[!is.na(deaths), deaths_string :=  paste0("N = " , prettyNum(deaths, big.mark=",", scientific = F))]
dt[is.na(deaths), deaths_string := ""]
dt[, rr_combined := paste0(rr, " (", rr_lower, "-", rr_upper, "); ", deaths_string)]

dt[is.na(conc_increment), conc_increment := 10]

dt[, sample_string := prettyNum(sample_size, big.mark=",", scientific = F)]

lite <- dt[, list(cause, nid, Study, sample_string, conc_mean_sd, conc_5_95, rr_combined, conc_increment, outcome)]

cast <- dcast(lite, ... ~ cause, value.var = "rr_combined")

setnames(cast, c("nid", "sample_string"), c("NID", "Sample Size"))

citations <- get_citations() %>% as.data.table
cite <- citations[, list(nid, field_citation_value)]
cited <- merge(cast, cite, by.x="NID", by.y="nid") %>% as.data.table
cited[Study=="Canadian National Enhanced Cancer Surveillance System Cohort (NECSS)", 
      field_citation_value := "Hystad P, Demers PA, Johnson KC, Carpiano RM, Brauer M. Long-term residential exposure to air pollution and lung cancer risk. Epidemiology. 2013; 24(5): 762-72."]

write.csv(cited, file.path(graphs.dir, paste0("ier_input_table_all_outcomes.csv")))
