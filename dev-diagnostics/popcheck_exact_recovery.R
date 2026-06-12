# Population-level check: build the EXACT observed P_{y,m*|a,c} from the DGP
# (no sampling), then run the analytic §4.2 solve at the TRUE Psi.
# If the recovered (pi,gamma) and g-comp NDE equal the oracle, the DERIVATION
# and my analytic impl are exact -> any bound_ne gap is a bound_ne issue.
expit<-function(x)1/(1+exp(-x)); or<-function(p)p/(1-p)
bM<--1.5;bY<--2.0;bAM<-log(2.5);tAY<-log(1.5);tMY<-log(2.5);bC<-0.3;tC<-0.3
Sn<-0.9; Sp<-0.9   # non-differential: Sn1=Sn0=Sn, Sp1=Sp0=Sp

# True per-(a,c) causal params
trueparc<-function(a,cc) list(
  pi = expit(bM+bAM*a+bC*cc),
  g1 = expit(bY+tAY*a+tMY*1+tC*cc),
  g0 = expit(bY+tAY*a+tMY*0+tC*cc))

# Exact observed joint P(Y=y, M*=m* | a,c) under non-diff misclass:
obs_pop<-function(a,cc){p<-trueparc(a,cc)
  # P(M=1,Y=1)=pi*g1 ; P(M=0,Y=1)=(1-pi)*g0 ; etc.
  pMY<-c(M1Y1=p$pi*p$g1, M0Y1=(1-p$pi)*p$g0, M1Y0=p$pi*(1-p$g1), M0Y0=(1-p$pi)*(1-p$g0))
  # M* via Sn/Sp (non-differential, same for both Y here)
  P11<-Sn*pMY["M1Y1"]+(1-Sp)*pMY["M0Y1"]   # Y=1,M*=1
  P10<-(1-Sn)*pMY["M1Y1"]+Sp*pMY["M0Y1"]    # Y=1,M*=0
  P01<-Sn*pMY["M1Y0"]+(1-Sp)*pMY["M0Y0"]    # Y=0,M*=1
  P00<-(1-Sn)*pMY["M1Y0"]+Sp*pMY["M0Y0"]    # Y=0,M*=0
  c(P11=unname(P11),P10=unname(P10),P01=unname(P01),P00=unname(P00))}

solve_st<-function(P,Sn1,Sp1,Sn0,Sp0){
  A1<-matrix(c(Sn1,1-Sp1,1-Sn1,Sp1),2,2,byrow=TRUE);A0<-matrix(c(Sn0,1-Sp0,1-Sn0,Sp0),2,2,byrow=TRUE)
  xy1<-solve(A1,c(P["P11"],P["P10"]));xy0<-solve(A0,c(P["P01"],P["P00"]))
  x1<-xy1[1];x0<-xy1[2];z1<-xy0[1];z0<-xy0[2];pi<-x1+z1
  list(pi=pi,g1=x1/pi,g0=x0/(1-pi))}

# recover at true Psi, compare to true params; g-comp NDE
par<-list(list(),list())
for(ci in 0:1){ac<-list();for(a in 0:1){P<-obs_pop(a,ci);ac[[a+1]]<-solve_st(P,Sn,Sp,Sn,Sp)};par[[ci+1]]<-ac}
# check recovery
err<-0;for(ci in 0:1)for(a in 0:1){tp<-trueparc(a,ci);rp<-par[[ci+1]][[a+1]]
  err<-max(err,abs(tp$pi-rp$pi),abs(tp$g1-rp$g1),abs(tp$g0-rp$g0))}
cat(sprintf("max |recovered - true| (pi,g1,g0) at true Psi = %.2e\n",err))
Eyf<-function(a,mf){t<-0;for(ci in 0:1){p<-par[[ci+1]];pm<-p[[mf+1]]$pi
  t<-t+0.5*(pm*p[[a+1]]$g1+(1-pm)*p[[a+1]]$g0)};t}
cat(sprintf("analytic@truePsi (POP, exact): NDE_OR=%.5f NIE_OR=%.5f\n",
  or(Eyf(1,0))/or(Eyf(0,0)), or(Eyf(1,1))/or(Eyf(1,0))))
cat("oracle was NDE_OR=1.48024 NIE_OR=1.19939\n== popcheck done ==\n")
