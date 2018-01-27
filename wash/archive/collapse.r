# clear environment
rm(list=ls(all=TRUE))

library(data.table)
library(reshape2)
library(plyr)
library(survey)
library(haven)
library(dplyr)

if (Sys.info()[1] == "Linux") {
  root <- "/home/j" 
} else {
  root <- "J:"
}

#load paths
dir <- "J:/temp/wgodwin/wash_exposure/02_clean/"
path <- "IND/MACRO_DHS_IND_1992_1993_HH_19787.dta"

#import data
# dt <- as.data.table(read_dta(paste0(dir, path)))
dt <- fread(paste0(dir, path, ".csv"))

#specify survey object
svy_obj <- svydesign(id = ~ihme_psu, strata = ~ihme_strata, weights = ~ihme_pweight, data = dt)

#generate means
vars <- c("w_treat", "w_boil", "w_filter", "w_cloth", "w_solar", "w_bleach")
for(i in vars) {  
  mean[i] <- dt[, svymean(i, svy_obj, na.rm = T)]
}


test_vars <- dt2[,c("w_treat", "mins_ws"), with = F]
head(dt[,w_treat])
dt2 <- dt[, lapply(.SD, mean(w_treat, na.rm = T)), .SDcols=c("w_treat", "w_boil")]
mean(dt2$w_treat)
dt2 <- dt[w_treat == 1 | w_treat == 0, ]
svymean(dt2$w_treat, svy_obj)
lapply(test_vars, svymean)
lapply(test_vars, mean, na.rm = T)
for(i in vars) {
  dt[i == NA, i := 0]
}

for(i in vars) {  
mean[i] <- dt[, svymean(i, svy_obj, na.rm = T)]
}

dt_vars <- dt[, c("w_treat", "w_boil", "w_filter", "w_cloth", "w_solar", "w_bleach"), with=F]
count <- dt[w_treat == NA, length(w_treat)]
dt <- dt[, count_treat := count]
count
head(dt)
mean(dt$w_treat, )
df[sex== "M", sex_id := 1]

#######################################################################################################################################

collapse_list <- function(df, vars) {
  
  ## Detect meta
  out.meta <- setdiff(names(df), vars)
  
  ## Binary for whether or not variable exists and is not completely missing
  out.vars <- sapply(vars, function(x) ifelse(x %in% names(df) & nrow(df[!is.na(x)]) > 0, 1, 0)) %>% t %>% data.table
  
  return(cbind(out.meta, out.vars))
}

#### Run function
vars <- c("improved_water", "piped", "w_treat", "w_boil")
collapse_list(dt2, vars)

#######################################################################################################################################

setup_design <- function(df, var) {
  
  ## Set options
  
  ## conservative adjustment recommended by Thomas Lumley for single-PSU strata.  Centers the data for the single-PSU stratum around the sample grand mean rather than the stratum mean
  options(survey.lonely.psu = 'adjust')
  
  ## conservative adjustment recommended by Thomas Lumley for single-PSU within subpopulations.  Need to find out more about what exactly this is doing.
  options(survey.adjust.domain.lonely = TRUE)
  
  ## Check for survey design vars
  check_list <- c("ihme_strata", "ihme_psu", "ihme_pweight")
  for (i in check_list) {
    ## Assign to *_formula the variable if it exists and nonmissing, else NULL
    assign(paste0(i, "_formula"),
           ifelse(i %in% names(df) & nrow(df[!is.na(i)]) > 0, paste("~", i), NULL) %>% as.formula
    ) 
  }
  
  ## Set svydesign
  return(svydesign(id = ihme_psu_formula, weight = ihme_pweight_formula, strat = ihme_strata_formula, data = df[!is.na(var)], nest = TRUE))
  
}

#### Run function
setup_design(dt, vars)

#######################################################################################################################################

collapse_by <- function(df, var, by_vars) {
  
  ## Subset to frame where data isn't missing
  df.c <- copy(df[!is.na(get(var)) & !is.na(ihme_strata) & !is.na(ihme_psu) & !is.na(ihme_pweight)])
  
  ## Setup design
  design <- setup_design(df.c, var)
  
  ## Setup by the by call as a formula
  by_formula <- as.formula(paste0("~", paste(by_vars, collapse = "+")))
  
  ## Calculate mean and standard error by by_var(s).  Design effect is dependent on the scaling of the sampling weights
   est = svyby(~get(var), by_formula, svymean, design = design, deff = "replace", na.rm = T, drop.empty.groups = TRUE, keep.names = F, multicore=TRUE)
  # est = svymean(~get(var), design, na.rm=T, names=T)
    setnames(est, c("get(var)", "DEff.get(var)"), c("mean", "deff"))
  
  ## Calculate number of observations, number of clusters, strata
  meta <- df.c[, list(ss = length(which(!is.na(get(var)))), 
                      nclust = length(unique(ihme_psu)), 
                      nstrata= length(unique(ihme_strata)),
                       var = var
   ), by = by_vars]
  
  ## Combine meta with est
  out <- merge(est, meta, by=by_vars)
  #out <- est
  return(out)                      
  
}

#### Run function
kittens <- c("improved_water", "piped")
for (i in kittens) {
  setkey(dt)
  collapse_by(dt, dt[(i)], "ihme_urban")
}
missing_rm <- function(x){
   dt2 <- dt[!is.na(x)]
   mean(dt2$x)
}
kitty <- c("improved_water", "piped")
kitty <- dt[, c("improved_water", "piped"), with=F]

test <- as.data.frame(lapply(kitty, svymean, design, na.rm=T))
test <- as.data.frame(lapply(kitty, collapse_by, kitty))
sapply(kitty, function=collapse_by)

collapse_by(dt, vars, "ihme_urban")
df <- copy(dt)
var <- "improved_water"
by_vars <- "ihme_urban"
