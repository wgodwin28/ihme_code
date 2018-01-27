test <- commandArgs(trailingOnly = T)
indicator <- test[1]

setwd('/homes/adesh/nohup_test')
a <- paste("nohup worked!", indicator)
writeLines(a, paste0("test_", indicator[1], ".txt"))