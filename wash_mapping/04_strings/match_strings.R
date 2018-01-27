library(magrittr)
library(plyr)
j <- ifelse(Sys.info()[1]=="Windows", "J:/", "/snfs1/")

most_recent_water <- paste0(j, "WORK/11_geospatial/wash/definitions/w_source_defined_updated_2017_07_21.csv")
most_recent_wother <- paste0(j, "WORK/11_geospatial/wash/definitions/w_other_defined_updated_2017_07_21.csv")
most_recent_toilet <- paste0(j, "WORK/11_geospatial/wash/definitions/t_type_defined_updated_2017_07_21.csv")

w <- read.csv(most_recent_water, stringsAsFactors=F, encoding = 'windows-1252')
w_o <- read.csv(most_recent_wother, stringsAsFactors=F, encoding = 'windows-1252')
t <- read.csv(most_recent_toilet, stringsAsFactors=F, encoding = 'windows-1252')



most_recent_extract <- paste0(j, "LIMITED_USE/LU_GEOSPATIAL/geo_matched/wash/packaged_dataset_08_10_2017.Rdata")
load(most_recent_extract)
#called packaged

new_w <- packaged$w_source_drink %>% unique
new_wo <- packaged$w_source_other %>% unique
new_t <- packaged$t_type %>% unique

new_w <- new_w[!(new_w %in% w$string)]
new_wo <- new_wo[!(new_wo %in% w_o$string) & !is.na(new_wo)]
new_t <- new_t[!(new_t %in% t$string) & !is.na(new_t)]

new_w <- as.data.frame(new_w, col.names="string", stringsAsFactors=F)
new_wo <- as.data.frame(new_wo, col.names="string", stringsAsFactors=F)
new_t <- as.data.frame(new_t, col.names="string", stringsAsFactors=F)
colnames(new_w)[1] <- "string"
colnames(new_wo)[1] <- "string"
colnames(new_t)[1] <- "string"

w <- rbind.fill(w, new_w)
w_o <- rbind.fill(w_o, new_wo)
t <- rbind.fill(t, new_t)

today <- Sys.Date() %>% gsub(pattern="-", replace="_")

write.csv(w, paste0(j, "WORK/11_geospatial/wash/definitions/w_source_defined_", today, ".csv"), row.names=F, na="")
write.csv(w_o, paste0(j, "WORK/11_geospatial/wash/definitions/w_other_defined_", today, ".csv"), row.names=F, na="")
write.csv(t, paste0(j, "WORK/11_geospatial/wash/definitions/t_type_defined_", today, ".csv"), row.names=F, na="")
