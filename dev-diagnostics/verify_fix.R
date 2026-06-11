# Verify (1) the current 3x3 system is wrong, (2) the proposed two-2x2 fix is exact.
expit<-function(x)1/(1+exp(-x))
# pick arbitrary true params + non-trivial Sn/Sp (differential to be general)
pi<-0.35; g1<-0.42; g0<-0.18
sn1<-0.88; sp1<-0.93; sn0<-0.80; sp0<-0.85   # Y-dependent (differential)

# Exact observed cells from the true model
P11 <- sn1*g1*pi + (1-sp1)*g0*(1-pi)
P10 <- (1-sn1)*g1*pi + sp1*g0*(1-pi)
P01 <- sn0*(1-g1)*pi + (1-sp0)*(1-g0)*(1-pi)
P00 <- (1-sn0)*(1-g1)*pi + sp0*(1-g0)*(1-pi)
cat(sprintf("cells sum to %.6f (should be 1)\n", P11+P10+P01+P00))

## --- (1) CURRENT code's 3x3 system ---
A<-matrix(c(sn1,(1-sp1),0, (1-sn1),sp1,0, 0,0,sn0),3,3,byrow=TRUE)
A[3,3]<-sn0; A[3,2]<-(1-sp0)
b<-c(P11,P10,P01)
th<-solve(A,b)
pi_c<-th[1]+th[3]; g1_c<-th[1]/pi_c; g0_c<-th[2]/(1-pi_c)
cat(sprintf("CURRENT 3x3:  pi=%.4f (true %.4f) g1=%.4f (true %.4f) g0=%.4f (true %.4f)\n",
  pi_c,pi,g1_c,g1,g0_c,g0))

## --- (2) PROPOSED two-2x2 systems ---
# Y=1: P11=sn1*x1+(1-sp1)*x0 ; P10=(1-sn1)*x1+sp1*x0 ; x1=pi*g1, x0=(1-pi)*g0
# Y=0: P01=sn0*z1+(1-sp0)*z0 ; P00=(1-sn0)*z1+sp0*z0 ; z1=pi*(1-g1), z0=(1-pi)*(1-g0)
A1<-matrix(c(sn1,1-sp1, 1-sn1,sp1),2,2,byrow=TRUE)
A0<-matrix(c(sn0,1-sp0, 1-sn0,sp0),2,2,byrow=TRUE)
xy1<-solve(A1,c(P11,P10)); xy0<-solve(A0,c(P01,P00))
x1<-xy1[1];x0<-xy1[2];z1<-xy0[1];z0<-xy0[2]
pi_f<-x1+z1; g1_f<-x1/pi_f; g0_f<-x0/(1-pi_f)
cat(sprintf("FIX two-2x2:  pi=%.6f g1=%.6f g0=%.6f | max err=%.2e\n",
  pi_f,g1_f,g0_f, max(abs(c(pi_f-pi,g1_f-g1,g0_f-g0)))))
# consistency: z0 should equal (1-pi)*(1-g0)
cat(sprintf("  check z0=(1-pi)(1-g0): %.6f vs %.6f ; pi from x1+z1 vs x0+z0: %.6f / %.6f\n",
  z0,(1-pi)*(1-g0), x1+z1, 1-(x0+z0)))
cat("== verify_fix done ==\n")
