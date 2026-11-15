#!/usr/bin/env Rscript
# Pre-render hook (see project.pre-render in _quarto.yml): regenerates
# _metadata.yml from the course workbook's Config sheet, so every
# coursefile.* display value (institution, subject name, course code,
# faculty name, section name, ...) AND book.title/book.subtitle come from
# the Excel workbook -- no _quarto.yml edits needed when reusing this
# template for a new course.
#
# _metadata.yml is Quarto's auto-discovered directory-level metadata file
# (see https://quarto.org/docs/projects/quarto-projects.html#metadata-includes),
# and project metadata is re-read after pre-render scripts run, so this
# file's content is picked up automatically on every `quarto render` -- no
# extra "metadata-files:" wiring needed (and not reliably supported for
# book-type projects across Quarto versions).

suppressWarnings(suppressMessages({
	library(yaml)
}))

# Pre-render scripts run with the project directory as the working directory.
project_root <- getwd()
source(file.path(project_root, "Course File Resources", "_data_helpers.R"))

output_path <- file.path(project_root, "_metadata.yml")
values <- read_course_config()

if (is.null(values)) {
	cat("[generate_coursefile_metadata] No workbook / Config sheet found; leaving coursefile metadata as defined in _quarto.yml.\n")
	quit(status = 0, save = "no")
}

# Build a profile-appropriate book title/subtitle from the Config sheet, so
# the rendered file name (Quarto derives it from book.title) always matches
# the current course, for every profile. Extend this map when adding a new
# profile in _quarto.yml's profile.group.
profile_title_suffixes <- c(
	"course-coordinator" = "Course File",
	"subject-teacher" = "Subject Teacher Course File",
	"laboratory-course" = "Laboratory Course File"
)
active_profile <- strsplit(Sys.getenv("QUARTO_PROFILE"), ",", fixed = TRUE)[[1]][1]
if (is.null(active_profile) || is.na(active_profile) || !nzchar(active_profile)) {
	active_profile <- tryCatch(resolve_coursefile_profile(values), error = function(e) "course-coordinator")
}
title_suffix <- if (active_profile %in% names(profile_title_suffixes)) profile_title_suffixes[[active_profile]] else "Course File"

course_code <- values[["course-code"]]
if (is.null(course_code) || !nzchar(course_code)) course_code <- "Course"

title_text <- paste(course_code, title_suffix)
faculty_name <- values[["faculty-name"]]
if (!is.null(faculty_name) && nzchar(faculty_name)) {
	title_text <- paste(title_text, faculty_name, sep = " - ")
}

book_values <- list(title = title_text)
if (!is.null(values[["institution"]]) && nzchar(values[["institution"]])) {
	book_values$subtitle <- values[["institution"]]
}
author_name <- if (!is.null(faculty_name) && nzchar(faculty_name)) faculty_name else "Course Coordinator"
book_values$author <- author_name

# subject-type + faculty-role together select which profile to render
# (see resolve_coursefile_profile() in _data_helpers.R and
# tools/render_course_file.R); they are not display values, so they are
# not written into coursefile: metadata itself.
values[["subject-type"]] <- NULL
values[["faculty-role"]] <- NULL

yaml_data <- c(list(author = author_name), list(book = book_values, coursefile = values))
yaml::write_yaml(yaml_data, output_path)

cat(sprintf(
	"[generate_coursefile_metadata] Wrote %s (book.title = '%s', %d coursefile fields) from the workbook's Config sheet.\n",
	output_path, book_values$title, length(values)
))
