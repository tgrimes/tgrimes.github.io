args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: Rscript --vanilla run.R PROJECT_ROOT OUTPUT_RELATIVE_TO_ROOT")
}
root <- normalizePath(args[1], mustWork = TRUE)
out <- file.path(root, args[2])
if (file.exists(out)) stop("Output path already exists; choose a new run directory.")
source(file.path(root, "R", "analysis.R"))
config <- ReadConfig(file.path(root, "config", "config.csv"))
if (!dir.create(out, recursive = TRUE)) stop("Cannot create output directory.")

people <- GeneratePeople(config)
summary <- SummarizePeople(people$outcome, config$confidence)
write.csv(people, file.path(out, "synthetic-people.csv"), row.names = FALSE)
write.csv(summary, file.path(out, "summary.csv"), row.names = FALSE)
saveRDS(summary, file.path(out, "summary.rds"))
saveRDS(config, file.path(out, "config-used.rds"))
writeLines(capture.output(sessionInfo()), file.path(out, "session-info.txt"))
writeLines(RNGkind(), file.path(out, "rng-kind.txt"))

input_paths <- c("config/config.csv", "R/analysis.R", "run.R")
input_manifest <- data.frame(
  path = input_paths, role = c("configuration", "functions", "entry point"),
  checksum = unname(tools::md5sum(file.path(root, input_paths))))
write.csv(input_manifest, file.path(out, "input-manifest.csv"), row.names = FALSE)
output_paths <- c("synthetic-people.csv", "summary.csv", "summary.rds",
                  "config-used.rds", "session-info.txt", "rng-kind.txt",
                  "input-manifest.csv")
output_manifest <- data.frame(
  path = output_paths,
  checksum = unname(tools::md5sum(file.path(out, output_paths))))
write.csv(output_manifest, file.path(out, "output-manifest.csv"), row.names = FALSE)
writeLines("All listed outputs written successfully.", file.path(out, "COMPLETE"))
print(summary, row.names = FALSE)
