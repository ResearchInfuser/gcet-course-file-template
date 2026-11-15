#!/usr/bin/env Rscript
# Renders the course file using the "subject-type" + "faculty-role" values
# from the workbook's Config sheet (resolved to a Quarto profile via
# resolve_coursefile_profile() in _data_helpers.R), so the whole render --
# metadata AND which profile/chapters to use -- is driven entirely by the
# Excel workbook.
#
# Usage:
#   Rscript tools/render_course_file.R [format]
# [format] defaults to "gcet-course-file-pdf" (try "docx" for a Word copy).

suppressWarnings(suppressMessages({
	library(yaml)
}))

args <- commandArgs(trailingOnly = TRUE)
format <- if (length(args) >= 1) args[[1]] else "gcet-course-file-pdf"

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else "tools/render_course_file.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."))
setwd(project_root)

source(file.path(project_root, "Course File Resources", "_data_helpers.R"))

values <- read_course_config()
if (is.null(values)) {
	stop("No workbook / Config sheet found. Add a '0.CourseFile_Config' sheet (see README.md) or render manually with `quarto render --profile <name>`.", call. = FALSE)
}

profile <- resolve_coursefile_profile(values)

cat(sprintf("Rendering profile '%s' (format: %s), per the workbook's Config sheet...\n", profile, format))
status <- system2("quarto", c("render", "--to", format, "--profile", profile))

# Quarto computes a book-project's default output filename from book.title
# before pre-render scripts run (so the book.title this script's pre-render
# hook writes to _metadata.yml doesn't reach it in time) -- it falls back
# to the project directory name instead. Rename the produced file here so
# it still ends up named after the current course, regardless of that
# Quarto-version quirk.
if (status == 0) {
	output_dir <- file.path(project_root, "Course File")
	ext <- switch(format, "gcet-course-file-pdf" = "pdf", "pdf" = "pdf", "docx" = "docx", tolower(format))
	produced <- list.files(output_dir, pattern = paste0("\\.", ext, "$"), full.names = TRUE)
	metadata_path <- file.path(project_root, "_metadata.yml")

	if (file.exists(metadata_path)) {
		desired_title <- tryCatch(yaml::read_yaml(metadata_path)$book$title, error = function(e) NULL)
		if (!is.null(desired_title) && nzchar(desired_title)) {
			desired_name <- paste0(gsub("[^A-Za-z0-9]+", "-", trimws(desired_title)), ".", ext)
			desired_name <- sub("^-+|-+(?=\\.)", "", desired_name, perl = TRUE)
			desired_path <- file.path(output_dir, desired_name)

			# Quarto renders to <project_directory_name>.<ext> by default
			default_produced <- file.path(output_dir, paste0(basename(project_root), ".", ext))
			source_file <- if (file.exists(default_produced)) {
				default_produced
			} else {
				candidates <- list.files(output_dir, pattern = paste0("\\.", ext, "$"), full.names = TRUE)
				candidates <- candidates[!identical(normalizePath(candidates, mustWork = FALSE), normalizePath(desired_path, mustWork = FALSE))]
				if (length(candidates) >= 1) {
					# Pick the most recently modified candidate
					info <- file.info(candidates)
					rownames(info)[order(info$mtime, decreasing = TRUE)][1]
				} else {
					NULL
				}
			}

			if (!is.null(source_file) && file.exists(source_file) && !identical(normalizePath(source_file, mustWork = FALSE), normalizePath(desired_path, mustWork = FALSE))) {
				if (file.exists(desired_path)) file.remove(desired_path)
				file.rename(source_file, desired_path)
				cat(sprintf("Renamed output to '%s' (from book.title in _metadata.yml).\n", desired_name))
			}
		}
	}
}

quit(status = status, save = "no")
