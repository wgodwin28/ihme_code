run "/home/j/WORK/10_gbd/00_library/functions/get_estimates.ado"
get_estimates, gbd_team(epi) gbd_id(1559) measure_ids(5) age_group_ids(2) status(best) clear
save "/home/j/temp/wgodwin/sga/data/04_get_estimates/estimates_wk_32_36", replace


/*
1557, 1558 and 1559
'prevalence of neonatal preterm birth <28 wks', 'prevalence of neonatal preterm birth 28-<32 wks', 
 and 'prevalence of neonatal preterm birth 32-<37 wks'