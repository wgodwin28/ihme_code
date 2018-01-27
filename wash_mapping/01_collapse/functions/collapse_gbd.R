###########################################################
### Author: Patrick Liu
### Date: 1/26/2015
### Project: ubCov
### Purpose: Collapse
###########################################################

###################
### Setting up ####
###################
# library(haven)
# library(data.table)
# library(dplyr)
# library(survey)

###################################################################
# Collapse Blocks
###################################################################


collapse_list <- function(df, vars) {

  ## Detect meta
  meta <- setdiff(names(df), vars)
  
  ## Binary for whether or not variable exists and is not completely missing
  out.vars <- sapply(vars, function(x) ifelse(x %in% names(df) & nrow(df[!is.na(x)]) > 0, 1, 0)) %>% t %>% data.table

  return(cbind(out.meta, out.vars))
}

#######################################################################################################################################

gbd_age <- function(df, age_yr) {

  ## Age groups
  df[, age_group_id := round((age_yr + 25)/5)]
  df[age_yr > 80, age_group_id := 21]

  return(df)

}

#######################################################################################################################################

setup_design <- function(df, var) {

## Set options

## conservative adjustment recommended by Thomas Lumley for single-PSU strata.  Centers the data for the single-PSU stratum around the sample grand mean rather than the stratum mean
options(survey.lonely.psu = 'adjust')

## conservative adjustment recommended by Thomas Lumley for single-PSU within subpopulations.  Need to find out more about what exactly this is doing.
options(survey.adjust.domain.lonely = TRUE)

## Check for survey design vars
check_list <- c("strata", "psu", "hhweight")
for (i in check_list) {
  ## Assign to *_formula the variable if it exists and nonmissing, else NULL
  # assign(paste0(i, "_formula"),
  #   #ifelse(i %in% names(df) & nrow(df[!is.na(df[[i]]),]) > 0, paste("~", i), NULL) %>% as.formula #data frame syntax
  #   ifelse(i %in% names(df), paste("~",i), NULL) %>% as.formula #data table syntax
  # )
  if(nrow(df[!is.na(df[[i]]),]) > 0){
    assign(paste0(i, "_formula"), paste0("~",i) %>% as.formula)
  } else {
    assign(paste0(i, "_formula"), NULL)
  }
}
  if(is.null(psu_formula)){
    psu_formula <- ~1
    df$psu <- 1
  }
## Set svydesign
return(svydesign(id = psu_formula, weight = hhweight_formula, strat = strata_formula, data = df[!is.na(var)], nest = TRUE))

}

#######################################################################################################################################

collapse_by <- function(df, var, by_vars) {

  ## Subset to frame where data isn't missing
  if(nrow(df[!is.na(psu),]) == 0){
    df.c <- copy(df[!is.na(get(var)),])
  } else {
    df.c <- copy(df[!is.na(get(var)) & !is.na(psu),])
  }                #& !is.na(strata) & !is.na(hhweight)])

  ## Setup design
  design <- setup_design(df.c, var)
  
  ## Setup by the by call as a formula
  by_formula <- as.formula(paste0("~", paste(by_vars, collapse = "+")))
  
  ## Calculate mean and standard error by by_var(s).  Design effect is dependent on the scaling of the sampling weights
  est = svyby(~get(var), by_formula, svymean, design = design, deff = "replace", na.rm = TRUE, drop.empty.groups = TRUE, keep.names = FALSE, multicore=TRUE)
  setnames(est, c("get(var)", "DEff.get(var)"), c("mean", "deff"))
  
  ## Calculate number of observations, number of clusters, strata
  meta <- df.c[, list(ss = length(which(!is.na(get(var)))), 
                    nclust = length(unique(psu)), 
                    nstrata= length(unique(strata)),
                    var = var
                    ), by = by_vars]
  
  ## Adjust SE if no strata present
  # if (nrow(df[!is.na(df[[strata]]),]) > 0) {
  #   df <- df[design_effect < 2.25, inflate := 2.25/design_effect]
  #   df <- df[design_effect < 2.25, standard_error := standard_error * sqrt(inflate)]
  #   df <- df[, inflate := NULL]
  #   df <- df[design_effect < 2.25, design_effect := 2.25]
  # }
  ## Combine meta with est
  out <- merge(est, meta, by=by_vars)

  return(out)                      
  
}

#######################################################################################################################################

