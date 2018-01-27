###########################################################
### Author: Zane Rankin
### Date: 11/11/2016
### Project: ubCov
### Purpose: Formatting for 1) Ubcov extraction output, 2) Ubcov tabulation output (for epi upload)
###########################################################

###################
### Setting up ####
###################
library(data.table)

###################################################################
# Format ubcov extract output to epi format
###################################################################

format_ubcov_epi <- function(df){
  #YEARS
  df <- setnames(df, "ihme_start_year", "year_start")
  df <- setnames(df, "ihme_end_year", "year_end")
  #SEX
  df[, sex_id := ifelse(ihme_male == 1, 1, 2)]
  df[, sex := ifelse(ihme_male == 1, "Male", "Female")]
  df[,ihme_male:=NULL]
  #AGE (this should be done with get_demographics when it's updated... here we want most detailed age_group_id - they can be aggregated to <5 later)
  df[, age_group_id := round((ihme_age_yr + 25)/5)]
  df[ihme_age_yr > 80, age_group_id := 21]
  df[,ihme_age_yr:=NULL]
  #LOCATION (this should be done with get_location_metadata when it's updated)
  #df <- setnames(df, "ihme_loc_id", "iso3") 
  df[, location_id := ihme_loc_id]
  df[, iso3 := ihme_loc_id]
  #OTHERS
  ihme_vars <- grep("ihme", names(df), value=TRUE)
  for(ihme_var in ihme_vars){
    #print(paste("Renaming", ihme_var, "to", substring(ihme_var,6)))
    df <- setnames(df, ihme_var, substring(ihme_var,6))
  }
}


#######################################################################################################################

###################################################################
# Format ubcov tabulation output to epi format
###################################################################
if(0 == 1){ # Testing
  df = copy(out)
  extractor = "kittens"
  measure = "continuous"
  validate = "no"
  case_name = ""
  case_definition = ""
  case_diagnostics = ""
  recall_type = "Point"
  source_type = "Survey - cross-sectional"
  note_SR = "extraction/tabulation via ubcov"
  stdev = "long"
  
}
#(In future, could make pull off of an excel codebook)
prep_epi_upload <- function(df, extractor, measure, validate = FALSE, case_name = "", case_definition = "", case_diagnostics = "", 
                            recall_type = "Point", source_type = "Survey - cross-sectional", note_SR = "extraction/tabulation via ubcov",
                            stdev = "none") {
  
  #Required Inputs 
  df[,extractor  := extractor]
  df[,measure  := measure]
  
  #Optional Inputs 
  df[,case_name  := case_name]
  df[,case_definition  := case_definition]
  df[,case_diagnostics  := case_diagnostics]
  df[,source_type := source_type]
  df[,recall_type  := recall_type]
  if(note_SR == "extraction/tabulation via ubcov"){ note_SR <- paste(note_SR, "on", Sys.Date())}
  df[,note_SR  := note_SR]
  
  #Automatic Inputs
  if(0 == 1) { #Waiting on central functions (get_location_metadata) and word on what unit_type is for continuous
    #Map following off location_metadata
    smaller_site_unit # 1 if national, 0 if subnational?  
    representative_name # "Nationally representative only" or "Representative for subnational location only" or "Representative for subnational location and urban/rural"
    urbanicity_type # can we make mixed/both unless location name includes "urban" or "rural" (ie, india subnats only)
  }
  
  #Map following off measure 
  if(measure == "prevalence") {
    df[,unit_type  := "Person"]
    df[,unit_type_value  := 1]
  }
  if(measure == "continuous") {
    df[,unit_type  := "Not sure what to do about this for continuous!!!"]
    df[,unit_type_value  := "Not sure what to do about this for continuous!!!"]
  }
  if(!(measure %in% c("prevalence", "continuous"))){
    stop(paste("Unsure what unit_type to put for measure = ", measure))
  }
  
  #Defaults 
  df[,site_memo  := ""]
  df[,sex_issue	:= 0]
  df[,year_issue	:= 0]
  df[,age_issue	:= 0]
  df[,age_demographer	:= 1]
  df[,measure_adj := 1] 
  
  #For now, try field citation based on filename 
  setnames(df,"file_name", "field_citation_value") 
  
  #Standard deviation: For now, we can either reshape long (as will be required for epi upload), or drop it 
  if(stdev == "long"){
    df.sd <- copy(df)
    df.sd[,c("var", "mean", "standard_error") := list(paste0(var, "_standard_deviation"), standard_deviation, standard_deviation_se)]
    df[,c("standard_deviation","standard_deviation_se") := NULL]
    df.sd[,c("standard_deviation","standard_deviation_se") := NULL]
    df <- rbind(df, df.sd)
  }
  if(stdev == "drop"){
    df[,c("standard_deviation","standard_deviation_se") := NULL]
  }
  if(stdev == "wide"){print("keeping stdev wide")} 
  
  #Order and keep variables of interest 
  #NEED TO DELETE SUPERFLOUS VARIABLES, but for now let's keep all until formatting is finalized 
  #setcolorder(df, c("nid", "field_citation_value", "location_id", "year_start", "year_end", "sex"))
  df[,list(names(df))]
  
  #Confirm format for epi uploader 
  if(validate) {
    #run Logans validation script (not available yet 11/11) 
  }
  
  return(df)
  
}

#######################################################################################################################
