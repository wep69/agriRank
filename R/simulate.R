# Reproducible agricultural simulation datasets ---------------------------

#' Simulate representative agricultural experiments
#' @export
simulate_agri <- function(design = c("crd", "rcbd", "factorial", "split_plot", "split_split", "strip_plot", "repeated", "repeated_missing", "multienv"), seed = 123,
                          n = 6, missing_rate = 0.2) {
  design <- match.arg(design)
  .seed_eval(seed, switch(design,
    crd = {
      treatment <- factor(rep(LETTERS[1:4], each = n)); y <- rgamma(length(treatment), shape = 3, scale = 2) + rep(c(0,1,2,3), each=n)
      data.frame(treatment, yield = y)
    },
    rcbd = {
      block <- factor(rep(seq_len(n), each = 4)); treatment <- factor(rep(LETTERS[1:4], times = n)); y <- rgamma(length(block),3,2)+as.numeric(treatment)*0.7+as.numeric(block)*0.15
      data.frame(block,treatment,yield=y)
    },
    factorial = {
      A <- factor(rep(c("A1","A2"), each=3*n)); B <- factor(rep(rep(c("B1","B2","B3"), each=n),2)); y <- rlnorm(length(A),1,.4)+as.numeric(A)+0.5*as.numeric(B)+0.8*(A=="A2" & B=="B3")
      data.frame(A,B,yield=y)
    },
    split_plot = {
      block <- factor(rep(seq_len(n), each=6)); irrigation <- factor(rep(rep(c("low","high"), each=3), times=n)); cultivar <- factor(rep(c("C1","C2","C3"), times=2*n)); wp <- interaction(block,irrigation); u <- rnorm(length(levels(wp)),0,.8)[wp]; y <- rgamma(length(block),4,1)+1.5*(irrigation=="high")+as.numeric(cultivar)*.4+u
      data.frame(block,irrigation,cultivar,yield=y)
    },
    split_split = {
      d <- expand.grid(block = factor(seq_len(n)), irrigation = factor(c("low","high")),
                       cultivar = factor(c("C1","C2","C3")), timing = factor(c("early","late")))
      wp <- interaction(d$block, d$irrigation, drop=TRUE)
      sp <- interaction(d$block, d$irrigation, d$cultivar, drop=TRUE)
      u1 <- rnorm(nlevels(wp),0,.8)[wp]; u2 <- rnorm(nlevels(sp),0,.5)[sp]
      d$yield <- 8 + 1.4*(d$irrigation=="high") + .5*as.numeric(d$cultivar) + .7*(d$timing=="late") + u1 + u2 + rt(nrow(d),5)
      d
    },
    strip_plot = {
      d <- expand.grid(block = factor(seq_len(n)), irrigation = factor(c("low","high","medium")),
                       nitrogen = factor(c("N0","N1","N2","N3")))
      ua <- rnorm(nlevels(interaction(d$block,d$irrigation)),0,.7)[interaction(d$block,d$irrigation)]
      ub <- rnorm(nlevels(interaction(d$block,d$nitrogen)),0,.6)[interaction(d$block,d$nitrogen)]
      d$yield <- 7 + .8*as.numeric(d$irrigation) + .45*as.numeric(d$nitrogen) +
        .25*as.numeric(d$irrigation)*as.numeric(d$nitrogen) + ua + ub + rt(nrow(d),5)
      d
    },
    repeated = {
      treatment <- factor(rep(rep(c("control","treated"), each=n), each=4)); subject <- factor(rep(seq_len(2*n), each=4)); time <- factor(rep(1:4, times=2*n), ordered=TRUE); base <- rep(rnorm(2*n,10,1.5), each=4); y <- base+as.numeric(time)*.5+1.2*(treatment=="treated")*(as.numeric(time)-1)+rt(length(time),4)
      data.frame(subject,treatment,time,height=y)
    },
    repeated_missing = {
      treatment <- factor(rep(rep(c("control","treated"), each=n), each=4)); subject <- factor(rep(seq_len(2*n), each=4)); time <- factor(rep(1:4, times=2*n), ordered=TRUE); base <- rep(rnorm(2*n,10,1.5), each=4); y <- base+as.numeric(time)*.5+1.2*(treatment=="treated")*(as.numeric(time)-1)+rt(length(time),4); y[runif(length(y))<missing_rate] <- NA_real_
      data.frame(subject,treatment,time,height=y)
    },
    multienv = {
      environment <- factor(rep(c("E1","E2","E3"), each=4*n)); block <- factor(rep(rep(seq_len(n), each=4),3)); genotype <- factor(rep(LETTERS[1:4], times=3*n)); y <- rlnorm(length(environment),2,.25)+as.numeric(genotype)+as.numeric(environment)*.7+rnorm(length(environment))
      data.frame(environment,block,genotype,yield=y)
    }
  ))
}
