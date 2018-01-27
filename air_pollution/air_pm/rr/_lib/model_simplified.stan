#----HEADER-------------------------------------------------------------------------------------------------------------
# Author: JF
# Date: 03/22/2016
# Project: RF: air_pm
# Purpose: Define the simplified GBD2015 model in Stan code
# source("/homes/jfrostad/_code/risks/air_pm/rr/_lib/model_gbd2015.stan", echo=T)
#***********************************************************************************************************************

# Create the stan model object 
# stan model
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
  real tmrel;
}

// specify model parameters
parameters {
  // we're assuming that these values have to be positive
  // lower=1e-9 forces positive values in case we use a prior distribution that allows for negatives
  real<lower=1e-9> beta;
  real<lower=1e-9> rho;
}
  
// specify priors and data likelihood function
model {
  // make a temporary vector to store the predicted log(RR)
  vector[N] pred_log_rr;
  
  // non-informative prior on parameters
  beta ~ gamma(1.0, 0.01);     // whereas beta and gamma are small, so tighten them up closer to 1.0
  rho ~ gamma(1.0, 0.01);
  
  // make predictions for log(RR) using alpha/beta/gamma
  for (n in 1:N) {
  pred_log_rr[n] <- log(exp(beta * pow((exposure[n] - tmrel), rho)) / exp(beta * pow((cf_exposure[n] - tmrel), rho)));
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
  predicted_RR[t] <- if_else(test_exposure[t] > tmrel, exp(beta * pow((test_exposure[t] - tmrel), rho)), 1.0);
  }
}