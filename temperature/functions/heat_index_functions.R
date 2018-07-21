mean_lag_30 <- function(i) { 
  is.near <- as.numeric(data$date[i] - data$date) >= 0 & as.numeric(data$date[i] - data$date) < 30
  mean(data$tmean[is.near], na.rm = T)
} 

mean_lag_3 <- function(i) { 
  is.near <- as.numeric(data$date[i] - data$date) >= 0 & as.numeric(data$date[i] - data$date) < 3
  mean(data$tmean[is.near], na.rm = T)
}