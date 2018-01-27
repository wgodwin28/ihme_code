# Author:   Kyle Foreman
#           kyleforeman@gmail.com
# Date:     04 Nov 2014
# Purpose:  fit pm2.5 RR model in Stan

##### CONFIGURE #####

# libraries
library(rstan)
library(ggplot2)
library(grid)

# working directory
# data <- 'C:/Users/jfrostad/Desktop/RISK_LOCAL/air_pm/STAN/data/mean_replicated'
# graphs <- 'C:/Users/jfrostad/Desktop/RISK_LOCAL/air_pm/STAN/graphs/mean_replicated'
# diagnostic.output <- 'C:/Users/jfrostad/Desktop/RISK_LOCAL/air_pm/STAN/output/mean_replicated'
# machinery.output <- 'J:/WORK/05_risk/01_database/02_data/air_pm/02_rr/04_models/output/power2_non_informative_priors'

data <- 'C:/Users/jfrostad/Desktop/RISK_LOCAL/air_pm/STAN/data/no_AS'
graphs <- 'C:/Users/jfrostad/Desktop/RISK_LOCAL/air_pm/STAN/graphs/no_AS'
diagnostic.output <- 'C:/Users/jfrostad/Desktop/RISK_LOCAL/air_pm/STAN/output/no_AS'
machinery.output <- 'J:/WORK/2013/05_risk/01_database/02_data/air_pm/02_rr/04_models/output/no_AS'

# ages and causes to loop through
# causes <- c("lri")
causes <- c("resp_copd", "neo_lung", "lri", "cvd_ihd", "cvd_stroke")
# causes <- c("cvd_stroke")

for (cause in causes) {
  
  if (cause == "resp_copd") {
    
    age.list <- c(99)
    seed <- 1926429
    
  } else if (cause == "neo_lung") {
    
    age.list <- c(99)
    seed <- 1458021
    
  } else if (cause == "lri") {
    
    age.list <- c(99)
    seed <- 1647938
    
  } else if (cause == "cvd_ihd") {
    
    age.list <- seq(25, 80, by=5)
    age.list <- c(25,50,80)
    seed <- 521741
    
  } else if (cause == "cvd_stroke") {
    
    age.list <- c(25,50,80)
    seed <- 175367
    
  }
  
  for (age in age.list) {
    
    ##### RUN STAN MODEL #####
    
    # print current loop status
    print(paste0(cause,' ',age))
    
    # load data
    load(file.path(data, paste0(cause,'_',age,'.RData')))
    draw.data$log_rr_adj <- log(draw.data$rr) # generate a new log rr variable from the adj adjusted (natural space) rr
    
    # stan model
    mod_code <- "
    // specify the input data
    data {
    // # observations
    int<lower=1> N;
    
    // log(RR) and sd(log(RR))
    vector[N] log_rr;
    vector[N] log_rr_sd;
    
    // observed exposure level
    vector[N] exposure;
    
    // counterfactual exposure level
    vector[N] cf_exposure;
    
    // test exposure values
    int<lower=1> T;             // number of test points
    vector[T] test_exposure;    // values at which to predict RR
    
    // theoretical minimum
    real tmred;
    }
    
    // specify model parameters
    parameters {
    // we're assuming that these values have to be positive
    // lower=1e-9 forces positive values in case we use a prior distribution that allows for negatives
    real<lower=1e-9> alpha;
    real<lower=1e-9> beta;
    real<lower=1e-9> gamma;
    }
    
    // specify priors and data likelihood function
    model {
    // make a temporary vector to store the predicted log(RR)
    vector[N] pred_log_rr;
    
    // non-informative prior on parameters
    alpha ~ gamma(1.0, 0.01);   // alpha can be big, so give it small precision
    beta ~ gamma(1.0, 0.01);     // whereas beta and gamma are small, so tighten them up closer to 1.0
    gamma ~ gamma(1.0, 0.01);

    // make predictions for log(RR) using alpha/beta/gamma
    for (n in 1:N) {
    pred_log_rr[n] <- log((1 + alpha * (1 - exp(-1 * beta * pow((exposure[n] - tmred)/1e10, gamma)))) / (1 + alpha * (1 - exp(-1 * beta * pow((cf_exposure[n] - tmred)/1e10, gamma)))));
    }
    
    // setup the data likelihood
    // our data is distributed with sd of sd(log(RR)) and mean being our predicted log(RR)
    log_rr ~ normal(pred_log_rr, log_rr_sd);
    }
    
    // generate values of RR at the test exposure levels
    generated quantities {
    vector[T] predicted_RR;
    
    // generate predictions
    for (t in 1:T) {
    predicted_RR[t] <- if_else(test_exposure[t] > tmred, 1 + alpha * (1 - exp(-1 * beta * pow((test_exposure[t] - tmred)/1e10, gamma))), 1.0);
    }
    }
    "
    
    # make a named list of data elements for Stan
    test_exposure <- c(seq(1,300,1), seq(350,30000,50))
    mod_dat <- list(N=dim(draw.data)[1], log_rr=draw.data$log_rr_adj, log_rr_sd=draw.data$logrrsd, exposure=draw.data$z.num, cf_exposure=draw.data$z.den, tmred=draw.data$tmred[1], T=length(test_exposure), test_exposure=test_exposure)
    
    # fit the model
    # 4 chains of 20k samples - drop first 10k of each, and keep each 20th sample after that
    chains <- 4
    iter <- 1e4
    warmup <- 5e3
    thin <- 20
    init.f <- function() {
      list(alpha = 50, beta = 0.1, gamma = 0.25)
    }
    mod_fit <- stan(model_code=mod_code, data=mod_dat, iter=iter, warmup=warmup, chains=chains, thin=thin, init=init.f)
    
    # extract parameters into an R list
    draws <- extract(mod_fit, inc_warmup=FALSE)
    
    # append the tmred
    draws.df <- data.frame(draws)
    draws.df$tmred=runif(nrow(draws.df), 5.9, 8.7)
    
    # export as a .csv to feed into PAF calculation
    
    write.csv(draws.df,paste0(diagnostic.output,"/nonzero_params_",cause,"_",age,".csv"))
    write.csv(draws.df,paste0(machinery.output,"/rr_curve_power2_",cause,"_a",age,".csv"))
    
    # draw histograms of each parameter
    pdf(file.path(graphs, paste0(cause,"_",age,'_params.pdf')), width=9, height=3)
    grid.newpage()
    pushViewport(viewport(layout=grid.layout(1, 3)))
    params <- c('alpha', 'beta', 'gamma')
    for (i in 1:length(params)) {
      p <- params[i]
      df <- data.frame(value=draws[[p]])
      plt <- ggplot(df, aes(x=value)) + geom_density(fill='steelblue', alpha=0.5) + ggtitle(paste0(cause,'_',age,'_',p))
      print(plt, vp=viewport(layout.pos.row=1, layout.pos.col=i))
    }
    dev.off()
    
    # extract chains with warmup for better diagnostic plots
    draws_all <- extract(mod_fit, permuted=FALSE, inc_warmup=TRUE)

    # plot chain diagnostics
    pdf(file.path(graphs, paste0(cause,'_',age,'_chains.pdf')), width=12, height=3)
    grid.newpage()
    pushViewport(viewport(layout=grid.layout(1, 3)))
    params <- c('alpha', 'beta', 'gamma')
    for (i in 1:length(params)) {
      p <- params[i]
      df <- data.frame(value=unlist(lapply(1:chains, function(c) as.matrix(draws_all[,,p][,c]))))
      df$chain <- as.factor(rep(1:chains, each=floor(iter / thin)))
      df$draw <- rep(1:floor(iter / thin), chains) * thin
      plt <- ggplot(df, aes(x=draw, y=value, color=chain))
      plt <- plt + geom_line(alpha=0.5)
      plt <- plt + scale_y_log10()
      plt <- plt + ggtitle(paste0(cause,'_',age,'_',p))
      plt <- plt + geom_vline(xintercept=warmup, alpha=0.5, linetype='longdash')
      print(plt, vp=viewport(layout.pos.row=1, layout.pos.col=i))
    }
    dev.off()
    
    
    # make a dataframe of all the estimates and data
    # extract data
    rr_draws <- extract(mod_fit, par=c('predicted_RR'))[['predicted_RR']]
    # empty dataframe
    rr_data <- data.frame(exposure=numeric(0), mn=numeric(0), lower=numeric(0), upper=numeric(0), observed=numeric(0), Size=numeric(0), Type=character(0))
    # extract predictions
    for (i in 1:length(test_exposure)) {
      draws <- rr_draws[,i]
      e <- test_exposure[i]
      tmp <- data.frame(
        exposure=e,
        mn=mean(draws),
        lower=quantile(draws, .025),
        upper=quantile(draws, .975),
        observed=NA,
        Size=NA,
        Type=NA
      )
      rr_data <- rbind(rr_data, tmp)
    }
    
    # remove outliers from observed RR data to make the graph more legible
    rr.upper <- quantile(draw.data$rr,.75,na.rm=TRUE)
    size.lower <-quantile((1/draw.data$logrrsd),.25,na.rm=TRUE)
    draw.data.outliered <- draw.data
    if(cause != "lri") draw.data.outliered[(draw.data$rr > rr.upper & (1/draw.data$logrrsd) < size.lower),] <- NA
    
    # append on observed
    for (i in 1:dim(draw.data.outliered)[1]) {
      sz <- 1 / draw.data.outliered[i, 'logrrsd']
      tmp <- data.frame(
        exposure=draw.data.outliered[i,'z.num'],
        mn=NA,
        lower=NA,
        upper=NA,
        observed=draw.data.outliered[i,'rr'],
        Size=sz,
        Type=draw.data.outliered[i,'zsource']
      )
      rr_data <- rbind(rr_data, tmp)
    }
    
    # output the estimated curves to graph both log2/power2 on the same axis
       write.csv(rr_data,paste0(diagnostic.output,"/rr_data_",cause,"_",age,".csv"))     
    
    # plot
    pdf(file.path(graphs, paste0(cause,'_',age,'_rr.pdf')))
    p <- ggplot(rr_data, aes(x=exposure))
    p <- p + geom_ribbon(aes(ymin=lower, ymax=upper), alpha=0.5, color='steelblue', fill='steelblue')
    p <- p + geom_line(aes(y=mn), alpha=0.5, color='navy')
    p <- p + geom_point(aes(y=observed, size=Size, color=Type))
    p <- p + ggtitle(paste0(cause, '_', age)) + xlab('exposure') + ylab('RR')
    print(p)
    dev.off()
    # plot a truncated version
    rr_data_trunc <- rr_data[rr_data$exposure <= 300,]
    pdf(file.path(graphs, paste0(cause,'_',age,'_rr_trunc.pdf')))
    p <- ggplot(rr_data_trunc, aes(x=exposure))
    p <- p + geom_ribbon(aes(ymin=lower, ymax=upper), alpha=0.5, color='steelblue', fill='steelblue')
    p <- p + geom_line(aes(y=mn), alpha=0.5, color='navy')
    p <- p + geom_point(aes(y=observed, size=Size, color=Type))
    p <- p + ggtitle(paste0(cause, '_', age)) + xlab('exposure') + ylab('RR')
    print(p)
    dev.off()
    # plot a logged version
    pdf(file.path(graphs, paste0(cause,'_',age,'_rr_log.pdf')))
    p <- ggplot(rr_data, aes(x=exposure))
    p <- p + geom_ribbon(aes(ymin=lower, ymax=upper), alpha=0.5, color='steelblue', fill='steelblue')
    p <- p + geom_line(aes(y=mn), alpha=0.5, color='navy')
    p <- p + geom_point(aes(y=observed, size=Size, color=Type))
    p <- p + scale_x_log10()
    p <- p + ggtitle(paste0(cause, '_', age)) + xlab('exposure') + ylab('RR')
    print(p)
    dev.off()

    
  }
}

