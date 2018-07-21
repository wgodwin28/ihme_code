# source('/ihme/code/geospatial/temperature/exposure/launch_exposure_calc_by_year.R', echo =T)
#set up smart sensing of os
if(Sys.info()[1]=='Windows'){
  j = "J:/"
} else{
  j = '/home/j/'
}

#set variables for parallelization
code.dir = paste0('/ihme/code/geospatial/temperature/exposure/')

slots = 30
years = seq(1990,2015, 5)
num_draws = 100
temp_prods = c('era_mean', 'cru_spline_interp')
admin_level = 'admin0'
tmrel_version = 1
risk_version = 'test'
paf_version = 1


#load the possible causes
load(paste0('/share/geospatial/temperature/estimates/risk/temperature_risks_', risk_version, '.Rdata'))
cause_list = as.character(unique(risk_grid$acause))

#cause_list = c('diabetes') #, 'resp_asthma')


for(tp in temp_prods){
  #make paf directory
  dir.create(paste0('/share/geospatial/temperature/estimates/paf/',tp,'/',paf_version),recursive = T)
  for(yyy in years){
    convert_k = grepl('era', tp)
    for (ccc in cause_list) {

      #prepare qsub
      args = paste(slots, yyy, tp, admin_level, ccc, paf_version, tmrel_version, risk_version, convert_k)

      rscript = paste0(code.dir, 'temperature_exposure_by_year.R')
      rshell = paste0('/ihme/code/geospatial/temperature/r_shell_fancy.sh')
      errors = '-o /share/temp/sgeoutput/dccasey/output -e /share/temp/sgeoutput/dccasey/errors'
      jname = paste0('calc_temp_exp_',tp,'_',yyy,'_',ccc)
      sys.sub <- paste0("qsub -P proj_geospatial ", errors, " -N ", jname, " ", "-pe multi_slot ", slots, " ", "-t ", paste0('1:', num_draws)) #array job, era that I've downloaded exists for 1989-2016
      command =paste(sys.sub, rshell, rscript, args)

      #launch jobs
      system(command)
      #print(command)
    } #close cause
  } #close years
} #close temperture products

#write arguments to disk
cols = list(run_date = as.character(Sys.time()), years = years, temperature_products = temp_prods, admin_level = admin_level, causes = cause_list,
                     paf_version = paf_version, tmrel_version= tmrel_version, risk_version = risk_version, draws = num_draws)
run_log = as.data.frame(lapply(cols, `length<-`, max(sapply(cols, length))))
write.csv(run_log, file = paste0('/share/geospatial/temperature/run_log/run_log_',paf_version,'.csv'))

