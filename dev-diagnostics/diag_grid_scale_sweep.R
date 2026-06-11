setwd("/Users/dt/projects/r-packages/active/medrobust")
suppressWarnings(suppressMessages(pkgload::load_all(".", quiet=TRUE)))
expit<-function(x) 1/(1+exp(-x))

## ---- DGP params (must match simulate_dm_data defaults) ----
bM<--1.5; bY<--2.0; bAM<-log(2.5); tAY<-log(1.5); tMY<-log(2.5)
bC<-0.3; tC<-0.3; ic<-0          # interaction_coef default 0

## ---- CORRECT truth: average outcome over M dist, then over C ----
EY<-function(a,aprime){ tot<-0
  for(cc in 0:1){ pc<-0.5
    piM<-expit(bM+bAM*aprime+bC*cc)
    g1<-expit(bY+tAY*a+tMY*1+ic*a*1+tC*cc)
    g0<-expit(bY+tAY*a+tMY*0+ic*a*0+tC*cc)
    tot<-tot+pc*(piM*g1+(1-piM)*g0) }; tot }
or<-function(p) p/(1-p)
Y10<-EY(1,0); Y00<-EY(0,0); Y11<-EY(1,1)
NDE_true<-or(Y10)/or(Y00); NIE_true<-or(Y11)/or(Y10)

## ---- independent analytic bound (manuscript 4.2), reused from diag.R ----
solve_stratum<-function(P11,P10,P01,P00,Sn1,Sp1,Sn0,Sp0){
  A1<-matrix(c(Sn1,1-Sp1,1-Sn1,Sp1),2,2,byrow=TRUE)
  A0<-matrix(c(Sn0,1-Sp0,1-Sn0,Sp0),2,2,byrow=TRUE)
  if(abs(det(A1))<1e-10||abs(det(A0))<1e-10)return(NULL)
  xy1<-solve(A1,c(P11,P10)); xy0<-solve(A0,c(P01,P00))
  x1<-xy1[1];x0<-xy1[2];z1<-xy0[1];z0<-xy0[2]; pi<-x1+z1
  if(pi<=1e-8||pi>=1-1e-8)return(NULL)
  g1<-x1/pi; g0<-x0/(1-pi)
  if(any(c(pi,g1,g0)< -1e-6 | c(pi,g1,g0)>1+1e-6))return(NULL)
  list(pi=pi,g1=min(max(g1,0),1),g0=min(max(g0,0),1)) }
gcomp_or<-function(par,pc){ Eyf<-function(a,mf){tot<-0
    for(ci in 0:1){p<-par[[ci+1]]; pm<-p[[mf+1]]$pi
      tot<-tot+pc[ci+1]*(pm*p[[a+1]]$g1+(1-pm)*p[[a+1]]$g0)}; tot}
  y10<-Eyf(1,0);y00<-Eyf(0,0);y11<-Eyf(1,1)
  c(NDE=or(y10)/or(y00), NIE=or(y11)/or(y10)) }
analytic<-function(df,sn0g,sp0g,psg,ppg){
  pc<-c(mean(df$C1==0),mean(df$C1==1)); obs<-list()
  for(ci in 0:1)for(a in 0:1){d<-df[df$C1==ci&df$A==a,]
    obs[[paste(ci,a)]]<-c(P11=mean(d$Y==1&d$M_star==1),P10=mean(d$Y==1&d$M_star==0),
      P01=mean(d$Y==0&d$M_star==1),P00=mean(d$Y==0&d$M_star==0))}
  NDEs<-c();NIEs<-c()
  for(sn0 in sn0g)for(sp0 in sp0g)for(ps in psg)for(pp in ppg){
    o2p<-function(p0,psi){o<-p0/(1-p0)*psi;o/(1+o)}
    Sn1<-o2p(sn0,ps);Sp1<-o2p(sp0,pp)
    par<-list(list(),list());ok<-TRUE
    for(ci in 0:1){ac<-list();for(a in 0:1){P<-obs[[paste(ci,a)]]
      s<-solve_stratum(P["P11"],P["P10"],P["P01"],P["P00"],Sn1,Sp1,sn0,sp0)
      if(is.null(s)){ok<-FALSE;break};ac[[a+1]]<-s};if(!ok)break;par[[ci+1]]<-ac}
    if(!ok)next; e<-gcomp_or(par,pc)
    if(all(is.finite(e))){NDEs<-c(NDEs,e["NDE"]);NIEs<-c(NIEs,e["NIE"])}}
  list(NDE=range(NDEs),NIE=range(NIEs),k=length(NDEs)) }

cat(sprintf("CORRECT truth:  NDE_OR=%.4f  NIE_OR=%.4f\n",NDE_true,NIE_true))
for(N in c(20000, 200000)){
  sim<-simulate_dm_data(n=N,
    true_params=list(beta_AM=bAM,theta_AY=tAY,theta_MY=tMY),
    dm_params=list(sn0=0.9,sp0=0.9,psi_sn=1,psi_sp=1),
    misclass_type="mediator",confounders=1,seed=7)
  df<-sim@observed
  # tight region centered AT the true baseline so true Psi is interior
  ab<-analytic(df, sn0g=seq(0.88,0.92,by=0.02), sp0g=seq(0.88,0.92,by=0.02),
               psg=1.0, ppg=1.0)
  reg<-sensitivity_region(c(0.88,0.92),c(0.88,0.92),c(1.0,1.0),c(1.0,1.0))
  b<-bound_ne(data=df,exposure="A",mediator="M_star",outcome="Y",confounders="C1",
    misclassified_variable="mediator",sensitivity_region=reg,n_grid=60,
    effect_scale="OR",verbose=FALSE)
  cat(sprintf("\n[N=%d]\n",N))
  cat(sprintf("  analytic NDE[%.4f,%.4f] NIE[%.4f,%.4f] k=%d | true in? NDE=%s NIE=%s\n",
    ab$NDE[1],ab$NDE[2],ab$NIE[1],ab$NIE[2],ab$k,
    NDE_true>=ab$NDE[1]&&NDE_true<=ab$NDE[2], NIE_true>=ab$NIE[1]&&NIE_true<=ab$NIE[2]))
  cat(sprintf("  bound_ne NDE[%.4f,%.4f] NIE[%.4f,%.4f] | true in? NDE=%s NIE=%s\n",
    b@NDE_lower,b@NDE_upper,b@NIE_lower,b@NIE_upper,
    NDE_true>=b@NDE_lower&&NDE_true<=b@NDE_upper, NIE_true>=b@NIE_lower&&NIE_true<=b@NIE_upper))
}
cat("\n== diag3 done ==\n")
