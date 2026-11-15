#!/usr/bin/env Rscript
# Preflight check for the course-file template.
#
# Validates that the workbook configured under coursefile.schema in
# _quarto.yml actually has every sheet and Register column the chapters
# expect — BEFORE you run a full Quarto render. Run it any time you swap in
# a new course's workbook, or after editing the `schema` block:
#
#   Rscript tools/check_workbook.R
#
# Exits with status 0 if everything matches, or 1 (with a line-by-line
# report of exactly what's missing) otherwise.

suppressWarnings(suppressMessages({
	library(readxl)
}))

file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else "tools/check_workbook.R"
project_root <- normalizePath(file.path(dirname(script_path), ".."))
setwd(project_root)

source(file.path(project_root, "Course File Resources", "_data_helpers.R"))

cat("== Course File Template: workbook preflight check ==\n")
cat("Project:", project_root, "\n\n")

all_ok <- TRUE
check <- function(condition, pass_msg, fail_msg) {
	if (isTRUE(condition)) {
		cat("  [OK]   ", pass_msg, "\n", sep = "")
	} else {
		cat("  [FAIL] ", fail_msg, "\n", sep = "")
		all_ok <<- FALSE
	}
}

schema <- get_schema()
workbook_path <- get_workbook_path()

check(
	!is.na(workbook_path),
	paste0("Workbook found: ", workbook_path),
	paste0("No workbook (.xlsx/.xlsm) found in the '", get_workbook_folder(), "' folder (coursefile.schema.workbook_folder in _quarto.yml).")
)

if (!is.na(workbook_path)) {
	available_sheets <- excel_sheets(workbook_path)

	sheets <- schema$sheets
	if (is.null(sheets) || length(sheets) == 0) {
		cat("  [WARN] No coursefile.schema.sheets configured in _quarto.yml.\n")
	} else {
		cat("\nSheets (coursefile.schema.sheets):\n")
		for (key in names(sheets)) {
			sheet_name <- sheets[[key]]
			check(
				sheet_name %in% available_sheets,
				paste0("'", sheet_name, "' (key: ", key, ")"),
				paste0("'", sheet_name, "' NOT found in workbook (key: ", key, ")")
			)
		}
	}

	register_sheet <- if (!is.null(sheets)) sheets[["register"]] else NULL
	if (!is.null(register_sheet) && register_sheet %in% available_sheets) {
		register_headers <- vapply(
			names(read_excel(workbook_path, sheet = register_sheet, n_max = 0)),
			normalise_header_text, character(1), USE.NAMES = FALSE
		)
		register_columns <- schema$register_columns

		if (is.null(register_columns) || length(register_columns) == 0) {
			cat("\n  [WARN] No coursefile.schema.register_columns configured in _quarto.yml.\n")
		} else {
			cat("\nRequired Register columns (required_register_columns in _data_helpers.R):\n")
			for (key in names(register_columns)) {
				header_text <- register_columns[[key]]
				check(
					normalise_header_text(header_text) %in% register_headers,
					paste0("'", header_text, "' (key: ", key, ")"),
					paste0("'", header_text, "' NOT found in the Register sheet (key: ", key, ")")
				)
			}
		}
	}

	config_sheet <- if (!is.null(sheets)) sheets[["course_config"]] else NULL
	if (!is.null(config_sheet) && config_sheet %in% available_sheets) {
		cat(sprintf("\nConfig sheet ('%s'):\n", config_sheet))
		config_values <- read_course_config()
		profile_or_error <- tryCatch(
			list(ok = TRUE, profile = resolve_coursefile_profile(config_values)),
			error = function(e) list(ok = FALSE, profile = conditionMessage(e))
		)
		check(
			profile_or_error$ok,
			paste0(
				"Subject '", config_values[["subject-type"]], "' + Faculty Role '", config_values[["faculty-role"]],
				"' -> profile '", profile_or_error$profile, "'"
			),
			paste0("Subject/Faculty Role -> profile resolution failed: ", profile_or_error$profile)
		)
	}
}

cat("\n")
if (all_ok) {
	cat("All checks passed — the workbook matches coursefile.schema in _quarto.yml.\n")
	quit(status = 0, save = "no")
} else {
	cat("One or more checks FAILED. Fix the workbook, or update coursefile.schema in\n_quarto.yml to match it, before rendering.\n")
	quit(status = 1, save = "no")
}
