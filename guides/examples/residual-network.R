# Synthetic residual-covariance network case study. Base R, independent people.
GenerateResidualNetwork <- function(n = 600L, seed = 2801L) {
  stopifnot(length(n) == 1L, n == as.integer(n), n >= 80L)
  set.seed(seed)
  a <- rbinom(n, 1, 0.5); z <- runif(n, -1, 1)
  feature <- paste0("F", 1:6)
  mu <- matrix(seq(5, 7, length.out = 6), n, 6, byrow = TRUE) +
    outer(z, c(1, 0.8, -0.7, 0.5, 0.6, -0.4)) +
    outer(z^2 - 1/3, rep(c(0.5, -0.5), 3)) +
    outer(a, seq(0, 0.5, length.out = 6)) +
    outer(a*z, c(1, 0.4, 0.9, -0.5, 0, 0.6))
  Sigma <- function(rho) {
    S <- diag(6)
    for (b in 1:3) {
      j <- 2*b-1; k <- 2*b; S[j,k] <- S[k,j] <- rho[b]
    }
    S
  }
  S0 <- Sigma(c(0.2, 0.2, 0.2)); S1 <- Sigma(c(0.65, -0.35, 0.2))
  noise <- matrix(0, n, 6)
  for (g in 0:1) {
    take <- which(a == g); S <- if (g == 1) S1 else S0
    noise[take, ] <- matrix(rnorm(length(take)*6), length(take), 6) %*% chol(S)
  }
  id <- sprintf("person_%04d", seq_len(n))
  assay <- t(mu + noise); dimnames(assay) <- list(feature, id)
  metadata <- data.frame(id, a, z)
  metadata <- metadata[sample.int(n), , drop = FALSE]
  pair <- combn(seq_len(6), 2)
  truth <- data.frame(edge = paste(feature[pair[1,]], feature[pair[2,]], sep = "--"),
                      psi0 = S0[t(pair)], psi1 = S1[t(pair)],
                      delta = (S1-S0)[t(pair)])
  list(assay = assay, metadata = metadata, truth = truth)
}

EstimateResidualNetwork <- function(assay, metadata, folds = 5L, seed = 2802L,
                                    model = c("quadratic", "intercept"), alpha = 0.05) {
  model <- match.arg(model)
  stopifnot(is.matrix(assay), is.numeric(assay), nrow(assay) >= 2,
            all(is.finite(assay)), !is.null(colnames(assay)), !is.null(rownames(assay)),
            !anyNA(colnames(assay)), !anyDuplicated(colnames(assay)),
            !anyNA(rownames(assay)), !anyDuplicated(rownames(assay)),
            all(c("id", "a", "z") %in% names(metadata)),
            !anyNA(metadata$id), !anyDuplicated(metadata$id),
            setequal(colnames(assay), metadata$id),
            length(folds) == 1L, folds >= 2L, folds == as.integer(folds),
            length(alpha) == 1L, is.finite(alpha), alpha > 0, alpha < 1)
  d <- metadata[match(colnames(assay), metadata$id), c("id", "a", "z"), drop = FALSE]
  stopifnot(identical(d$id, colnames(assay)), all(d$a %in% 0:1), all(is.finite(d$z)),
            min(table(factor(d$a, levels = 0:1))) >= 2*folds)
  y <- t(assay); n <- nrow(y); p <- ncol(y)
  X <- if (model == "quadratic") cbind(1, d$z, d$z^2) else matrix(1, n, 1)
  set.seed(seed); fold <- integer(n)
  for (g in 0:1) {
    take <- which(d$a == g)
    fold[take] <- sample(rep(seq_len(folds), length.out = length(take)))
  }
  residual <- matrix(NA_real_, n, p, dimnames = dimnames(y))
  for (g in 0:1) for (k in seq_len(folds)) {
    train <- d$a == g & fold != k; test <- d$a == g & fold == k
    fit <- qr(X[train, , drop = FALSE])
    stopifnot(fit$rank == ncol(X))
    coefficients <- qr.coef(fit, y[train, , drop = FALSE])
    residual[test, ] <- y[test, , drop = FALSE] - X[test, , drop = FALSE] %*% coefficients
  }
  stopifnot(all(is.finite(residual)))
  pair <- combn(seq_len(p), 2)
  R <- residual[, pair[1,], drop = FALSE] * residual[, pair[2,], drop = FALSE]
  group_stats <- lapply(0:1, function(g) {
    rg <- R[d$a == g, , drop = FALSE]
    list(mean = colMeans(rg), variance_of_mean = apply(rg, 2, var)/nrow(rg))
  })
  delta <- group_stats[[2]]$mean - group_stats[[1]]$mean
  se <- sqrt(group_stats[[1]]$variance_of_mean + group_stats[[2]]$variance_of_mean)
  stopifnot(all(is.finite(se)), all(se > 0))
  pvalue <- 2*pnorm(-abs(delta/se))
  result <- data.frame(edge = paste(rownames(assay)[pair[1,]], rownames(assay)[pair[2,]], sep = "--"),
                       psi0 = group_stats[[1]]$mean, psi1 = group_stats[[2]]$mean,
                       delta, SE = se, lower = delta-qnorm(0.975)*se,
                       upper = delta+qnorm(0.975)*se, pvalue,
                       BY = p.adjust(pvalue, "BY"))
  result$discovery <- result$BY <= alpha
  list(results = result, fold = data.frame(id = d$id, group = d$a, fold),
       residual = residual, group_counts = table(d$a), model = model,
       family_size = nrow(result))
}

EvaluateResidualNetwork <- function(replicates = 200L, sizes = c(300L, 900L), seed = 29000L) {
  stopifnot(replicates >= 2, replicates == as.integer(replicates))
  records <- list(); attempts <- list(); index <- 0L
  for (n in sizes) for (b in seq_len(replicates)) {
    data <- GenerateResidualNetwork(n, seed + 10000L*n + b)
    for (model in c("quadratic", "intercept")) {
      index <- index + 1L
      fit <- tryCatch(EstimateResidualNetwork(data$assay, data$metadata,
                   seed = seed + b, model = model), error = identity)
      ok <- !inherits(fit, "error")
      attempts[[index]] <- data.frame(n, replicate = b, model, success = ok,
        message = if (ok) "" else conditionMessage(fit))
      if (!ok) next
      r <- fit$results; truth <- data$truth$delta[match(r$edge, data$truth$edge)]
      r$truth <- truth; r$error <- r$delta-truth
      r$covered <- r$lower <= truth & truth <= r$upper
      r$n <- n; r$replicate <- b; r$model <- model
      records[[length(records)+1L]] <- r
    }
  }
  attempts <- do.call(rbind, attempts)
  raw <- if (length(records)) do.call(rbind, records) else data.frame()
  if (!nrow(raw)) return(list(attempts = attempts, raw = raw, summary = data.frame()))
  keys <- unique(attempts[c("n", "model")]); summaries <- list()
  for (k in seq_len(nrow(keys))) {
    n <- keys$n[k]; model <- keys$model[k]
    r <- raw[raw$n == n & raw$model == model, ]
    att <- attempts[attempts$n == n & attempts$model == model, ]
    if (!nrow(r)) next
    per_dataset <- lapply(split(r, r$replicate), function(x) {
      false <- sum(x$discovery & x$truth == 0); R <- sum(x$discovery)
      c(FDP = false/max(R, 1), coverage = mean(x$covered),
        power = mean(x$discovery[x$truth != 0]))
    })
    metrics <- do.call(rbind, per_dataset)
    sentinel <- r[r$edge == "F1--F3", ]
    summaries[[k]] <- data.frame(n, model, attempted = nrow(att), success = nrow(metrics),
      failures = sum(!att$success), sentinel_bias = mean(sentinel$error),
      bias_MCSE = sd(sentinel$error)/nrow(metrics)^0.5,
      coverage = mean(metrics[, "coverage"]),
      coverage_MCSE = sd(metrics[, "coverage"])/nrow(metrics)^0.5,
      FDR = mean(metrics[, "FDP"]), FDR_MCSE = sd(metrics[, "FDP"])/nrow(metrics)^0.5,
      power = mean(metrics[, "power"]))
  }
  list(attempts = attempts, raw = raw, summary = do.call(rbind, summaries))
}

RunResidualNetwork <- function(output = "network-results", replicates = 200L) {
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  data <- GenerateResidualNetwork()
  fit <- EstimateResidualNetwork(data$assay, data$metadata)
  write.csv(data$assay, file.path(output, "synthetic-assay.csv"))
  write.csv(data$metadata, file.path(output, "metadata.csv"), row.names = FALSE)
  write.csv(data$truth, file.path(output, "simulation-truth.csv"), row.names = FALSE)
  write.csv(fit$fold, file.path(output, "folds.csv"), row.names = FALSE)
  write.csv(fit$results, file.path(output, "edges.csv"), row.names = FALSE)
  evaluation <- EvaluateResidualNetwork(replicates)
  write.csv(evaluation$attempts, file.path(output, "attempts.csv"), row.names = FALSE)
  write.csv(evaluation$raw, file.path(output, "evaluation-edges.csv"), row.names = FALSE)
  write.csv(evaluation$summary, file.path(output, "evaluation-summary.csv"), row.names = FALSE)
  writeLines(capture.output(sessionInfo()), file.path(output, "session-info.txt"))
  invisible(list(data = data, fit = fit, evaluation = evaluation))
}
# Run from a terminal: Rscript guides/examples/residual-network.R OUTPUT_DIRECTORY [REPLICATES]
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  output <- if (length(args)) args[1] else "network-results"
  B <- if (length(args) >= 2L) as.integer(args[2]) else 200L
  run <- RunResidualNetwork(output, B)
  print(run$fit$results); print(run$evaluation$summary)
}
