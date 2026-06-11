setwd("/Users/dt/projects/r-packages/active/medrobust")
suppressWarnings(suppressMessages(pkgload::load_all(".", quiet = TRUE)))

# ============================================================
# Independent analytic bound for MEDIATOR misclassification,
# implementing manuscript section 4.2 EXACTLY, in base R.
# Single binary confounder C1 -> stratify by c in {0,1}.
# For each stratum & a, solve the 3x3 linear system for
# (pi_a, gamma_a1, gamma_a0) given Psi, then g-compute NDE/NIE (OR).
# ============================================================

expit <- function(x) 1/(1+exp(-x))

# Solve true causal params from observed P_{y,m*} given Sn_y, Sp_y.
# Unknowns: pi (P(M=1|a,c)), g1 (P(Y=1|M=1,a,c)), g0 (P(Y=1|M=0,a,c)).
# Observed (4 eqs, 3 indep):
#  P11 = Sn1 g1 pi + (1-Sp1) g0 (1-pi)
#  P10 = (1-Sn1) g1 pi + Sp1 g0 (1-pi)
#  P01 = Sn0 (1-g1) pi + (1-Sp0)(1-g0)(1-pi)
#  P00 = (1-Sn0)(1-g1) pi + Sp0 (1-g0)(1-pi)
# Strategy: marginal M among (a,c): from rows summing over Y.
#   P(M*=1|a,c) = P11+P01 ;  these relate to pi via Sn/Sp mixing.
# Define u = P(M=1,a,c)=pi, solve via the M*-marginal then Y-conditionals.
solve_stratum <- function(P11,P10,P01,P00, Sn1,Sp1,Sn0,Sp0) {
  # M* marginal: P(M*=1) = Sn_mix*pi + (1-Sp_mix)*(1-pi) is Y-dependent,
  # so we cannot collapse over Y. Instead solve the full system directly.
  # Let x1 = g1*pi (=P(M=1,Y=1)), x0 = g0*(1-pi) (=P(M=0,Y=1)),
  #     z1 = (1-g1)*pi (=P(M=1,Y=0)), z0=(1-g0)*(1-pi)(=P(M=0,Y=0)).
  # Then: P11 = Sn1 x1 + (1-Sp1) x0
  #       P10 = (1-Sn1) x1 + Sp1 x0
  #       P01 = Sn0 z1 + (1-Sp0) z0
  #       P00 = (1-Sn0) z1 + Sp0 z0
  # Two independent 2x2 systems:
  A_y1 <- matrix(c(Sn1, 1-Sp1, 1-Sn1, Sp1), 2, 2, byrow=TRUE)
  A_y0 <- matrix(c(Sn0, 1-Sp0, 1-Sn0, Sp0), 2, 2, byrow=TRUE)
  if (abs(det(A_y1))<1e-10 || abs(det(A_y0))<1e-10) return(NULL)
  xy1 <- solve(A_y1, c(P11,P10))   # (x1, x0)
  xy0 <- solve(A_y0, c(P01,P00))   # (z1, z0)
  x1<-xy1[1]; x0<-xy1[2]; z1<-xy0[1]; z0<-xy0[2]
  pi  <- x1 + z1                    # P(M=1)
  if (pi<=1e-8 || pi>=1-1e-8) return(NULL)
  g1 <- x1/pi                       # P(Y=1|M=1)
  g0 <- x0/(1-pi)                   # P(Y=1|M=0)
  vals <- c(pi,g1,g0)
  if (any(vals< -1e-6 | vals>1+1e-6)) return(NULL)   # compatibility check
  list(pi=pi,g1=pmin(pmax(g1,0),1),g0=pmin(pmax(g0,0),1))
}

# NDE/NIE on OR scale via g-computation, given per-(a,c) params, P(c).
gcomp_or <- function(par, pc) {
  # par[[c+1]][[a+1]] = list(pi,g1,g0)
  Ey <- function(a, m_from) {
    # E[Y(a, M(m_from))] = sum_c P(c) * sum_m P(M=m|m_from,c)*g_{a,m}(c)
    tot<-0
    for(ci in 0:1){ p<-par[[ci+1]]
      pm1 <- p[[m_from+1]]$pi
      g1<-p[[a+1]]$g1; g0<-p[[a+1]]$g0
      tot <- tot + pc[ci+1]*(pm1*g1 + (1-pm1)*g0)
    }; tot
  }
  Y10 <- Ey(1,0); Y00 <- Ey(0,0); Y11 <- Ey(1,1)
  NDE_OR <- (Y10/(1-Y10))/(Y00/(1-Y00))
  NIE_OR <- (Y11/(1-Y11))/(Y10/(1-Y10))
  c(NDE_OR=NDE_OR, NIE_OR=NIE_OR)
}

analytic_bounds <- function(df, sn0_grid, sp0_grid, psi_sn_grid, psi_sp_grid){
  pc <- c(mean(df$C1==0), mean(df$C1==1))
  # observed P_{y,m*} per (a,c)
  obs <- list()
  for(ci in 0:1) for(a in 0:1){
    d <- df[df$C1==ci & df$A==a,]
    n<-nrow(d)
    obs[[paste(ci,a)]] <- c(
      P11=mean(d$Y==1 & d$M_star==1), P10=mean(d$Y==1 & d$M_star==0),
      P01=mean(d$Y==0 & d$M_star==1), P00=mean(d$Y==0 & d$M_star==0))
  }
  NDEs<-c(); NIEs<-c()
  for(sn0 in sn0_grid) for(sp0 in sp0_grid)
   for(ps in psi_sn_grid) for(pp in psi_sp_grid){
    # psi defines Sn1,Sp1 from baseline via OR
    o2p <- function(p0,psi){ o<-p0/(1-p0)*psi; o/(1+o) }
    Sn1<-o2p(sn0,ps); Sp1<-o2p(sp0,pp); Sn0<-sn0; Sp0<-sp0
    par<-list(list(),list()); ok<-TRUE
    for(ci in 0:1){ ac<-list()
      for(a in 0:1){
        P<-obs[[paste(ci,a)]]
        s<-solve_stratum(P["P11"],P["P10"],P["P01"],P["P00"],Sn1,Sp1,Sn0,Sp0)
        if(is.null(s)){ok<-FALSE;break}; ac[[a+1]]<-s
      }; if(!ok)break; par[[ci+1]]<-ac }
    if(!ok) next
    e<-gcomp_or(par,pc)
    if(all(is.finite(e))){NDEs<-c(NDEs,e["NDE_OR"]); NIEs<-c(NIEs,e["NIE_OR"])}
  }
  list(NDE=range(NDEs), NIE=range(NIEs), n_compatible=length(NDEs))
}

# ---- Generate ONE cell, psi=1, true baseline INSIDE region ----
sn0<-0.9; sp0<-0.9
sim <- simulate_dm_data(n=4000,
  true_params=list(beta_AM=log(2.5), theta_AY=log(1.5), theta_MY=log(2.5)),
  dm_params=list(sn0=sn0,sp0=sp0,psi_sn=1.0,psi_sp=1.0),
  misclass_type="mediator", confounders=1, seed=7)
df<-sim@observed; te<-sim@true_effects
cat(sprintf("TRUE  NDE_OR=%.4f  NIE_OR=%.4f\n", te$NDE_OR, te$NIE_OR))

# Analytic bound over a region that CONTAINS the truth (psi in [1,1])
ab <- analytic_bounds(df,
  sn0_grid=seq(0.85,0.95,by=0.025), sp0_grid=seq(0.85,0.95,by=0.025),
  psi_sn_grid=1.0, psi_sp_grid=1.0)
cat(sprintf("ANALYTIC NDE[%.4f, %.4f]  NIE[%.4f, %.4f]  (compat sets=%d)\n",
  ab$NDE[1],ab$NDE[2],ab$NIE[1],ab$NIE[2],ab$n_compatible))
cat(sprintf("  -> truth in analytic NDE? %s   NIE? %s\n",
  te$NDE_OR>=ab$NDE[1]&&te$NDE_OR<=ab$NDE[2],
  te$NIE_OR>=ab$NIE[1]&&te$NIE_OR<=ab$NIE[2]))

# Same data through medrobust::bound_ne
reg <- sensitivity_region(c(0.85,0.95),c(0.85,0.95),c(1.0,1.0),c(1.0,1.0))
b <- bound_ne(data=df, exposure="A", mediator="M_star", outcome="Y",
  confounders="C1", misclassified_variable="mediator",
  sensitivity_region=reg, n_grid=40, effect_scale="OR", verbose=FALSE)
cat(sprintf("BOUND_NE NDE[%.4f, %.4f]  NIE[%.4f, %.4f]\n",
  b@NDE_lower,b@NDE_upper,b@NIE_lower,b@NIE_upper))
cat(sprintf("  -> truth in bound_ne NDE? %s   NIE? %s\n",
  te$NDE_OR>=b@NDE_lower&&te$NDE_OR<=b@NDE_upper,
  te$NIE_OR>=b@NIE_lower&&te$NIE_OR<=b@NIE_upper))
cat("== DIAG DONE ==\n")
