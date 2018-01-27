setwd('/share/code/geospatial/adesh/mbg/wash')
###

parallel <- c()
for (i in 1:3) {
  script <- "nohup_child.R"
  r_shell <- "r_shell.sh"
  args <- i
  parallel[i] <- paste("nohup Rscript", script, args, " &")
}
parallel[4] <- "pwd"
for (i in 1:4) {
  system("cd /share/code/geospatial/adesh/mbg/wash")
  system(parallel[i])
}
