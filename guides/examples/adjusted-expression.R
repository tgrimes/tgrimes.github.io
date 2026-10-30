# Synthetic expression case study. Base R only; independent rows are people.
ExpressionStudyConfig <- function() {
  list(n = 800L, genes = 24L, folds = 5L, data_seed = 911L,
       fold_seed = 912L, alpha = 0.05, probability_bounds = c(0.1, 0.9),
       mean_bounds = c(0, 16), simulation_replicates = 100L,
       simulation_n = c(400L, 1200L), simulation_seed = 14000L)
}

GenerateExpressionStudy <- function(n = 800L, genes = 24L, seed = 911L) {
  stopifnot(length(n) == 1, n >= 80, n == as.integer(n),
            length(genes) == 1, genes >= 8, genes == as.integer(genes))
  set.seed(seed)
  z <- runif(n, -1, 1); batch <- rbinom(n, 1, 0.5)
  e <- plogis(-0.1 + z + 0.5 * batch)
  a <- rbinom(n, 1, e)
  observation_prob <- plogis(0.6 - 0.6 * a + 0.5 * z - 0.3 * batch)
  r <- rbinom(n, 1, observation_prob)
  gene <- sprintf("gene_%02d", seq_len(genes))
  baseline <- seq(6, 9, length.out = genes)
  slope <- seq(0.5, 1.1, length.out = genes)
  curvature <- rep(c(0.45, -0.35), length.out = genes)
  technical <- rep(c(0.3, 0.5), length.out = genes)
  delta <- c(0.7, -0.65, 0.5, -0.45, 0.35, -0.3, rep(0, genes - 6))
  heterogeneity <- rep(c(0.5, -0.4, 0.3), length.out = genes)
  mu <- matrix(baseline, n, genes, byrow = TRUE) +
    outer(z, slope) + outer(z^2 - 1/3, curvature) +
    outer(batch, technical) + outer(a, delta) + outer(a * z, heterogeneity)
  shared_noise <- runif(n, -0.5, 0.5)
  y <- mu + shared_noise + matrix(runif(n * genes, -0.6, 0.6), n, genes)
  y[r == 0, ] <- NA_real_
  id <- sprintf("person_%04d", seq_len(n))
  assay <- t(y); dimnames(assay) <- list(gene, id)
  metadata <- data.frame(id = id, a = a, z = z, batch = batch, r = r)
  metadata <- metadata[sample.int(n), , drop = FALSE] # intentional shuffled order
  list(assay = assay, metadata = metadata,
       features = data.frame(gene = gene, annotation_version = "synthetic-v1"),
       truth = data.frame(gene = gene, psi = delta, heterogeneity = heterogeneity),
       generator = "bounded-log2-expression-v1")
}

AlignExpressionStudy <- function(assay, metadata) {
  required <- c("id", "a", "z", "batch", "r")
  stopifnot(is.matrix(assay), is.numeric(assay), nrow(assay) >= 1,
            all(required %in% names(metadata)), !is.null(rownames(assay)),
            !is.null(colnames(assay)), !anyNA(rownames(assay)),
            !anyDuplicated(rownames(assay)), !anyNA(colnames(assay)),
            !anyDuplicated(colnames(assay)), !anyNA(metadata$id),
            !anyDuplicated(metadata$id), setequal(colnames(assay), metadata$id))
  d <- metadata[match(colnames(assay), metadata$id), required, drop = FALSE]
  stopifnot(identical(colnames(assay), d$id), all(d$a %in% 0:1),
            all(d$r %in% 0:1), all(d$batch %in% 0:1), all(is.finite(d$z)),
            all(is.finite(assay[, d$r == 1, drop = FALSE])),
            all(is.na(assay[, d$r == 0, drop = FALSE])))
  list(y = t(assay), metadata = d)
}

AugmentedExpressionScore <- function(y, a, r, m1, m0, q1, q0) {
  score <- m1 - m0
  observed_1 <- a == 1 & r == 1
  observed_0 <- a == 0 & r == 1
  score[observed_1, ] <- score[observed_1, , drop = FALSE] +
    sweep(y[observed_1, , drop = FALSE] - m1[observed_1, , drop = FALSE],
          1, q1[observed_1], "/")
  score[observed_0, ] <- score[observed_0, , drop = FALSE] -
    sweep(y[observed_0, , drop = FALSE] - m0[observed_0, , drop = FALSE],
          1, q0[observed_0], "/")
  score
}

EstimateExpressionContrast <- function(assay, metadata, folds = 5L, seed = 912L,
                                       outcome_model = "quadratic", weight_model = "adjusted",
                                       probability_bounds = c(0.1, 0.9),
                                       mean_bounds = c(0, 16), alpha = 0.05) {
  aligned <- AlignExpressionStudy(assay, metadata)
  d <- aligned$metadata; y <- aligned$y; n <- nrow(d); G <- ncol(y)
  stopifnot(length(folds) == 1, folds == as.integer(folds), folds >= 2, folds <= n / 10,
            outcome_model %in% c("quadratic", "intercept"),
            weight_model %in% c("adjusted", "intercept"), alpha > 0, alpha < 1,
            length(probability_bounds) == 2, all(is.finite(probability_bounds)),
            0 < probability_bounds[1], probability_bounds[1] < probability_bounds[2],
            probability_bounds[2] < 1, length(mean_bounds) == 2,
            all(is.finite(mean_bounds)), mean_bounds[1] < mean_bounds[2],
            all(y[d$r == 1, ] >= mean_bounds[1]),
            all(y[d$r == 1, ] <= mean_bounds[2]))
  set.seed(seed); fold <- sample(rep(seq_len(folds), length.out = n))
  m1 <- m0 <- matrix(NA_real_, n, G)
  raw_e <- raw_pi1 <- raw_pi0 <- rep(NA_real_, n)
  warnings <- character()
  FitLogit <- function(formula, train) {
    fit <- withCallingHandlers(glm(formula, family = binomial(), data = train),
      warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") })
    if (!isTRUE(fit$converged) || any(!is.finite(coef(fit)))) stop("Unusable probability fit")
    fit
  }
  X <- if (outcome_model == "quadratic") model.matrix(~ z + I(z^2) + batch, d) else matrix(1, n, 1)
  for (k in seq_len(folds)) {
    tr <- fold != k; te <- !tr
    if (length(unique(d$a[tr])) != 2 || length(unique(d$r[tr])) != 2) stop("Training fold lacks a class")
    e_fit <- FitLogit(if (weight_model == "adjusted") a ~ z + batch else a ~ 1, d[tr, ])
    pi_fit <- FitLogit(if (weight_model == "adjusted") r ~ a + z + batch else r ~ 1, d[tr, ])
    raw_e[te] <- predict(e_fit, d[te, ], type = "response")
    d1 <- d[te, ]; d1$a <- 1; d0 <- d[te, ]; d0$a <- 0
    raw_pi1[te] <- predict(pi_fit, d1, type = "response")
    raw_pi0[te] <- predict(pi_fit, d0, type = "response")
    for (arm in 0:1) {
      obs <- tr & d$a == arm & d$r == 1
      if (sum(obs) < max(10, ncol(X) + 2)) stop("Too few observed people in a training arm")
      fit <- lm.fit(X[obs, , drop = FALSE], y[obs, , drop = FALSE])
      if (fit$rank != ncol(X) || any(!is.finite(fit$coefficients))) stop("Singular outcome fit")
      prediction <- X[te, , drop = FALSE] %*% fit$coefficients
      if (arm == 1) m1[te, ] <- prediction else m0[te, ] <- prediction
    }
  }
  stopifnot(all(is.finite(c(raw_e, raw_pi1, raw_pi0, m1, m0))))
  ClipProbability <- function(x) pmin(probability_bounds[2], pmax(probability_bounds[1], x))
  e <- ClipProbability(raw_e); pi1 <- ClipProbability(raw_pi1); pi0 <- ClipProbability(raw_pi0)
  mean_clipped <- mean(c(m1 < mean_bounds[1] | m1 > mean_bounds[2],
                         m0 < mean_bounds[1] | m0 > mean_bounds[2]))
  m1[] <- pmin(mean_bounds[2], pmax(mean_bounds[1], m1))
  m0[] <- pmin(mean_bounds[2], pmax(mean_bounds[1], m0))
  q1 <- e * pi1; q0 <- (1 - e) * pi0
  score <- AugmentedExpressionScore(y, d$a, d$r, m1, m0, q1, q0)
  estimate <- colMeans(score); phi <- sweep(score, 2, estimate)
  se <- apply(phi, 2, sd) / sqrt(n)
  if (any(!is.finite(se) | se <= 0)) stop("Invalid standard error")
  p <- 2 * pnorm(-abs(estimate / se)); critical <- qnorm(1 - alpha / 2)
  crude <- colMeans(y[d$a == 1 & d$r == 1, , drop = FALSE]) -
    colMeans(y[d$a == 0 & d$r == 1, , drop = FALSE])
  results <- data.frame(gene = colnames(y), estimate = estimate, se = se,
    lower = estimate - critical * se, upper = estimate + critical * se,
    p = p, p_BY = p.adjust(p, "BY"), reject_BY = p.adjust(p, "BY") <= alpha,
    complete_case_crude = crude, row.names = NULL)
  weights <- ifelse(d$r == 1, ifelse(d$a == 1, 1 / q1, 1 / q0), 0)
  diagnostics <- data.frame(n = n, observed = sum(d$r), group0 = sum(d$a == 0),
    group1 = sum(d$a == 1), observed0 = sum(d$a == 0 & d$r == 1),
    observed1 = sum(d$a == 1 & d$r == 1),
    e_min = min(e), e_max = max(e), pi_min = min(pi0, pi1), pi_max = max(pi0, pi1),
    q_min = min(q0, q1), max_observed_weight = max(weights),
    probability_clipped = mean(c(e != raw_e, pi1 != raw_pi1, pi0 != raw_pi0)),
    mean_clipped = mean_clipped, warning_count = length(warnings))
  list(results = results, diagnostics = diagnostics, warnings = unique(warnings),
       contributions = data.frame(id = d$id, fold = fold, phi, check.names = FALSE),
       predictions = data.frame(id = d$id, a = d$a, r = d$r, z = d$z, batch = d$batch,
                                e = e, pi1 = pi1, pi0 = pi0, q1 = q1, q0 = q0),
       score = score)
}

EvaluateExpressionStudy <- function(B = 100L, ns = c(400L, 1200L), genes = 24L,
                                    folds = 5L, seed = 14000L, alpha = 0.05,
                                    probability_bounds = c(0.1, 0.9), mean_bounds = c(0, 16)) {
  stopifnot(B >= 2, B == as.integer(B))
  scenarios <- data.frame(scenario = c("Both correct", "Outcome only correct", "Weights only correct", "Both wrong"),
    outcome = c("quadratic", "quadratic", "intercept", "intercept"),
    weights = c("adjusted", "intercept", "adjusted", "intercept"))
  out <- list(); j <- 0
  for (size in seq_along(ns)) for (b in seq_len(B)) {
    data_seed <- seed + 10000L * size + b; fold_seed <- seed + 100000L + 10000L * size + b
    study <- GenerateExpressionStudy(ns[size], genes, data_seed)
    for (s in seq_len(nrow(scenarios))) {
      j <- j + 1
      row <- data.frame(n = ns[size], replicate = b, scenario = scenarios$scenario[s],
        data_seed = data_seed, fold_seed = fold_seed, success = FALSE, error = "",
        sentinel_bias = NA_real_, mean_squared_error = NA_real_, coverage = NA_real_,
        fdp = NA_real_, true_positive_fraction = NA_real_, discoveries = NA_real_,
        sentinel_gene = sprintf("gene_%02d", min(12L, genes)),
        probability_clipped = NA_real_, warning_count = NA_integer_)
      fit <- tryCatch(EstimateExpressionContrast(study$assay, study$metadata, folds, fold_seed,
        outcome_model = scenarios$outcome[s], weight_model = scenarios$weights[s], alpha = alpha,
        probability_bounds = probability_bounds, mean_bounds = mean_bounds),
        error = function(e) e)
      if (inherits(fit, "error")) row$error <- conditionMessage(fit) else {
        truth <- study$truth$psi[match(fit$results$gene, study$truth$gene)]
        error <- fit$results$estimate - truth; reject <- fit$results$reject_BY
        row$success <- TRUE; row$sentinel_bias <- error[min(12L, genes)]
        row$mean_squared_error <- mean(error^2)
        row$coverage <- mean(fit$results$lower <= truth & fit$results$upper >= truth)
        row$fdp <- sum(reject & truth == 0) / max(sum(reject), 1)
        row$true_positive_fraction <- sum(reject & truth != 0) / sum(truth != 0)
        row$discoveries <- sum(reject)
        row$probability_clipped <- fit$diagnostics$probability_clipped
        row$warning_count <- fit$diagnostics$warning_count
      }
      out[[j]] <- row
    }
  }
  do.call(rbind, out)
}

SummarizeExpressionEvaluation <- function(records) {
  keys <- unique(records[c("n", "scenario")])
  do.call(rbind, lapply(seq_len(nrow(keys)), function(j) {
    attempted <- records[records$n == keys$n[j] & records$scenario == keys$scenario[j], ]
    d <- attempted[attempted$success, ]; ok <- nrow(d)
    Average <- function(x) if (ok) mean(x) else NA_real_
    MCSE <- function(x) if (ok > 1) sd(x) / sqrt(ok) else NA_real_
    data.frame(n = keys$n[j], scenario = keys$scenario[j], attempted = nrow(attempted), successful = ok,
      sentinel_bias = Average(d$sentinel_bias), bias_mcse = MCSE(d$sentinel_bias),
      root_mean_squared_error = sqrt(Average(d$mean_squared_error)),
      coverage = Average(d$coverage), coverage_mcse = MCSE(d$coverage),
      fdr = Average(d$fdp), fdr_mcse = MCSE(d$fdp),
      true_positive_fraction = Average(d$true_positive_fraction))
  }))
}

WriteExpressionStudy <- function(output_dir, config = ExpressionStudyConfig()) {
  if (dir.exists(output_dir) && length(list.files(output_dir, all.files = TRUE, no.. = TRUE))) {
    stop("Choose a new or empty output directory so previous runs are retained")
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  study <- GenerateExpressionStudy(config$n, config$genes, config$data_seed)
  fit <- EstimateExpressionContrast(study$assay, study$metadata, config$folds, config$fold_seed,
    probability_bounds = config$probability_bounds, mean_bounds = config$mean_bounds, alpha = config$alpha)
  records <- EvaluateExpressionStudy(config$simulation_replicates, config$simulation_n,
    config$genes, config$folds, config$simulation_seed, config$alpha,
    config$probability_bounds, config$mean_bounds)
  objects <- list(metadata = study$metadata, features = study$features, simulation_truth = study$truth,
    results = fit$results, diagnostics = fit$diagnostics, predictions = fit$predictions,
    influence_contributions = fit$contributions, simulation_records = records,
    simulation_summary = SummarizeExpressionEvaluation(records))
  for (name in names(objects)) write.csv(objects[[name]], file.path(output_dir, paste0(name, ".csv")), row.names = FALSE)
  write.csv(data.frame(gene = rownames(study$assay), study$assay, check.names = FALSE),
    file.path(output_dir, "observed_assay.csv"), row.names = FALSE)
  saveRDS(config, file.path(output_dir, "config.rds"))
  writeLines(capture.output(dput(config)), file.path(output_dir, "config.txt"))
  writeLines(capture.output(sessionInfo()), file.path(output_dir, "session-info.txt"))
  writeLines(fit$warnings, file.path(output_dir, "fit-warnings.txt"))
  files <- list.files(output_dir, full.names = TRUE)
  manifest <- data.frame(file = basename(files), md5 = unname(tools::md5sum(files)),
    source = "Synthetic bounded-log2-expression-v1; no real participants")
  write.csv(manifest, file.path(output_dir, "manifest.csv"), row.names = FALSE)
  invisible(list(study = study, fit = fit, records = records))
}
