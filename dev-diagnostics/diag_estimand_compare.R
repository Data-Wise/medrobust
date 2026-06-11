setwd("/Users/dt/projects/r-packages/active/medrobust")
suppressWarnings(suppressMessages(pkgload::load_all(".", quiet=TRUE)))
expit<-function(x) 1/(1+exp(-x))

# DGP params (defaults used by simulate_dm_data)
bM<--1.5; bY<--2.0; bAM<-log(2.5); tAY<-log(1.5); tMY<-log(2.5)
bC<-0.3; tC<-0.3; aC<-0.3   # confounder effects (binary C, p=0.5)

# Correct natural-effect g-computation for binary M, binary C:
# E[Y(a, M(a'))] = sum_c P(c) sum_m P(M=m|a',c) * P(Y=1|a,m,c)
Ey<-function(a,aprime){
  tot<-0
  for(cc in 0:1){ pc<-0.5
    piM <- expit(bM + bAM*aprime + bC*cc)          # P(M=1|a',c)
    g1  <- expit(bY + tAY*a + tMY*1 + tC*cc)        # P(Y=1|a,M=1,c)
    g0  <- expit(bY + tAY*a + tMY*0 + tC*cc)        # P(Y=1|a,M=0,c)
    tot <- tot + pc*(piM*g1 + (1-piM)*g0)
  }; tot
}
Y10<-Ey(1,0); Y00<-Ey(0,0); Y11<-Ey(1,1)
or<-function(p) p/(1-p)
NDE_correct <- or(Y10)/or(Y00)
NIE_correct <- or(Y11)/or(Y10)

sim<-simulate_dm_data(n=4000,
  true_params=list(beta_AM=bAM,theta_AY=tAY,theta_MY=tMY),
  dm_params=list(sn0=0.9,sp0=0.9,psi_sn=1,psi_sp=1),
  misclass_type="mediator",confounders=1,seed=7)
te<-sim@true_effects
cat(sprintf("package  NDE_OR=%.4f  NIE_OR=%.4f  (plug-in-mean-M formula)\n", te$NDE_OR, te$NIE_OR))
cat(sprintf("correct  NDE_OR=%.4f  NIE_OR=%.4f  (average over M distribution)\n", NDE_correct, NIE_correct))
cat(sprintf("difference NDE: %.4f\n", te$NDE_OR-NDE_correct))
