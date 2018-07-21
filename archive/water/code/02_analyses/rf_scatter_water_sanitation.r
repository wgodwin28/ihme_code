################################################################################
## Author: Kelly Cercy
##         ggplot code adapted from Ryan Barber's cod_model_scatter_dev.R
## Date Created: 27 January 2016
## Last updated: 9 February 2016
## Description: Compare epi model versions of custom RF exposures, produces pdfs
##              of GBD 2013 vs 2015 exposures for water and sanitation covariates
##              in 1990 and 2010 for 
##              all countries. Countries with % change <=5% are not labeled. Will
##              be saved as: J:/WORK/05_risk/central/diagnostics/exp_scatters/scatter_{covariate}_{date}_nat.pdf
##
##  REQUIRED INPUT:
##    input.path       ->  file path to input data as a .csv. input data must have
##                            -GPR results: gpr_mean
##                            -Age groups: age_group_id
##                            -Sex: sex_id
##                            -Geography: ihme_loc_id
##                            -Year: year_id
##                         example, "J:/temp/kcercy/input.csv"
##
##  OPTIONAL INPUT:
##    nat                 ->  logical for if locations should be national or 
##							  subnational, assumed true, giving natinonal results
##
##  EXAMPLE:
##    source('rf_scatter.R')
##    rf_scatter("J:/temp/kcercy/input.csv")
##	  rf_scatter("J:/temp/kcercy/input.csv",nat=FALSE)
##
################################################################################

if (.Platform$OS.type=="unix") {
  prefix <- '/home/j'
} else {
  prefix <- 'J:'
}


#################################################################################
## helper functions
#################################################################################

#function that takes the model_version_id and returns the 2015 data
get_2013_data <- function(covariate_id,nat){
  # Set read only credentials
  db_username <- "readonly"
  db_password <- "justlooking"
  db_host <- "newhalem.ihme.washington.edu"
  loc.level<-ifelse(nat==TRUE,"admin0","admin1")
  
  #pull from database using query Joe wrote in risk_info
  con <- dbConnect(dbDriver("MySQL"), username = db_username, password = db_password, host = db_host)
  data2013 <- dbGetQuery(con, sprintf("
                                      SELECT location_id,
                                      year_id,
                                      sex_id,
                                      age_group_id,
                                      mean_value
                                      FROM covariates.models
                                      JOIN covariates.model_versions using (model_version_id)
                                      JOIN covariates.data_versions using(data_version_id)
                                      join covariates.demographics using (demographic_id)
                                      join covariates.locations using (location_id)
                                      WHERE is_best=1
                                      AND covariate_id = %s
                                      AND year_id in (1990,2010)
                                      AND age_group_id=22
                                      AND sex_id=3
                                      AND locations.type='%s'
      ",covariate_id,loc.level))
  dbDisconnect(con)

  #make sure data was pulled
  data2013 <- data.table(data2013)
  if(nrow(data2013)==0) stop("No rows returned from 2013 data query")

  #return data
  return(data2013)
}

#################################################################################
## main function
#################################################################################

rf_scatter <- function(input.path=NULL,nat=TRUE){
  
  library(RMySQL)
  library(data.table)
  library(ggplot2)
  #make sure file paths are correct
  if (!grepl(".csv", input.path, fixed = T)) stop("invalid input file type: must be .csv")
  
  #pull data
  data <- fread(input.path)
  
  ## make sure input data has needed columns
  if (!"gpr_mean" %in% names(data)) stop("data is missing gpr_mean")
  if (!"age_group_id" %in% names(data)) stop("data is missing age group (age_group_id) variable")
  if (!22 %in% data$age_group_id) stop("age is not all ages in input data")
  if (!"sex_id" %in% names(data)) stop("data is missing sex (sex_id) variable")
  if (!3 %in% data$sex_id) stop("sex is not both sexes in input data")
  if (!"ihme_loc_id" %in% names(data)) stop("data is missing geograpy (ihme_loc_id) variable")
  if (!"year_id" %in% names(data)) stop("data is missing year (year_id) variable")
  if (!"me_name" %in% names(data)) stop("data is missing me_name")
  
  #subset data
  data <- data[year_id %in% c(1990,2010) & sex_id==3 & age_group_id==22,
               list(me_name,location_id,ihme_loc_id,year_id,age_group_id,sex_id,gpr_mean)]
  if(nrow(data)==0) stop("Unable to subset input data to needed characteristics")
  data <- unique(data)
  

  # Get associated covariate and covariate_id based on me_name
  risk <- unique(data$me_name)
  covariate <- ifelse(risk=="wash_water_imp","water_prop",
                      ifelse(risk=="wash_sanitation_imp","sanitation_prop",
                             stop("me_name is not water or sanitation covariate")))
  covariate_id <- ifelse(risk=="wash_water_imp",160,
                         ifelse(risk=="wash_sanitation_imp",142,
                                stop("me_name is not water or sanitation covariate")))
  
  #pull 2013 data
  data2013 <- get_2013_data(covariate_id,nat)
  
  #merge 2013 and 2015 data
  data <- merge(data2013,data,by=c("location_id","year_id","sex_id","age_group_id"),all.x=T)
  region <- fread("J:/temp/wgodwin/gpr_output/region_map.csv")
  data <- merge(data,region,by="location_id",all.x=T)
  #check that model exists for all countries
  if (data[, length(unique(ihme_loc_id))] != 188 & nat==TRUE) {
    warning("You are missing countries in your data")
  }
  #check that model exists for all subnationals
  if (data[, length(unique(ihme_loc_id))] != 78 & nat==FALSE) {
    warning("You are missing subnationals in your data")
  }
  # Ensure that we have a unique set of observations
  if (nrow(data[, list(location_id, year_id, sex_id, age_group_id)])!= nrow(data)) {
    stop("HALT! You have existing models with duplicate rows across location, age, sex, and year")
  }
  

  #calculate percent change:
  data$pct_change <- abs((data$mean_value-data$gpr_mean)/data$mean_value)
  #label point with iso if % change was > 5%
  data$ihme_loc_id_lab <- ifelse(data$pct_change<=0.05,"",data$ihme_loc_id)
  
  #plot formatting
  y_mod_lab <- "Active GBD 2015 best model"
  x_mod_lab <- "GBD 2013 best model"

  data$mean_value[is.na(data$mean_value)] <- 0
  data$gpr_mean[is.na(data$gpr_mean)] <- 0
  data$sex <- "Both sexes"

  #set regions for color coding
  if (nat) {
    gnum <- 21
    gname <- "Region"
    data$region_name <- factor(data$region_name, levels = c("High-income Asia Pacific","Western Europe","High-income North America","Australasia","Southern Latin America",
                                                            "Central Europe","Eastern Europe","Central Asia",
                                                            "Central Sub-Saharan Africa","Eastern Sub-Saharan Africa","Southern Sub-Saharan Africa","Western Sub-Saharan Africa",
                                                            "North Africa and Middle East",
                                                            "South Asia",
                                                            "East Asia","Southeast Asia","Oceania",
                                                            "Andean Latin America","Central Latin America","Tropical Latin America","Caribbean"))
  } else {
    gnum <- 3
    gname <- "Country"
    data$region_name <- ifelse(grepl("CHN",data$ihme_loc_id),"China",ifelse(grepl("GBR",data$ihme_loc_id),"United Kingdom",ifelse(grepl("MEX",data$ihme_loc_id),"Mexico","")))
    data$region_name <- factor(data$region_name, levels = c("China","Mexico","United Kingdom"))
  }
  col_grad <- colorRampPalette(c("#9E0142", "#F46D43", "#FEE08B", "#E6F598", "#66C2A5", "#5E4FA2"), space = "rgb")
  
  #one plot for each year to same pdf
  years <- c(1990,2010)
  if (nat){
    pdf(file = paste0(prefix,"/WORK/05_risk/central/diagnostics/exp_scatters/scatter_",covariate,"_",format(Sys.Date(),"Y%YM%mD%d"),"_nat.pdf"),width = 11, height = 8.5)
  } else {
    pdf(file = paste0(prefix,"/WORK/05_risk/central/diagnostics/exp_scatters/scatter_",covariate,"_",format(Sys.Date(),"Y%YM%mD%d"),"_subnat.pdf"),width = 11, height = 8.5)
  }
  
  for (year in years){
    
    tmpdata<-data[which(data$year_id==year),]
    maxy<-max(tmpdata$gpr_mean)+0.1*max(tmpdata$gpr_mean)
    maxx<-max(tmpdata$mean_value)+0.1*max(tmpdata$mean_value)
    max <- ifelse(maxy>maxx,maxy,maxx)
    graph_title <- ifelse(covariate_id==142,paste0("Sanitation (proportion with access): ",year," all ages"),paste0("Improved water source (proportion with access): ",year," all ages"))
    model_plot <- ggplot(data=tmpdata, aes(x=mean_value, y=gpr_mean, color=region_name)) + 
      geom_point() +
      geom_text(aes(label=ihme_loc_id_lab), hjust=.5, vjust=.5,show.legend = F) +
      scale_y_continuous() +
      scale_colour_manual(values=rev(col_grad(gnum)), name=gname) +
      xlab(x_mod_lab) + 
      ylab(y_mod_lab) + 
      coord_cartesian(ylim=c(0,max), xlim=c(0,max)) +
      facet_grid( ~ sex) +
      geom_abline(data=tmpdata, intercept = 0, slope = 1, colour="black") +
      ggtitle(graph_title) +
      theme_bw()+
      theme(axis.title.x = element_text(face="bold", color="black", size=14),
            axis.title.y = element_text(face="bold", color="black", size=14),
            axis.text.x = element_text(color="black", size=12),
            axis.text.y = element_text(color="black", size=12),
            plot.title = element_text(face="bold", color = "black", size=16),
            legend.position="bottom")
    print(model_plot)
  }
  dev.off()
  if (nat){
    print(paste0("Saved as: ",prefix,"/WORK/05_risk/central/diagnostics/exp_scatters/scatter_",covariate,"_",format(Sys.Date(),"Y%YM%mD%d"),"_nat.pdf"),width = 11, height = 8.5)
  } else {
    print(paste0("Saved as: ",prefix,"/WORK/05_risk/central/diagnostics/exp_scatters/scatter_",covariate,"_",format(Sys.Date(),"Y%YM%mD%d"),"_subnat.pdf"),width = 11, height = 8.5)
  }
  
  
}



