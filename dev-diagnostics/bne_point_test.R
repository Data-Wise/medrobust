setwd("/Users/dt/projects/r-packages/active/medrobust")
suppressWarnings(suppressMessages(pkgload::load_all(".", quiet=TRUE)))
expit<-function(x)1/(1+exp(-x))
bM<--1.5;bY<--2.0;bAM<-log(2.5);tAY<-log(1.5);tMY<-log(2.5);bC<-0.3;tC<-0.3
# large n so observed cells ~ population; true Psi exactly (0.9,0.9,psi=1)
sim<-simulate_dm_data(n=500000,true_params=list(beta_AM=bAM,theta_AY=tAY,theta_MY=tMY),
  dm_params=list(sn0=0.9,sp0=0.9,psi_sn=1,psi_sp=1),misclass_type="mediator",confounders=1,seed=7)
df<-sim@observed
# DEGENERATE region = exactly the true Psi (single point)
reg<-sensitivity_region(c(0.899,0.901),c(0.899,0.901),c(1.0,1.0),c(1.0,1.0))
b<-bound_ne(data=df,exposure="A",mediator="M_star",outcome="Y",confounders="C1",
  misclassified_variable="mediator",sensitivity_region=reg,n_grid=10,
  effect_scale="OR",verbose=FALSE)
cat(sprintf("bound_ne @ degenerate true Psi: NDE[%.5f,%.5f] NIE[%.5f,%.5f]\n",
  b@NDE_lower,b@NDE_upper,b@NIE_lower,b@NIE_upper))
cat("oracle/correct: NDE_OR=1.48024  NIE_OR=1.19939\n")
# also try RD scale to see if OR conversion is the culprit
b2<-bound_ne(data=df,exposure="A",mediator="M_star",outcome="Y",confounders="C1",
  misclassified_variable="mediator",sensitivity_region=reg,n_grid=10,
  effect_scale="RD",verbose=FALSE)
cat(sprintf("bound_ne RD @ true Psi: NDE[%.5f,%.5f] NIE[%.5f,%.5f]  (oracle NDE_RD=0.06197 NIE_RD=0.03371)\n",
  b2@NDE_lower,b2@NDE_upper,b2@NIE_lower,b2@NIE_upper))
cat("== bne_point done ==\n")
