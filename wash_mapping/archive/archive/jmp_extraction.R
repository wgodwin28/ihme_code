library(dplyr)

setwd("C:/Users/adesh/Documents/WASH/jmp_files/csv/water")

files <- list.files()
master_data_list <- list()

for (j in files) {
test <- read.csv(j, stringsAsFactors = F, header = F)
  

# Get Country
data_list <- list()

for (i in 0:(floor((ncol(test))/6)-1)) {
  sub_dim <- c(1,6)
  sub_dim <- sub_dim+(6*i)
  test2 <- test[,sub_dim[1]:sub_dim[2]]
  
  test3_start <- ifelse("Urban" %in% test2[,4], which(test2[,4] == "Urban"), 4)
  test3 <- as.data.frame(test2[(test3_start+1):(test3_start+73),], stringsAsFactors = F)
  names(test3) <- test2[4,]
  test3[,4] <- as.numeric(test3[,4])
  test3[,5] <- as.numeric(test3[,5])
  test3[,6] <- as.numeric(test3[,6])
  test3[,4:6][is.na(test3[,4:6])] <- 0
  
  svy_nm <- test2[2,1]
  svy_yr <- test2[3,4]
  cntry <- test2[1,4]
  used_imp_u <- test2[91,4]
  used_pipe_u <- test2[92,4]
  used_surface_u <- test2[93,4]
  used_imp_r <- test2[91,5]
  used_pipe_r <- test2[92,5]
  used_surface_r <- test2[93,5]
  
  message(paste(cntry, svy_yr, svy_nm))
  
  w_pipe_u  <- if(test3[2,4] != 0) {test3[2,4]} else {sum(test3[3:4,4])}
  w_imp_u <- sum(
                 ifelse(sum(test3[5:6,4]) == 0, 
                  ifelse(test3[1,4] == 0, 0, (test3[1,4] - w_pipe_u)),
                  sum(test3[5:6,4])),
    
                 test3[c(22,30,42,54),4],
    
                 ifelse(test3[51,4] == 0, 
                   ifelse(test3[50,4] == 0, 0, (test3[50,4] - test3[52,4])),
                   test3[51,4]),
    
                 ifelse(test3[64,4] == 0, sum(test3[65:66,4]), test3[64,4])
                )
  
  
  w_unimp_u <- sum(
                ifelse(test3[34,4] == 0, 
                  ifelse(test3[26,4] == 0, 0, (test3[26,4] - test3[30,4])),
                  test3[34,4]),
    
                ifelse(test3[46,4] == 0, 
                  ifelse(test3[38,4] == 0, 0, (test3[38,4] - test3[42,4])),
                  test3[46,4]),
    
                ifelse(test3[55,4] == 0, 
                       ifelse(test3[53,4] == 0, 0, (test3[53,4] - test3[52,4])),
                       sum(test3[55,4])),
                
                ifelse(test3[55,4] == 0, sum(test3[65:66,4]), test3[64,4]),
                
                ifelse(test3[67,4] == 0, sum(test3[68:69,4]), test3[67,4])
                )
  
  w_surface_u <- if(test3[56,4] != 0) {test3[56,4]} else {sum(test3[57:63,4])}
  w_total_u <- w_pipe_u + w_imp_u + w_unimp_u + w_surface_u
  
  w_pipe_u_adj <- (w_pipe_u/w_total_u)*100
  w_imp_u_adj <- (w_imp_u/w_total_u)*100
  w_unimp_u_adj <- (w_unimp_u/w_total_u)*100
  w_surface_u_adj <- (w_surface_u/w_total_u)*100
  w_total_u_adj <- w_pipe_u + w_imp_u + w_unimp_u + w_surface_u
  
  w_pipe_r  <- if(test3[2,5] != 0) {test3[2,5]} else {sum(test3[3:4,5])}
  w_imp_r <- sum(
                ifelse(sum(test3[5:6,5]) == 0, 
                  ifelse(test3[1,5] == 0, 0, (test3[1,5] - w_pipe_r)),
                  sum(test3[5:6,5])),
    
                  test3[c(22,30,42,54),5],
    
                ifelse(test3[51,5] == 0, 
                  ifelse(test3[50,5] == 0, 0, (test3[50,5] - test3[52,5])),
                  test3[51,5]),
    
                ifelse(test3[64,5] == 0, sum(test3[65:66,5]), test3[64,5])
                )
  
  
  w_unimp_r <- sum(
                  ifelse(test3[34,5] == 0, 
                    ifelse(test3[26,5] == 0, 0, (test3[26,5] - test3[30,5])),
                    test3[34,5]),
    
                  ifelse(test3[46,5] == 0, 
                    ifelse(test3[38,5] == 0, 0, (test3[38,5] - test3[42,5])),
                    test3[46,5]),
    
                  test3[52,5],
                  
                  ifelse(test3[55,5] == 0, 
                         ifelse(test3[53,5] == 0, 0, (test3[53,5] - test3[52,5])),
                         sum(test3[55,5])),
                  
                  ifelse(test3[67,5] == 0, sum(test3[68:69,5]), test3[67,5])
                  )
  
  w_surface_r <- if(test3[56,5] != 0) {test3[56,5]} else {sum(test3[57:63,5])}
  w_total_r <- w_pipe_r + w_imp_r + w_unimp_r + w_surface_r
  
  w_pipe_r_adj <- (w_pipe_r/w_total_r)*100
  w_imp_r_adj <- (w_imp_r/w_total_r)*100
  w_unimp_r_adj <- (w_unimp_r/w_total_r)*100
  w_surface_r_adj <- (w_surface_r/w_total_r)*100
  w_total_r_adj <- w_pipe_r_adj + w_imp_r_adj + w_unimp_r_adj + w_surface_r_adj
  
  obs <- c(svy_yr, cntry, svy_nm, w_pipe_u_adj, w_imp_u_adj, w_unimp_u_adj, w_surface_u_adj,
           w_pipe_r_adj, w_imp_r_adj, w_unimp_r_adj, w_surface_r_adj, used_imp_u, 
           used_pipe_u, used_surface_u, used_imp_r, used_pipe_r, used_surface_r, j, i)
  
  data_list[[length(data_list)+1]] <- obs
}

dataset <- do.call(rbind, data_list)
master_data_list[[length(master_data_list)+1]] <- dataset

}

master_dataset <- do.call(rbind, master_data_list)
master_dataset <- as.data.frame(master_dataset, stringsAsFactors = F)
names(master_dataset) <- c('year','country','survey',"w_pipe_u_adj", "w_imp_u_adj", "w_unimp_u_adj", "w_surface_u_adj",
                    "w_pipe_r_adj", "w_imp_r_adj", "w_unimp_r_adj", "w_surface_r_adj", "used_imp_u", 
                    "used_pipe_u", "used_surface_u", "used_imp_r", "used_pipe_r", "used_surface_r", "file","subset")

# filter out observations that don't have survey variable defined
master_dataset2 <- filter(master_dataset, !is.na(survey))
master_dataset2 <- filter(master_dataset, survey != "")

for (i in 12:14) {
  print(names(master_dataset2)[i])
  print(unique(master_dataset2[,i]))
}

###### URBAN ####
# filter out datasets that cannot be used for urban
master_dataset3 <- master_dataset2[grep("yes",master_dataset2$used_imp_u, ignore.case = T),]
master_dataset3 <- master_dataset3[grep("yes",master_dataset3$used_pipe_u, ignore.case = T),]
master_dataset3 <- master_dataset3[grep("yes",master_dataset3$used_surface_u, ignore.case = T),]
for (i in 4:11) {
  master_dataset3[,i] <- as.numeric(master_dataset3[,i])
}
## dropping american samoa census of 2001
master_dataset3 <- filter(master_dataset3, !is.na(master_dataset3$w_imp_u_adj))
for (i in 4:11) {
  print(mean(master_dataset3[,i]))
}

###### RURAL ####
# filter out datasets that cannot be used for rural
master_dataset4 <- master_dataset2[grep("yes",master_dataset2$used_imp_r, ignore.case = T),]
master_dataset4 <- master_dataset4[grep("yes",master_dataset4$used_pipe_r, ignore.case = T),]
master_dataset4 <- master_dataset4[grep("yes",master_dataset4$used_surface_r, ignore.case = T),]
for (i in 4:11) {
  master_dataset4[,i] <- as.numeric(master_dataset4[,i])
}
## dropping american samoa census of 2001
master_dataset4 <- filter(master_dataset4, !is.na(master_dataset4$w_imp_u_adj))
for (i in 4:11) {
  print(mean(master_dataset4[,i]))
}