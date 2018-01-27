power2 <- list(
	parameters = c("alpha", "beta", "gamma"),
	eval = function(z, params, ...){ out <- ifelse(z > params$tmred, 1+(params$alpha*(1-exp(-params$beta*((z-params$tmred)/1e10)^params$gamma))), 1); out},
	eval.mean = function(z, params, ...){ out <- ifelse(z > params$tmred.mean, 1+(params$alpha.mean*(1-exp(-params$beta.mean*((z-params$tmred.mean)/1e10)^params$gamma.mean))), 1); out},
	eval.2010 = function(z, params, ...){ out <- ifelse(z > params$tmred, 1+(params$alpha*(1-exp(-params$beta*(z-params$tmred)^params$gamma))), 1); out},
	eval.2010.mean = function(z, params, ...){ out <- ifelse(z > params$tmred.mean, 1+(params$alpha.mean*(1-exp(-params$beta.mean*(z-params$tmred.mean)^params$gamma.mean))), 1); out},
	func = function(rr, z, tmred, alpha, beta, gamma, ...){ rr~1+(alpha*(1-exp(-beta*(z-tmred)/1e10^gamma)))*(z > tmred)},
	func.ratio = function(rr, z.num, z.den, tmred, alpha, beta, gamma, ...){rr~(1+(alpha*(1-exp(-beta*((z.num-tmred)/1e10)^gamma))))/(1+(alpha*(1-exp(-beta*((z.den-tmred)/1e10)^gamma))))},
	gen.inits = function(init.data) { 			
		# New init values based on Rick's email on 1/16/2014
			# 1.  set initial value for alpha = mean(a few RR with the largest Pm2.5 values)
			# 2.  select out only AAP RR and fit model AAPRR=1 + a*(RR-cf) and then set beta=a/alpha (IER ~ 1 + alpha*beta*(z-cf) for small z )
			# 3.  for fixed alpha and beta based on 1 and 2 above, run the IER model with ONLY delta to be estimated - with only 1 parameter to estimate this almost always converges
		
		# Step 1: I arbitrarily chose the top 20%
		alpha.est <- mean(init.data$rr[init.data$z.num >= quantile(init.data$z.num, .8)])
		
		# Step 2: I assume he means an actual 1, not a B_0 in linear model. 
		z.num.shifted <- init.data$z.num - init.data$tmred
		rr.shifted <- init.data$rr - 1
		temp.lm <- lm(rr.shifted[init.data$zsource=="OAP"] ~ 0 + z.num.shifted[init.data$zsource=="OAP"])
		beta.est <- coef(temp.lm) / alpha.est
		
		# Step 3: Make a function to fit NLS to with the previous values and run NLS
		# This function is the same as the above power2$func.ratio, but with alpha=alpha.est and beta=beta.est
		temp.func <- function(rr, z.num, z.den, tmred, gamma, ...) {
								rr ~ (1 + (alpha.est * (1 - exp(-beta.est * (z.num - tmred)/1e10^gamma)))) / 
								      (1 + (alpha.est * (1 - exp(-beta.est * (z.den - tmred)/1e10^gamma)))) 
					}
		
		temp.nls <- try(nls(temp.func(gamma), start=list(gamma=1), weights=weights, data=init.data, 
					control=nls.control(maxiter=1000, tol=1e-05, minFactor = 1/1024^4, printEval = FALSE, warnOnly = FALSE)), silent=TRUE)
		
		# Use the results. If the nls failed, I use the old method, so that we have something to pass on.
		if(class(temp.nls) != "try-error") {
			out <- list(alpha=alpha.est, beta=beta.est, gamma=temp.nls$m$getPars()["gamma"])
		} else {
			a.init <- max(init.data$rr[init.data$zsource != "IAP"])-1				
			suppressWarnings(trans.r <- log(-log( 1- (init.data$rr[init.data$zsource!="IAP"]-0.99)/a.init ))) # Sometimes produces NaN, but we don't care
			trans.r[is.na(trans.r)] <- mean(trans.r[!is.na(trans.r) ])
			trans.z <- log(init.data$z.num[init.data$zsource!="IAP"] - init.data$tmred[init.data$zsource!="IAP"])
			trans.lm <- lm(trans.r ~ 1+trans.z)
			b.init <- exp(coef(trans.lm)[1])
			c.init <- coef(trans.lm)[2]
			out <- list(alpha=a.init, beta=b.init, gamma=c.init)
		}
		
		out
	}
)
	
power <- list(
	parameters = c("alpha", "beta"),
	eval = function(z, params, ...){ out = ifelse(z > params$tmred, 1 + (params$alpha * (z-params$tmred)^params$beta), 1); out},
	func = function(rr, z, tmred, alpha, beta, ...){ rr~1+(alpha * (z-tmred)^beta) * (z > tmred)},
	func.ratio = function(rr, z.num, z.den, tmred, alpha, beta, ...){ rr~(1+ifelse(z.num > tmred, alpha*(z.num-tmred)^beta, 0))/(1+ifelse(z.den > tmred, alpha*(z.den-tmred)^beta, 0))},
	gen.inits = function(init.data) { 
						conditions = init.data$z.den == init.data$tmred & init.data$rr > 1
						tmp.mod = lm(log(init.data$rr[conditions]-1) ~ 1+ log(init.data$z.num[conditions] - init.data$tmred[conditions]))
						out = list(alpha=exp(coef(tmp.mod)[1]), beta=coef(tmp.mod)[2])
						out
						}
)

log2 <- list(
	parameters = c("alpha", "beta"), 
	eval = function(z, params, ...){out <- ifelse(z <= params$tmred, 1, (((z + params$alpha)/(params$tmred + params$alpha))^params$beta)*(z > params$tmred)); out}, 
	func = function(rr, z, tmred, alpha, beta, ...){ rr~(1*(z <= tmred)) + (((z + alpha)/(tmred+alpha))^beta)*(z > tmred)}, 
	func.ratio = function(rr, z.num, z.den, alpha, beta, ...){ rr~(1*(z.num <= tmred)+(((z.num+alpha)/(tmred+alpha))^beta)*(z.num > tmred))/(1*(z.den <= tmred)+(((z.den+alpha)/(tmred+alpha))^beta)*(z.den > tmred))},       
	gen.inits = function(init.data) { 
				loglik <- function(a, sig=sd(r), r, z, tmred, ...) {
					mu <- ((z+a[1])/(tmred+a[1]))^a[2]
					out <- sum(log(dnorm(r, mu, sig)))
					out
				}
			
				if(init.data$cause[1] %in% c("cvd_ihd"))
				{
					a.temp <- rep(seq(-20, 20, length=100), 100)
					b.temp <- rep(seq(-20, 20, length=100), each=100)
				} else if (init.data$cause[1] %in% "cvd_stroke") {
					a.temp <- rep(seq(-10, 30, length=100), 100)
					b.temp <- rep(seq(-10, 30, length=100), each=100)				
				} else {
					a.temp <- seq(-20, 20, length=100)
					b.temp <- seq(-20, 20, length=100)
				}
				eval <- apply(X=cbind(a.temp, b.temp), MARGIN=1, FUN=function(x) {
										loglik(a=x, 
												sig=sd(init.data$rr[init.data$zsource != "IAP"]), 
												r=init.data$rr[init.data$zsource != "IAP"], 
												z=init.data$z.num[init.data$zsource != "IAP"], 
												tmred=init.data$tmred[init.data$zsource != "IAP"])
													})
				eval[is.na(eval)] <- -Inf
				a.temp <- a.temp[eval!= -Inf]
				b.temp <- b.temp[eval!= -Inf]
				eval <- eval[eval!= -Inf]
				
				out <- list(alpha=a.temp[which.max(eval)], beta=b.temp[which.max(eval)])
				out
			}				
)
