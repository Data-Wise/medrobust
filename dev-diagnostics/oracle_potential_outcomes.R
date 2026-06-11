# Ground-truth NDE/NIE by DIRECT potential-outcome simulation (no formula).
# This is the unimpeachable oracle. Matches simulate_dm_data's DGP structure.
expit <- function(x) 1/(1+exp(-x))
set.seed(99)

bM<--1.5; bY<--2.0; bAM<-log(2.5); tAY<-log(1.5); tMY<-log(2.5)
bC<-0.3; tC<-0.3; aC<-0.3; ic<-0
N <- 5e6

C <- rbinom(N,1,0.5)
# potential mediators M(a) for a=0,1
pM0 <- expit(bM + bAM*0 + bC*C);  M0 <- rbinom(N,1,pM0)
pM1 <- expit(bM + bAM*1 + bC*C);  M1 <- rbinom(N,1,pM1)
# potential outcome Y(a,m) mean given (a,m,C)
muY <- function(a,m) expit(bY + tAY*a + tMY*m + ic*a*m + tC*C)
# E[Y(a, M(astar))] via plug-in of the COUNTERFACTUAL mediator draw
EYpo <- function(a, Mstar) mean(muY(a, Mstar))

Y10 <- EYpo(1, M0)   # Y(1, M(0))
Y00 <- EYpo(0, M0)   # Y(0, M(0))
Y11 <- EYpo(1, M1)   # Y(1, M(1))
or <- function(p) p/(1-p)
cat(sprintf("ORACLE  E[Y(1,M0)]=%.5f E[Y(0,M0)]=%.5f E[Y(1,M1)]=%.5f\n", Y10,Y00,Y11))
cat(sprintf("ORACLE  NDE_OR=%.5f  NIE_OR=%.5f  NDE_RD=%.5f  NIE_RD=%.5f\n",
  or(Y10)/or(Y00), or(Y11)/or(Y10), Y10-Y00, Y11-Y10))

# --- compare the three FORMULAS against the oracle ---
# (a) simulator's plug-in-mean (collapses M and C to means)
Cbar<-0.5
pM1m<-expit(bM+bAM+bC*Cbar); pM0m<-expit(bM+bC*Cbar)
 a_Y11<-expit(bY+tAY+tMY*pM1m+tC*Cbar); a_Y10<-expit(bY+tAY+tMY*pM0m+tC*Cbar); a_Y00<-expit(bY+tMY*pM0m+tC*Cbar)
cat(sprintf("(a) plug-in-mean   NDE_OR=%.5f NIE_OR=%.5f\n", or(a_Y10)/or(a_Y00), or(a_Y11)/or(a_Y10)))

# (b) correct g-comp: average over m AND over c
gEY<-function(a,ap){t<-0;for(cc in 0:1){pc<-0.5
  piM<-expit(bM+bAM*ap+bC*cc); g1<-expit(bY+tAY*a+tMY+tC*cc); g0<-expit(bY+tAY*a+tC*cc)
  t<-t+pc*(piM*g1+(1-piM)*g0)};t}
cat(sprintf("(b) g-comp avg m,c NDE_OR=%.5f NIE_OR=%.5f\n", or(gEY(1,0))/or(gEY(0,0)), or(gEY(1,1))/or(gEY(1,0))))

# (c) g-comp but averaging M over c THEN collapsing (mimic possible bound_ne convention)
#     i.e. use marginal P(M=1|a) = mean over c, then average outcome over c
pM1_marg<-mean(expit(bM+bAM+bC*C)); pM0_marg<-mean(expit(bM+bC*C))
cEY<-function(a,pm){t<-0;for(cc in 0:1){pc<-0.5
  g1<-expit(bY+tAY*a+tMY+tC*cc); g0<-expit(bY+tAY*a+tC*cc)
  t<-t+pc*(pm*g1+(1-pm)*g0)};t}
cat(sprintf("(c) marginal-M,avg c NDE_OR=%.5f NIE_OR=%.5f\n",
  or(cEY(1,pM0_marg))/or(cEY(0,pM0_marg)), or(cEY(1,pM1_marg))/or(cEY(1,pM0_marg))))
cat("== oracle done ==\n")
