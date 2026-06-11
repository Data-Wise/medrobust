setwd("/Users/dt/projects/r-packages/active/medrobust")
suppressWarnings(suppressMessages(pkgload::load_all(".", quiet=TRUE)))
expit<-function(x)1/(1+exp(-x))
bM<--1.5;bY<--2.0;bAM<-log(2.5);tAY<-log(1.5);tMY<-log(2.5);bC<-0.3;tC<-0.3

# TRUE per-(a,c) params (oracle for recovery check)
truep<-function(a,cc) list(pi=expit(bM+bAM*a+bC*cc),
  g1=expit(bY+tAY*a+tMY+tC*cc), g0=expit(bY+tAY*a+tC*cc))

# Replicate compute_effects_from_params math by hand using TRUE params,
# to confirm the FORMULA gives the oracle (isolates formula vs upstream solve).
or<-function(p)p/(1-p)
EYaMa<-0; EYaMa0<-0; EYa0Ma0<-0
for(cc in 0:1){w<-0.5
  p1<-truep(1,cc); p0<-truep(0,cc)
  EYaMa  <- EYaMa  + w*(p1$pi*p1$g1 + (1-p1$pi)*p1$g0)         # E[Y(1,M(1))]
  EYaMa0 <- EYaMa0 + w*(p0$pi*p1$g1 + (1-p0$pi)*p1$g0)         # E[Y(1,M(0))]
  EYa0Ma0<- EYa0Ma0+ w*(p0$pi*p0$g1 + (1-p0$pi)*p0$g0)         # E[Y(0,M(0))]
}
cat(sprintf("FORMULA w/ TRUE params: NDE_OR=%.5f NIE_OR=%.5f (oracle 1.48024/1.19939)\n",
  or(EYaMa0)/or(EYa0Ma0), or(EYaMa)/or(EYaMa0)))

# Now: does bound_ne's SOLVE recover the true params from large-n observed cells?
# Reach into the internal by calling bound_ne and dumping compatible_sets params.
sim<-simulate_dm_data(n=500000,true_params=list(beta_AM=bAM,theta_AY=tAY,theta_MY=tMY),
  dm_params=list(sn0=0.9,sp0=0.9,psi_sn=1,psi_sp=1),misclass_type="mediator",confounders=1,seed=7)
df<-sim@observed
reg<-sensitivity_region(c(0.899,0.901),c(0.899,0.901),c(1.0,1.0),c(1.0,1.0))
b<-bound_ne(data=df,exposure="A",mediator="M_star",outcome="Y",confounders="C1",
  misclassified_variable="mediator",sensitivity_region=reg,n_grid=10,effect_scale="OR",verbose=FALSE)
cat(sprintf("bound_ne result: NDE[%.5f,%.5f] NIE[%.5f,%.5f]\n",b@NDE_lower,b@NDE_upper,b@NIE_lower,b@NIE_upper))
# What stratum coding does the data have? check C1 distribution & naive
cat("C1 mean:",mean(df$C1)," A mean:",mean(df$A)," Y mean:",mean(df$Y)," M* mean:",mean(df$M_star),"\n")
# TRUE params table
for(cc in 0:1)for(a in 0:1){tp<-truep(a,cc)
  cat(sprintf("  true a=%d c=%d: pi=%.4f g1=%.4f g0=%.4f\n",a,cc,tp$pi,tp$g1,tp$g0))}
cat("== instrument done ==\n")
