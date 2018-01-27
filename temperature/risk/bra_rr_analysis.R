#Purpose: Brazil temperature RR analysis
#source('/snfs2/HOME/wgodwin/temperature/era_interim/municipality_prep_erac.R', echo = T)
rm(list=ls())
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

#load libraries
# for(ppp in c('parallel', 'rgdal', 'sp', 'raster','ncdf4','data.table', 'ggplot2')){
#   library(ppp, lib.loc = pack_lib, character.only =T)
# }

#install pacman library
#if("pacman" %in% rownames(installed.packages())==FALSE){
#  library(pacman,lib.loc="/homes/wgodwin/R/x86_64-pc-linux-gnu-library/3.3")
#}

# load packages, install if missing  
pack_lib = '/snfs2/HOME/wgodwin/R'
.libPaths(pack_lib)
pacman::p_load(data.table, fst, ggplot2, parallel, magrittr, maptools, raster, rgdal, rgeos, sp, splines, stringr, RMySQL, snow, ncdf4)

#read in and append temperature and COD data
bra_cod <- paste0(j, "temp/wgodwin/temperature/cod/bra/years")
cod_dt <- rbindlist(lapply(list.files(bra_cod, full.names = T), fread), fill = T)
bra_temp <- paste0(j, "temp/wgodwin/temperature/exposure/prepped_data/bra/era_interim")
temp_dt <- rbindlist(lapply(list.files(bra_temp, full.names = T), fread))

#Merge them together
dt <- merge(cod_dt, temp_dt, by = c("date", "adm2_code"), all.x = T)
