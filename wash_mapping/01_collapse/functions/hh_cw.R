######################################################
##### HOUSEHOLD SIZE CROSSWALKING CODE ###############

cw <- function(data, debug = F, var_family = indi_fam) {
  
  if (debug) {broswer()}
  library(dplyr)
  
  # Remove all missing hh_size obs
  data <- filter(data, !is.na(hh_size))
  
  # Duplicate data into reference and comparison sets with dummy encoding
  data_1 <- data %>% mutate(cw = 1)
  
  data_2 <- data %>% mutate(cw = 0)
  data_2$hh_size <- 1
  data_2$id_short <- data_2$id_short + max(data_1$id_short)
  
  data <- rbind(data_1, data_2)
  
  if (var_family == 'water') {
    data <- rename(data, indi = piped) }
  
  if (var_family == 'sani') {
    data <- rename(data, indi = od) }
  
  
  # Aggregate data into clusters
  data <- data %>% mutate(wt_indi = hhweight*indi*hh_size, wt_denom = hhweight*hh_size) %>% 
          group_by(id_short, cw) %>% 
          summarize(wtavg_indi = sum(wt_indi, na.rm = T)/sum(wt_denom, na.rm = T),
              total_hh = sum(hh_size)) 
  
  # Fit a binomial model and get a ratio estimate for crosswalking missing household sizes
  model <- glm(data = data, formula = wtavg_indi ~ cw, family = binomial(link = 'logit'),
              weights = data$total_hh)
  ratio <- model$coefficients['cw']
  ratio <- exp(ratio)
  return(ratio)
}

hh_cw <- function(data, debug = F, var_family = indi_fam) {
  
  if (debug) {browser()}
  
  if (length(data[which(is.na(data$hh_size)),1]) < 1) {
    print("No missing hh_sizes!")
    return(data)
  } else {
    
  library(dplyr)
  
  # Split data into urban and rural
  urban <- filter(data, urban == 1)
  rural <- filter(data, urban == 0)
  overall <- data
  
  # Obtain urban-rural specific ratios and overal ratios in case U/R is
  # missing
  u_ratio <- cw(urban)
  r_ratio <- cw(rural)
  o_ratio <- cw(overall)
  
  # Plug in ratios into hh_sizes based on urban-rural specificity
  results <- data.frame(urban = c(1,0,2), ratio = c(u_ratio,r_ratio,o_ratio))
  data$hh_size[which(is.na(data$hh_size) &
                 data$urban == 1)] <- u_ratio
  data$hh_size[which(is.na(data$hh_size) &
                 data$urban == 0)] <- r_ratio
  data$hh_size[which(is.na(data$hh_size) &
                 is.na(data$urban))] <- o_ratio
  
  # Print ratios
  print(results)
  return(data)
  
  }
}