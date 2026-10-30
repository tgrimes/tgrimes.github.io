# A small reproducible research project

This is a base-R teaching project. Every person and measurement is synthetic.
It estimates the population mean of independent normal outcomes using a
Student t interval. The configuration supplies the simulation mean to the
generator; the estimator receives only the generated values and confidence
level. It is not an omics analysis or a scientific validation study.

Requirements: R 3.6 or later with the standard packages supplied with R. No
additional packages, network access, private data, or interactive objects are
needed. Each run records its R version and random-number generator setup.

## Run

From the unpacked project directory:

```sh
Rscript --vanilla run.R . results/run-01
Rscript --vanilla run.R . results/run-02
```

The first argument is the project root; the second is the output path relative
to that root. From another working directory, supply absolute paths for the
script and root. Quote paths containing spaces. The runner refuses an existing
output path, so choose a new directory for every attempt.

## Inputs and outputs

- `config/config.csv`: seed, independent-person count, generator mean, confidence level.
- `R/analysis.R`: functions for configuration, generation, and estimation.
- `run.R`: the documented entry point.
- `results/run-01/`: synthetic inputs, numeric summary, configuration used,
  input/code checksums, output checksums, R session information, RNG setup,
  and a final `COMPLETE` marker.

A partial directory without `COMPLETE` is not a completed run. Retain failed-run
logs when investigating a problem. A completed run indicates execution status,
not the truth of statistical assumptions.

## Compare two runs

In R, from the project root:

```r
a <- readRDS("results/run-01/summary.rds")
b <- readRDS("results/run-02/summary.rds")
stopifnot(isTRUE(all.equal(a, b, tolerance = 1e-12)))
```

This comparison expects the same documented R setup and inputs. It checks
numeric agreement, not byte identity of every file across platforms. Check
the input manifests first; logs and software records are part of the evidence.

Change one configuration setting, create a third run, and retain all three.
Explain which difference in inputs predicts the change in results. In a real
study, external data releases, inclusion rules, annotation versions, and
external system dependencies must also be recorded.

The `--vanilla` flag deliberately skips startup profiles for this base-R
example. A project using renv must activate its documented environment;
skipping `.Rprofile` also skips its usual automatic renv activation.
