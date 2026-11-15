#!/usr/bin/env Rscript
# Installs the R packages the course file template needs. Safe to re-run:
# packages that are already installed are skipped.
#
# Usage:
#   Rscript tools/install_packages.R

required <- c("knitr", "rmarkdown", "readxl", "yaml", "xml2", "kableExtra", "flextable")

missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing) == 0) {
	cat("All required R packages are already installed:", paste(required, collapse = ", "), "\n")
} else {
	cat("Installing:", paste(missing, collapse = ", "), "\n")
	install.packages(missing, repos = "https://cloud.r-project.org")
	still_missing <- missing[!vapply(missing, requireNamespace, logical(1), quietly = TRUE)]
	if (length(still_missing) > 0) {
		stop("Could not install: ", paste(still_missing, collapse = ", "), call. = FALSE)
	}
	cat("Done.\n")
}
