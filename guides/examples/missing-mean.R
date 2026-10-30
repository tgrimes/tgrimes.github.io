# Self-contained bounded-outcome teaching example; independent rows are people.
SimulateMissingMean <- function(n = 800, seed = 51) {
  set.seed(seed)
  z <- runif(n, -1, 1)
  prob <- plogis(-0.3 + z)
  full_y <- 2 + z + z^2 + runif(n, -1, 1)
  r <- rbinom(n, 1, prob)
  list(data = data.frame(id = seq_len(n), z = z, r = r,
                         y = ifelse(r == 1, full_y, NA_real_)), truth = 7 / 3)
}

CrossFitMissingMean <- function(d, K = 5, seed = 52,
                                probability_bounds = c(0.1, 0.9),
                                outcome_bounds = c(0, 6)) {
  n <- nrow(d)
  stopifnot(n >= 20, K >= 2, K <= n, !anyDuplicated(d$id),
            all(is.finite(d$z)), all(d$r %in% c(0, 1)),
            all(is.finite(d$y[d$r == 1])),
            all(is.na(d$y[d$r == 0])),
            length(probability_bounds) == 2,
            0 < probability_bounds[1], probability_bounds[1] < probability_bounds[2],
            probability_bounds[2] < 1, length(outcome_bounds) == 2,
            outcome_bounds[1] < outcome_bounds[2],
            all(d$y[d$r == 1] >= outcome_bounds[1]),
            all(d$y[d$r == 1] <= outcome_bounds[2]))
  set.seed(seed)
  fold <- sample(rep(seq_len(K), length.out = n))
  mhat <- phat <- raw_p <- raw_m <- numeric(n)
  for (k in seq_len(K)) {
    train <- d[fold != k, ]; test <- d[fold == k, ]
    observed <- train[train$r == 1, ]
    if (nrow(observed) < 6 || length(unique(train$r)) < 2) {
      stop("Training fold has inadequate observed outcomes or observation classes")
    }
    outcome_fit <- lm(y ~ z + I(z^2), data = observed)
    probability_fit <- glm(r ~ z, family = binomial(), data = train)
    if (!isTRUE(probability_fit$converged)) stop("Observation fit did not converge")
    raw_m[fold == k] <- predict(outcome_fit, newdata = test)
    raw_p[fold == k] <- predict(probability_fit, newdata = test, type = "response")
  }
  stopifnot(all(is.finite(raw_m)), all(is.finite(raw_p)))
  mhat <- pmin(outcome_bounds[2], pmax(outcome_bounds[1], raw_m))
  phat <- pmin(probability_bounds[2], pmax(probability_bounds[1], raw_p))
  score <- mhat
  observed <- d$r == 1
  # Do not multiply zero by NA: construct residual corrections on observed rows.
  score[observed] <- mhat[observed] + (d$y[observed] - mhat[observed]) / phat[observed]
  estimate <- mean(score); phi <- score - estimate
  se <- sd(phi) / sqrt(n)
  list(summary = data.frame(estimate = estimate, se = se,
                            lower = estimate - 1.96 * se, upper = estimate + 1.96 * se,
                            observed = sum(observed), n = n,
                            probability_clipped = mean(phat != raw_p),
                            mean_clipped = mean(mhat != raw_m)),
       contributions = data.frame(id = d$id, fold = fold, r = d$r, z = d$z,
                                  mhat = mhat, phat = phat, score = score, phi = phi))
}
