## Model, fit, rmse
oos.rmse <- function(df, transform="kittens", offset=0.01, model, prop_train, reps) {
  ## Identify y variable
  y <- gsub("[~].*", "", model) %>% gsub("^\\s+|\\s+$", "", .)
  ## Identify model type
  func <- ifelse(grepl("[|]", model), "lmer", "lm")
  ## Transform y
  if (transform=="logit") df[[y]] <- car::logit(df[[y]], adjust=offset)
  if (transform=="log") df[[y]] <- log(df[[y]])
  ## Run fit on whole dataset
  if (func == "lmer") mod.full <- lmer(as.formula(model), data=df)
  if (func == "lm") mod.full <- lm(as.formula(model), data=df)
  ## Store coefficient info  
  Vcov <- vcov(mod.full, useScale = FALSE) 
  if (func=="lmer") betas <- fixef(mod.full) 
  if (func=="lm") betas <- coefficients(mod.full) 
  se <- sqrt(diag(Vcov))
  zval <- betas / se 
  pval <- 2 * pnorm(abs(zval), lower.tail = FALSE) 
  sum_water2 <- cbind(model=model, betas, se, zval, pval) 
  ## Run fit iterations
  rmse.out <- mclapply(1:reps, function(x) {
    ## Split dataset into test/train
    set.seed(x)
    train_index <- sample(seq_len(nrow(df)), size=floor(prop_train*nrow(df)))
    train <- df[train_index]
    test <- df[-train_index]
    ## Model on train
    if (func == "lmer") mod <- lmer(as.formula(model), data=train)
    if (func == "lm") mod <- lm(as.formula(model), data=train)
    ## Predict on test
    test <- test[, kittens := predict(mod, newdata=test, re.form=NA, allow.new.levels=TRUE)]
    ## Back transform
    if (transform=="logit") {test <-  test[, kittens := inv.logit(kittens)]; test <-  test[, (y) := inv.logit(get(y))]}
    if (transform=="log") {test <- test[, kittens := exp(kittens)]; test <- test[, (y) := exp(get(y))]}
    ## RMSE
    rmse <- sqrt(mean(test[["kittens"]]-test[[y]], na.rm=TRUE)^2)
  }, mc.cores=10) %>% unlist %>% mean
  return(list(mod=model, fit=mod.full, rmse=rmse.out, sum=sum))
}

# Apply function
package_lib <- "J:/WORK/01_covariates/05_ubcov_R_libraries"
library(haven)
library(rhdf5)
library(data.table)
library(magrittr)
library(lme4)
df <- fread("J:/temp/wgodwin/gpr_input/run1/ebf0_5_prior.csv")
model <- data ~ cv_piped_covar + (1|super_region_id) + (1|region_id)
model <- data ~ sdi + (1|super_region_id) + (1|region_id)
model <- data ~ log(ldi_pc) + maternal_educ_yrs_pc + prop_urban + (1|super_region_id) + (1|region_id)
transform <- "logit"
y <- "data"
func <- "lmer"

prop_train <- 0.3
reps <- 3
fit <- oos.rmse(df, transform = "logit", offset = .01, model, prop_train, reps)


mod <- lmer(data ~ log_ldi + maternal_educ_yrs_pc + log_tfr + (1|super_region_id) + (1|region_id),
          data = df,
          na.action=na.omit)
coefficients_re <- as.data.table(coef(summary(mod)), keep.rownames = T)
mod <- lm(data ~ ln_ldi + maternal_educ_yrs_pc + log_tfr,
            data = df,
            na.action=na.omit)
ebf0_5 <- as.data.table(coef(summary(mod)), keep.rownames = T)
