setwd("/Users/dt/projects/r-packages/active/medrobust")
suppressWarnings(suppressMessages(pkgload::load_all(".", quiet=TRUE)))
expit<-function(x) 1/(1+exp(-x)); or<-function(p) p/(1-p)
bM<--1.5;bY<--2.0;bAM<-log(2.5);tAY<-log(1.5);tMY<-log(2.5);bC<-0.3;tC<-0.3
EY<-function(a,ap){t<-0;for(cc in 0:1){pc<-0.5
  piM<-expit(bM+bAM*ap+bC*cc);g1<-expit(bY+tAY*a+tMY+tC*cc);g0<-expit(bY+tAY*a+tC*cc)
  t<-t+pc*(piM*g1+(1-piM)*g0)};t}
NDE_true<-or(EY(1,0))/or(EY(0,0)); NIE_true<-or(EY(1,1))/or(EY(1,0))

solve_stratum<-function(P11,P10,P01,P00,Sn1,Sp1,Sn0,Sp0){
  A1<-matrix(c(Sn1,1-Sp1,1-Sn1,Sp1),2,2,byrow=TRUE);A0<-matrix(c(Sn0,1-Sp0,1-Sn0,Sp0),2,2,byrow=TRUE)
  if(abs(det(A1))<1e-10||abs(det(A0))<1e-10)return(NULL)
  xy1<-solve(A1,c(P11,P10));xy0<-solve(A0,c(P01,P00));x1<-xy1[1];x0<-xy1[2];z1<-xy0[1];z0<-xy0[2];pi<-x1+z1
  if(pi<=1e-8||pi>=1-1e-8)return(NULL);g1<-x1/pi;g0<-x0/(1-pi)
  if(any(c(pi,g1,g0)< -1e-6|c(pi,g1,g0)>1+1e-6))return(NULL)
  list(pi=pi,g1=min(max(g1,0),1),g0=min(max(g0,0),1))}
analytic<-function(df,sn0g,sp0g){pc<-c(mean(df$C1==0),mean(df$C1==1));obs<-list()
  for(ci in 0:1)for(a in 0:1){d<-df[df$C1==ci&df$A==a,]
    obs[[paste(ci,a)]]<-c(mean(d$Y==1&d$M_star==1),mean(d$Y==1&d$M_star==0),mean(d$Y==0&d$M_star==1),mean(d$Y==0&d$M_star==0))}
  N<-c();I<-c()
  for(sn0 in sn0g)for(sp0 in sp0g){par<-list(list(),list());ok<-TRUE
    for(ci in 0:1){ac<-list();for(a in 0:1){P<-obs[[paste(ci,a)]]
      s<-solve_stratum(P[1],P[2],P[3],P[4],sn0,sp0,sn0,sp0);if(is.null(s)){ok<-FALSE;break};ac[[a+1]]<-s};if(!ok)break;par[[ci+1]]<-ac}
    if(!ok)next
    Eyf<-function(a,mf){t<-0;for(ci in 0:1){p<-par[[ci+1]];pm<-p[[mf+1]]$pi;t<-t+pc[ci+1]*(pm*p[[a+1]]$g1+(1-pm)*p[[a+1]]$g0)};t}
    N<-c(N,or(Eyf(1,0))/or(Eyf(0,0)));I<-c(I,or(Eyf(1,1))/or(Eyf(1,0)))}
  list(NDE=range(N),NIE=range(I),k=length(N))}

# population-scale data, DENSE grid centered exactly on true baseline 0.9
sim<-simulate_dm_data(n=300000,true_params=list(beta_AM=bAM,theta_AY=tAY,theta_MY=tMY),
  dm_params=list(sn0=0.9,sp0=0.9,psi_sn=1,psi_sp=1),misclass_type="mediator",confounders=1,seed=7)
df<-sim@observed
ab<-analytic(df, sn0g=seq(0.88,0.92,by=0.005), sp0g=seq(0.88,0.92,by=0.005))
cat(sprintf("CORRECT truth NDE=%.4f NIE=%.4f\n",NDE_true,NIE_true))
cat(sprintf("analytic(dense,k=%d) NDE[%.4f,%.4f] NIE[%.4f,%.4f] | true in NDE=%s NIE=%s\n",
  ab$k,ab$NDE[1],ab$NDE[2],ab$NIE[1],ab$NIE[2],
  NDE_true>=ab$NDE[1]&&NDE_true<=ab$NDE[2], NIE_true>=ab$NIE[1]&&NIE_true<=ab$NIE[2]))
# point check: at the EXACT true Psi (0.9,0.9), analytic should return truth
ab0<-analytic(df, sn0g=0.9, sp0g=0.9)
cat(sprintf("analytic@truePsi NDE=%.4f (should equal %.4f) NIE=%.4f (should equal %.4f)\n",
  ab0$NDE[1],NDE_true,ab0$NIE[1],NIE_true))
cat("== diag4 done ==\n")
