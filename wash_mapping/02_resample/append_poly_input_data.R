setwd('J:/WORK/11_geospatial/wash/data/resamp/water/piped/2017-09-06')

mydat <- lapply(list.files(), read.csv, stringsAsFactors = F)
mydat <- do.call(rbind, mydat)

glimpse(mydat)

mydat <- mydat %>% select(-X, -lat.y, -long.y) %>%
          rename(latitude = lat.x, longitude = long.x,
            N = total_hh, year = year_start,
            country = iso3) %>% 
          mutate(w_piped = round(piped*N)) %>%
          mutate(N = round(N)) %>%
          rename(prop = piped) %>%
          glimpse()

mydat2 <- read.csv('J:/WORK/11_geospatial/10_mbg/input_data/w_piped.csv',
                   stringsAsFactors = F)

mydat2 <- select(mydat2, -X)
mydat3 <- rbind(mydat2, mydat)
write.csv(mydat3, 'J:/WORK/11_geospatial/10_mbg/input_data/w_piped.csv')
