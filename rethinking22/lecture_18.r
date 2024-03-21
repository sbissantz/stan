#
# Lecture 18 (Missing data)
#

# Draw DAGs on paper before simulating!

# Dog eats random homework (MCAR)
set.seed(112)
N <- 1e2 # 100 students
S <- rnorm(N) # Study time (standardized)
D <- rbinom(N, 1, 0.5) # Missingness indicator
H <- rnorm(N, 0.6 * S) # Effect: S -> H (more studying; more quality)
# Dog eats 80% of the homework at random
Hstar <- H
Hstar[D == 1] <- NA
Hstar
# Visualize
plot(S, H, col = "steelblue", lwd = 2)
points(S, Hstar, col = 2 , lwd = 3)
# True effect: S -> H (unobserved)
abline(lm(H ~ S), lwd = 3 , col = "steelblue")
# Estimated effect: S -> Hstar (partially observed)
abline(lm(Hstar ~ S), lwd = 3, col = 2)

# Dog eats homework of students how study too much (MAR)
# Conditional on student
set.seed(112)
N <- 1e2
S <- rnorm(N) # Study effort in time
H <- rnorm(N, 0.8*S) # Asm: Linear effect!
D <- ifelse(S > 0, 1, 0) #...if student studies more than average – eat!
Hstar <- H
Hstar[D == 1] <- NA
# Visualize
plot(S, H, col = "steelblue", lwd = 2)
points(S, Hstar, col = 2 , lwd = 3)
# True effect: S -> H (unobserved)
abline(lm(H ~ S), lwd = 3 , col = "steelblue")
# Estimated effect: S -> Hstar (partially observed)
abline(lm(Hstar ~ S), lwd = 3, col = 2)

# Dog eats homework of students how study too much (MAR)
# NONLINEAR-CEILING EFFECT
set.seed(112)
N <- 1e2
S <- rnorm(N) # Study effort in time
H <- rnorm(N, 1-exp(-0.7*S)) # Asm: Noninear effect!
D <- ifelse(S > 0, 1, 0) #...if student studies more than average – eat!
Hstar <- H
Hstar[D == 1] <- NA
# Visualize
plot(S, H, col = "steelblue", lwd = 2)
points(S, Hstar, col = 2 , lwd = 3)
# True effect: S -> H (unobserved)
abline(lm(H ~ S), lwd = 3 , col = "steelblue")
# Estimated effect: S -> Hstar (partially observed)
abline(lm(Hstar ~ S), lwd = 3, col = 2) # Boooom!

# Dog eats bad homework (MNAR)
# Conditional on homework
N <- 1e2
S <- rnorm(N) # Study effort in time
H <- rnorm(N, 0.7*S) # Asm: Linear effect!
D <- ifelse(H < 0, 1, 0) #...if homework are worse than average – feed to dog
Hstar <- H
Hstar[D == 1] <- NA
# Visualize
plot(S, H, col = "steelblue", lwd = 2)
points(S, Hstar, col = 2 , lwd = 3)
# True effect: S -> H (unobserved)
abline(lm(H ~ S), lwd = 3 , col = "steelblue")
# Estimated effect: S -> Hstar (partially observed)
abline(lm(Hstar ~ S), lwd = 3, col = 2) # Boooom!

#
# Primated Phylogeny
# Moving from complete cases to imputation
#
library(rethinking)
library(ape)
data(Primates301) ; data(Primates301_nex)
d <- Primates301
d$name <- as.character(d$name)

# Complete case analysis (1a.stan)

# Data
dcc <- d[complete.cases(d$group_size, d$body, d$brain), ]
spp <- dcc$name
# Phylogeny
spp <- as.character(dcc$name)
tree_trimmed <- keep.tip(Primates301_nex, spp)
Rbm <- corBrownian(phy = tree_trimmed)
V <- vcv(Rbm)
Dmat <- cophenetic(tree_trimmed)

# Stan list
stan_ls <- list(
    N = nrow(dcc),
    M = standardize(log(dcc$body)),
    B = standardize(log(dcc$brain)),
    G = standardize(log(dcc$group_size)),
    Dmat = Dmat[spp, spp] / max(Dmat)
)

# Stan model
path <- "~/projects/rethinking/rethinking22"
file <- file.path(path, "stan", "18", "1a.stan")
mdl <- cmdstanr::cmdstan_model(file, pedantic = TRUE)
fit <- mdl$sample(data=stan_ls, parallel_chains = 4)
fit$cmdstan_diagnose()

# Posterior
draws1a <- fit$draws(format = "data.frame")

# Visualize
plot(density(draws1a$bG), lwd = 3, col = "steelblue", xlab = "effect of G on B",
ylim = c(0, 25)) 
abline(v = 0, lty = 3)

# Impute group size and body mass (1b.stan)

# Data
dd <- d[complete.cases(d$brain),]
spp <- dd$name
# Phylogeny
spp <- as.character(dd$name)
tree_trimmed <- keep.tip(Primates301_nex, spp)
Rbm <- corBrownian(phy = tree_trimmed)
V <- vcv(Rbm)
Dmat <- cophenetic(tree_trimmed)


stan_ls <- list(
    N = nrow(dd),
    # Impute G
    N_G_obs = sum(complete.cases(dd$group_size)),
    N_G_mis = sum(is.na(dd$group_size)),
    G_obs = standardize(log(dd$group_size[complete.cases(dd$group_size)])),
    ii_G_obs = which(complete.cases(dd$group_size)),
    ii_G_mis = which(is.na(dd$group_size)),
    # Impute B
    N_M_obs = sum(complete.cases(dd$body)),
    N_M_mis = sum(is.na(dd$body)),
    M_obs = standardize(log(dd$body[complete.cases(dd$body)])),
    ii_M_obs = which(complete.cases(dd$body)),
    ii_M_mis = which(is.na(dd$body)),
    # Oldje stuff 
    B = standardize(log(dd$brain)),
    Dmat = Dmat[spp, spp] / max(Dmat)
)

# Stan model
path <- "~/projects/rethinking/rethinking22"
file <- file.path(path, "stan", "18", "1b.stan")
mdl <- cmdstanr::cmdstan_model(file, pedantic = TRUE)
fit <- mdl$sample(data=stan_ls, parallel_chains = 4)
fit$cmdstan_diagnose()

# Posterior
draws1b <- fit$draws(format = "data.frame")

colnames(draws1b)

#
# Why is the other model running so much faster????
#


# Continue with two missing variables (1c.stan)

## R code 14.49
data(Primates301)
d <- Primates301
d$name <- as.character(d$name)
dstan <- d[ complete.cases( d$group_size , d$body , d$brain ) , ]
spp_cc <- dstan$name

# complete case analysis
dstan <- d[complete.cases(d$group_size,d$body,d$brain),]
dat_cc <- list(
    N_spp = nrow(dstan),
    M = standardize(log(dstan$body)),
    B = standardize(log(dstan$brain)),
    G = standardize(log(dstan$group_size)),
    Imat = diag(nrow(dstan)) )

# drop just missing brain cases
dd <- d[complete.cases(d$brain),]
dat_all <- list(
    N_spp = nrow(dd),
    M = standardize(log(dd$body)),
    B = standardize(log(dd$brain)),
    G = standardize(log(dd$group_size)),
    Imat = diag(nrow(dd)) )

dd <- d[complete.cases(d$brain),]
table( M=!is.na(dd$body) , G=!is.na(dd$group_size) )

# now with phylogeny

library(ape)
spp <- as.character(dd$name)
tree_trimmed <- keep.tip( Primates301_nex, spp )
Rbm <- corBrownian( phy=tree_trimmed )
V <- vcv(Rbm)
Dmat <- cophenetic( tree_trimmed )

# distance matrix
dat_all$Dmat <- Dmat[ spp , spp ] / max(Dmat)

# imputation ignoring models of M and G
fMBG_OU <- alist(
    B ~ multi_normal( mu , K ),
    mu <- a + bM*M + bG*G,
    M ~ normal(0,1),
    G ~ normal(0,1),
    matrix[N_spp,N_spp]:K <- cov_GPL1(Dmat,etasq,rho,0.01),
    a ~ normal( 0 , 1 ),
    c(bM,bG) ~ normal( 0 , 0.5 ),
    etasq ~ half_normal(1,0.25),
    rho ~ half_normal(3,0.25)
)
mBMG_OU <- ulam( fMBG_OU , data=dat_all , chains=4 , cores=4 , sample=TRUE )

stancode( mBMG_OU )