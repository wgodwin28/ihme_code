load(file = "J:/WORK/11_geospatial/wash/resampling/water/piped/master_pt.RData")
load(file = "J:/WORK/11_geospatial/wash/resampling/water/piped/master_poly.RData")


source('mbg_central/misc_functions.R')
coverage_maps <- graph_data_coverage_values(df = coverage_data,
                                            var = 'had_diarrhea',
                                            out_file = "/snfs1/temp/ngraetz/test.png",
                                            title = 'Diarrhea',
                                            year_min = '1998',
                                            year_max = '2016',
                                            year_var = 'start_year',
                                            region = 'south_asia',
                                            sum_by = 'n',
                                            cores = 10,
                                            indicator = 'had_diarrhea',
                                            high_is_bad = TRUE,
                                            return_maps = TRUE,
                                            legend_title = "Prevalence")

data_poly_plot <- ungroup(data_poly)
data_poly_plot <- select(data_poly, shapefile, location_code, year_start,
                         mbg_indic_bin, latitude, longitude, N, ihme_loc_id, poly_id)
data_poly_plot <- rename(data_poly_plot, year = year_start, country = ihme_loc_id)
data_poly_plot <- mutate(data_poly_plot, svy_id = substr(poly_id, 1, 10))
data_poly_plot <- data_poly_plot[,c(1:8,10)]

data_pt_plot <- select(data_pt, lat, long, year, mbg_indic_bin, N, country, cluster_id)
data_pt_plot <- rename(data_pt_plot, latitude = lat, longitude = long)
data_pt_plot$shapefile <- NA
data_pt_plot$location_code <- NA
data_pt_plot <- mutate(data_pt_plot, svy_id = substr(cluster_id, 1, 10))
data_pt_plot <- select(data_pt_plot, -cluster_id)


data_plot <- rbind(data_poly_plot, data_pt_plot)
data_plot <- rename(data_plot, w_piped = mbg_indic_bin)

save(data_plot, file = 'H:/data_cov_plot.RData')


source('mbg_central/misc_functions.R')
coverage_maps <- graph_data_coverage_values(df = data_plot,
                                            var = 'w_piped',
                                            out_file = "/homes/adesh/test.png",
                                            title = 'W_Piped',
                                            year_min = '1998',
                                            year_max = '2016',
                                            year_var = 'year',
                                            region = 'africa',
                                            sum_by = 'N',
                                            cores = 10,
                                            indicator = 'w_piped',
                                            high_is_bad = TRUE,
                                            return_maps = TRUE,
                                            legend_title = "Prevalence")
