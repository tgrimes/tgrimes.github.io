ReadConfig <- function(path) {
  settings <- read.csv(path, colClasses = c("character", "numeric"))
  required <- c("seed", "n_people", "population_mean", "confidence")
  stopifnot(identical(names(settings), c("setting", "value")),
            !anyDuplicated(settings$setting),
            setequal(settings$setting, required), all(is.finite(settings$value)))
  config <- as.list(setNames(settings$value, settings$setting))
  stopifnot(config$seed >= 0, config$seed <= .Machine$integer.max,
            config$seed == floor(config$seed), config$n_people >= 2,
            config$n_people == floor(config$n_people),
            config$confidence > 0, config$confidence < 1)
  config
}

GeneratePeople <- function(config) {
  set.seed(config$seed, kind = "Mersenne-Twister", normal.kind = "Inversion",
           sample.kind = "Rejection")
  data.frame(person = paste0("P", seq_len(config$n_people)),
             outcome = rnorm(config$n_people, mean = config$population_mean))
}

SummarizePeople <- function(y, confidence = 0.95) {
  stopifnot(is.numeric(y), is.null(dim(y)), length(y) >= 2,
            all(is.finite(y)), length(confidence) == 1,
            is.finite(confidence), confidence > 0, confidence < 1)
  estimate <- mean(y)
  se <- sd(y) / sqrt(length(y))
  critical <- qt((1 + confidence) / 2, df = length(y) - 1)
  data.frame(n_people = length(y), estimate, se, confidence,
             lower = estimate - critical * se, upper = estimate + critical * se)
}
