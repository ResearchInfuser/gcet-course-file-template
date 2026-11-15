# Shared helpers used by the Course File Resources/*.qmd chapters to pull
# data directly from the master workbook, and to render the tables that
# repeat across chapters (CO tables, CO-PO/PSO mapping, Register subsets).
#
# BEST-PRACTICE CONTRACT: no file in this project should hardcode a workbook
# filename, worksheet name, cell range, or Register column position/header.
# All of that lives in the `coursefile.schema` block of _quarto.yml. This
# file reads that block (via get_schema()) and every chapter asks for data
# by *logical key* (cf_sheet("course_info"), register_columns = "cae1_marks",
# ...). To reuse this whole codebase for a different course, copy the
# project, drop in that course's workbook, and update `coursefile.schema` in
# _quarto.yml to match its sheet/column layout — no chapter or R code needs
# to change. Run `Rscript tools/check_workbook.R` to validate the schema
# against the workbook before rendering.

library(readxl)

#' Locate `_quarto.yml` regardless of whether the caller is a knitr chunk
#' (which may render from the project root or from its own chapter folder)
#' or a plain Rscript (e.g. tools/check_workbook.R, which has no knitr
#' context at all).
locate_project_file <- function(filename) {
	current_input_dir <- tryCatch(
		dirname(knitr::current_input(dir = TRUE)),
		error = function(e) NA_character_
	)
	candidate_paths <- c(filename, file.path("..", filename), file.path(getwd(), filename), file.path(getwd(), "..", filename))
	if (!is.na(current_input_dir) && length(current_input_dir) > 0 && nzchar(current_input_dir)) {
		candidate_paths <- c(candidate_paths, file.path(current_input_dir, "..", filename))
	}
	candidate_paths <- unique(candidate_paths)
	found <- candidate_paths[file.exists(candidate_paths)]
	if (length(found) == 0) NA_character_ else found[1]
}

#' Read and cache the `coursefile` block of _quarto.yml, merged with the
#' `coursefile` block of _metadata.yml if present (the file
#' tools/generate_coursefile_metadata.R regenerates from the workbook's
#' Config sheet on every render via project.pre-render in _quarto.yml;
#' _metadata.yml is Quarto's auto-discovered directory-level metadata
#' file, so no extra wiring is needed for it to take effect). _metadata.yml
#' overrides _quarto.yml for any key both define, mirroring Quarto's own
#' directory-metadata precedence.
get_coursefile_config <- local({
	cached <- NULL
	function() {
		if (!is.null(cached)) return(cached)

		yml_path <- locate_project_file("_quarto.yml")
		base_coursefile <- list()
		if (is.na(yml_path)) {
			warning("_quarto.yml not found; coursefile schema will be empty.")
		} else {
			config <- yaml::read_yaml(yml_path)
			if (!is.null(config$coursefile)) base_coursefile <- config$coursefile
		}

		generated_path <- locate_project_file("_metadata.yml")
		generated_coursefile <- list()
		if (!is.na(generated_path)) {
			generated_config <- yaml::read_yaml(generated_path)
			if (!is.null(generated_config$coursefile)) generated_coursefile <- generated_config$coursefile
		}

		cached <<- utils::modifyList(base_coursefile, generated_coursefile)
		cached
	}
})

#' The coursefile.schema block (workbook/sheets/ranges/register_columns),
#' or an empty-but-well-formed list if it is not configured.
get_schema <- function() {
	schema <- get_coursefile_config()$schema
	if (is.null(schema)) schema <- list(workbook = NULL, sheets = list(), ranges = list())
	overrides <- schema$register_columns
	schema$register_columns <- utils::modifyList(required_register_columns, if (is.null(overrides)) list() else overrides)
	schema
}

#' The Register-sheet columns this template requires, as logical key ->
#' mandated header text. Every course workbook's Register sheet must have
#' these headers (in any order/position); tools/check_workbook.R verifies
#' them. They are deliberately NOT listed in _quarto.yml: the Register
#' layout is part of the template, not a per-course setting. Add a key here
#' when a chapter starts reading a new Register column. Only a workbook
#' whose headers genuinely differ needs a
#' coursefile.schema.register_columns.<key> override in _quarto.yml.
required_register_columns <- list(
	serial_no = "S. No.",
	section = "Branch / Section",
	admission_no = "Admission No",
	student_name = "Student Name",
	cae1_attendance = "CAE-I Attendance",
	cae1_marks = "CAE-I Marks",
	cae2_attendance = "CAE-II Attendance",
	cae2_marks = "CAE-II Marks",
	assignment_1 = "Assign/Tutorial Grade 1",
	assignment_2 = "Assign/Tutorial Grade 2",
	assignment_3 = "Assign/Tutorial Grade 3",
	assignment_4 = "Assign/Tutorial Grade 4",
	assignment_5 = "Assign/Tutorial Grade 5",
	assignment_total = "Assignment Total",
	put_attendance = "PUT Attendance",
	put_marks = "PUT Marks"
)

#' Read an arbitrary field from the top-level `coursefile` block of
#' _quarto.yml (e.g. "course-code", "section-name"), with a default when the
#' field is absent so chapters degrade gracefully instead of erroring.
cf_value <- function(key, default = "") {
	value <- get_coursefile_config()[[key]]
	if (is.null(value)) default else value
}

#' Resolve a logical sheet key (e.g. "course_info") configured under
#' coursefile.schema.sheets in _quarto.yml to its real worksheet name. Falls
#' back to treating `key` itself as a literal sheet name (with a warning) so
#' a typo'd/unconfigured key still fails in an obvious way rather than
#' silently.
cf_sheet <- function(key) {
	sheet_name <- get_schema()$sheets[[key]]
	if (is.null(sheet_name)) {
		warning(sprintf("No coursefile.schema.sheets.%s entry in _quarto.yml; using '%s' literally.", key, key))
		return(key)
	}
	sheet_name
}

#' Resolve a logical range key (e.g. "co_table") configured under
#' coursefile.schema.ranges in _quarto.yml to its cell range string.
cf_range <- function(key) {
	range_value <- get_schema()$ranges[[key]]
	if (is.null(range_value)) {
		stop(sprintf("No coursefile.schema.ranges.%s entry in _quarto.yml.", key), call. = FALSE)
	}
	range_value
}

#' Locate the course workbook regardless of whether Quarto renders from the
#' project root or from the chapter's own folder. Resolution order:
#' explicit `filename` argument > coursefile.schema.workbook in _quarto.yml
#' > auto-detected (the single .xlsx/.xlsm file inside the workbook folder,
#' see get_workbook_folder(), ignoring Excel's "~$..." lock files) — so a
#' new course only requires swapping the workbook in that folder, with no
#' filename to configure anywhere.
get_workbook_path <- function(filename = NULL) {

    if (is.null(filename)) {
        # [[ ]] not $: `$workbook` would partial-match `workbook_folder`.
        filename <- get_schema()[["workbook"]]
    }

    if (is.null(filename)) {
        filename <- autodetect_workbook_filename()
    }

    if (is.null(filename)) {
        stop(
            "No single Excel workbook found. ",
            "Expected exactly one .xlsx or .xlsm file in the '",
            get_workbook_folder(), "' folder."
        )
    }

    locate_project_file(filename)
}

#' The project root directory (the directory containing _quarto.yml).
get_project_root <- function() {
	yml_path <- locate_project_file("_quarto.yml")
	if (is.na(yml_path)) "." else dirname(yml_path)
}

#' The project folder that holds the course workbook
#' (coursefile.schema.workbook_folder in _quarto.yml, relative to the
#' project root). Whatever single workbook sits in it is used automatically.
get_workbook_folder <- function() {
    folder <- get_schema()$workbook_folder
    if (is.null(folder) || !nzchar(trimws(folder))) "Course Workbook" else trimws(folder)
}

#' Find the single workbook inside the workbook folder (see
#' get_workbook_folder()), ignoring Excel's "~$..." lock files. Returns its
#' path relative to the project root, or NULL (not an error) if there isn't
#' exactly one match.
autodetect_workbook_filename <- function() {

    folder <- get_workbook_folder()

    # Support both Excel workbook formats
    candidates <- list.files(
        file.path(get_project_root(), folder),
        pattern = "\\.(xlsx|xlsm)$",
        ignore.case = TRUE
    )

    # Exclude temporary Excel lock files
    candidates <- candidates[
        !grepl("^~\\$", candidates)
    ]

    if (length(candidates) == 1L) {
        return(file.path(folder, candidates[1]))
    }

    if (length(candidates) > 1L) {
        warning(
            "Multiple Excel workbooks found in '", folder, "' (",
            paste(candidates, collapse = ", "),
            "). Keep only the course workbook there."
        )
    }

    NULL
}

#' Read the course workbook's Config sheet (coursefile.schema.sheets.
#' course_config in _quarto.yml) into a named list of Key/Value pairs.
#' Used both by tools/generate_coursefile_metadata.R (to build
#' _metadata.yml) and tools/render_course_file.R (to resolve the render
#' profile via resolve_coursefile_profile()). Returns NULL if the workbook
#' or the Config sheet isn't present.
read_course_config <- function() {
	workbook_path <- get_workbook_path()
	if (is.na(workbook_path)) return(NULL)

	config_sheet <- cf_sheet("course_config")
	if (!(config_sheet %in% readxl::excel_sheets(workbook_path))) return(NULL)

	config_df <- as.data.frame(read_excel(workbook_path, sheet = config_sheet, col_names = c("key", "value"), skip = 1))
	config_df <- config_df[!is.na(config_df$key) & nzchar(trimws(as.character(config_df$key))), ]

	values <- as.list(trimws(ifelse(is.na(config_df$value), "", as.character(config_df$value))))
	names(values) <- trimws(as.character(config_df$key))
	values
}

#' The valid (subject-type, faculty-role) -> Quarto profile combinations
#' for the Config sheet's "subject-type" (Theory/Lab) and "faculty-role"
#' (Course Coordinator/Subject Faculty/Laboratory Faculty) fields. Extend
#' this when adding a new profile (see README.md "Adding a new profile").
coursefile_profile_map <- list(
	"Theory|Course Coordinator" = "course-coordinator",
	"Theory|Subject Faculty" = "subject-teacher",
	"Lab|Laboratory Faculty" = "laboratory-course"
)

#' Resolve the Config sheet's "subject-type" + "faculty-role" values (read
#' via read_course_config()) to the Quarto profile to render, so the Config
#' sheet can stay in faculty-friendly terms instead of raw profile names.
#' Stops with a clear error listing the supported combinations if the pair
#' is missing/unrecognised, or if it maps to a profile no longer listed
#' under profile.group in _quarto.yml.
resolve_coursefile_profile <- function(values) {
	safe_trim <- function(x) if (is.null(x) || length(x) == 0) "" else trimws(x)
	subject_type <- safe_trim(values[["subject-type"]])
	faculty_role <- safe_trim(values[["faculty-role"]])

	profile <- coursefile_profile_map[[paste(subject_type, faculty_role, sep = "|")]]

	supported <- paste(
		vapply(names(coursefile_profile_map), function(k) sub("\\|", " + ", k), character(1)),
		collapse = "; "
	)

	if (is.null(profile)) {
		stop(sprintf(
			"Unsupported Config sheet Subject ('%s') / Faculty Role ('%s') combination. Supported combinations: %s.",
			ifelse(nzchar(subject_type), subject_type, "(not set)"),
			ifelse(nzchar(faculty_role), faculty_role, "(not set)"),
			supported
		), call. = FALSE)
	}

	yml_path <- locate_project_file("_quarto.yml")
	if (!is.na(yml_path)) {
		known_profiles <- unlist(yaml::read_yaml(yml_path)$profile$group)
		if (!(profile %in% known_profiles)) {
			stop(sprintf(
				"Subject '%s' + Faculty Role '%s' maps to profile '%s', which is no longer listed under profile.group in _quarto.yml.",
				subject_type, faculty_role, profile
			), call. = FALSE)
		}
	}

	profile
}

#' Read a sheet (optionally a range) from the workbook. Returns NULL
#' (instead of raising an error) when the workbook cannot be located, so
#' chapters can fall back to a friendly message via notify_workbook_missing().
read_workbook_sheet <- function(sheet, range = NULL, col_names = TRUE, workbook = NULL) {
	xlsx_path <- get_workbook_path(workbook)
	if (is.na(xlsx_path)) {
		return(NULL)
	}
	args <- list(path = xlsx_path, sheet = sheet, col_names = col_names)
	if (!is.null(range)) {
		args$range <- range
	}
	do.call(read_excel, args)
}

#' Standard "workbook not found" notice, printed as part of a results:'asis' chunk.
notify_workbook_missing <- function() {
	cat(paste0("_No course workbook found in this project's `", get_workbook_folder(), "` folder._\n"))
}

#' Normalise a header string so Excel's wrapped-text line breaks and
#' repeated/leading/trailing whitespace don't cause a configured header
#' (e.g. "Branch / Section") to fail to match the actual cell text (which
#' Excel may store as "Branch / \nSection" if the header is word-wrapped).
normalise_header_text <- function(x) {
	trimws(gsub("[[:space:]]+", " ", x))
}

#' Pull named columns from the Register sheet by their configured header
#' text (required_register_columns above) instead of by
#' fixed column position, so chapters stay correct even if columns are
#' inserted/removed/reordered in the Register sheet (as long as the header
#' text is unchanged). `keys` is a character vector of logical column keys
#' (e.g. c("serial_no", "student_name", "cae1_marks")); the result is a
#' data.frame with one column per key, named after `keys`.
get_register_columns <- function(register_df, keys) {
	register_columns <- get_schema()$register_columns
	headers <- vapply(names(register_df), normalise_header_text, character(1), USE.NAMES = FALSE)

	resolved <- lapply(keys, function(key) {
		header_text <- register_columns[[key]]
		if (is.null(header_text)) {
			stop(sprintf("Unknown Register column key '%s': add it to required_register_columns in _data_helpers.R.", key), call. = FALSE)
		}
		col_index <- which(headers == normalise_header_text(header_text))
		if (length(col_index) == 0) {
			stop(sprintf(
				"Register sheet has no column headed '%s' (required column '%s'). Run tools/check_workbook.R for a full report.",
				header_text, key
			), call. = FALSE)
		}
		register_df[[col_index[1]]]
	})
	names(resolved) <- keys
	as.data.frame(resolved, stringsAsFactors = FALSE, check.names = FALSE)
}

#' Build + print a kable from a subset of Register columns identified by
#' logical keys, handling the HTML/LaTeX branching, blank-row filtering, and
#' standard styling shared by most Register-derived chapters (CAE-I/II, PUT,
#' assignments, attendance, ...).
#'
#' `name_key` identifies which of `keys` holds the student name, used both
#' to drop blank rows and to pick a sensible default column alignment.
render_register_table <- function(register_df, keys, labels, col_widths = NULL,
																	 font_size = 9, name_key = "student_name", tight = FALSE) {
	table_df <- get_register_columns(register_df, keys)
	names(table_df) <- labels

	name_label <- labels[match(name_key, keys)]
	if (!is.na(name_label)) {
		table_df <- table_df[!is.na(table_df[[name_label]]) & nzchar(trimws(as.character(table_df[[name_label]]))), ]
	}
	rownames(table_df) <- NULL

	align <- ifelse(keys == name_key, "l", "c")

	if (knitr::is_latex_output()) {
		tbl <- kableExtra::kbl(table_df, format = "latex", booktabs = TRUE, longtable = TRUE, align = align) |>
			kableExtra::kable_styling(
				latex_options = c("repeat_header", "HOLD_position", "striped"),
				stripe_color = "gray!12", font_size = font_size, full_width = FALSE
			)
		if (!is.null(col_widths)) {
			for (i in seq_along(col_widths)) {
				if (!is.na(col_widths[i])) tbl <- kableExtra::column_spec(tbl, i, width = col_widths[i])
			}
		}
		if (tight) cat("\\setlength{\\tabcolsep}{3pt}\n")
		print(tbl)
		if (tight) cat("\\setlength{\\tabcolsep}{6pt}\n")
	} else {
		print(kableExtra::kbl(table_df) |> kableExtra::kable_styling(bootstrap_options = c("striped")))
	}
	invisible(table_df)
}

#' Read + clean the 3-column Course Outcomes table (CO, Bloom's level,
#' statement) from a Course_Info-style sheet. Returns a data.frame with
#' columns CO/Bloom_Level/Course_Outcome, or NULL if the workbook is
#' missing (callers should check for NULL and call notify_workbook_missing()).
get_co_table <- function(sheet, range) {
	co_table <- read_workbook_sheet(sheet, range = range)
	if (is.null(co_table)) return(NULL)
	co_table <- as.data.frame(co_table)
	names(co_table) <- c("CO", "Bloom_Level", "Course_Outcome")
	co_table <- co_table[!is.na(co_table$CO) & nzchar(trimws(co_table$CO)), ]
	rownames(co_table) <- NULL
	co_table
}

#' Render the "Course Outcomes" table for display (wraps get_co_table()).
render_co_table <- function(sheet, range) {
	co_table <- get_co_table(sheet, range)
	if (is.null(co_table)) {
		notify_workbook_missing()
		return(invisible(NULL))
	}
	display_df <- co_table
	names(display_df) <- c("CO", "Bloom's Knowledge Level", "Course Outcome")

	if (knitr::is_latex_output()) {
		tbl <- kableExtra::kbl(display_df, format = "latex", booktabs = TRUE, longtable = TRUE, align = c("c", "c", "l")) |>
			kableExtra::kable_styling(latex_options = c("repeat_header", "HOLD_position", "striped"), font_size = 9, full_width = FALSE) |>
			kableExtra::column_spec(1, width = "0.55in") |>
			kableExtra::column_spec(2, width = "1.00in") |>
			kableExtra::column_spec(3, width = "4.25in")
		print(tbl)
	} else {
		print(kableExtra::kbl(display_df) |> kableExtra::kable_styling(bootstrap_options = c("striped")))
	}
	invisible(co_table)
}

#' Print the "**Course Code:** ... / **Course Name:** ..." header line read
#' from a Course_Info-style sheet.
render_course_header <- function(sheet, range) {
	course_header <- read_workbook_sheet(sheet, range = range)
	if (is.null(course_header)) return(invisible(NULL))
	course_header <- as.data.frame(course_header)
	cat("**Course Code:** ", trimws(as.character(course_header[1, 1])), "  \n", sep = "")
	cat("**Course Name:** ", trimws(as.character(course_header[1, 2])), "\n\n", sep = "")
	invisible(course_header)
}

#' Render the CO-PO/PSO mapping matrix (with the row-wise average) from the
#' long-format CO/PO/Level/Justification data in a Course_Info-style sheet.
#' Returns the cleaned long-format data invisibly so render_copo_justification()
#' can reuse it without re-reading the workbook.

#' Render the CO-PO/PSO mapping matrix with PO-wise averages.
#' Blank/NA Excel cells are displayed as "-" in the output.
#' Unmapped values are excluded from average calculations.
#' Returns cleaned long-format data invisibly.

render_copo_mapping <- function(sheet, range) {
    copo_long <- read_workbook_sheet(sheet, range = range)

    if (is.null(copo_long)) {
        notify_workbook_missing()
        return(invisible(NULL))
    }

    copo_long <- as.data.frame(copo_long)
    names(copo_long) <- c("CO", "PO", "Level", "Justification")

    # Remove rows without valid CO or PO identifiers
    copo_long$CO <- trimws(as.character(copo_long$CO))
    copo_long$PO <- trimws(as.character(copo_long$PO))

    copo_long <- copo_long[
        !is.na(copo_long$CO) & nzchar(copo_long$CO) &
        !is.na(copo_long$PO) & nzchar(copo_long$PO),
        ,
        drop = FALSE
    ]

    if (nrow(copo_long) == 0L) {
        return(invisible(copo_long))
    }

    # Normalize missing mapping levels
    copo_long$Level <- trimws(as.character(copo_long$Level))

    missing_level <- is.na(copo_long$Level) |
        copo_long$Level %in% c("", "NA", "N/A", "-")

    copo_long$Level[missing_level] <- "-"

    # Determine CO and PO order
    cos <- unique(copo_long$CO)
    pos <- unique(copo_long$PO)

    po_numbers <- suppressWarnings(
        as.numeric(gsub("\\D", "", pos))
    )

    pos <- pos[order(po_numbers, pos, na.last = TRUE)]

    # Initialize all unmapped cells with "-"
    mat <- matrix(
        "-",
        nrow = length(cos),
        ncol = length(pos),
        dimnames = list(cos, pos)
    )

    # Populate mapping matrix
    for (i in seq_len(nrow(copo_long))) {
        mat[copo_long$CO[i], copo_long$PO[i]] <-
            copo_long$Level[i]
    }

    copo_matrix <- data.frame(
        CO = rownames(mat),
        mat,
        check.names = FALSE,
        row.names = NULL
    )

    names(copo_matrix) <- c("CO", pos)

    # Calculate PO-wise averages, excluding unmapped cells
    po_averages <- vapply(pos, function(po) {

        values <- suppressWarnings(
            as.numeric(mat[, po])
        )

        if (all(is.na(values))) {
            "-"
        } else {
            formatC(
                mean(values, na.rm = TRUE),
                format = "f",
                digits = 2
            )
        }

    }, character(1))

    # Append average row
    average_row <- as.data.frame(
        as.list(c("Average", po_averages)),
        check.names = FALSE
    )

    names(average_row) <- c("CO", pos)

    copo_matrix <- rbind(copo_matrix, average_row)

    # Render table
    if (knitr::is_latex_output()) {

        copo_tbl <- kableExtra::kbl(
            copo_matrix,
            format = "latex",
            booktabs = TRUE,
            longtable = FALSE,
            align = "c",
            escape = TRUE
        ) |>
            kableExtra::column_spec(
                1,
                width = "0.85in"
            ) |>
            kableExtra::row_spec(
                nrow(copo_matrix),
                bold = TRUE
            )

        copo_latex <- as.character(copo_tbl)

        # Expand table to available line width
        copo_latex <- sub(
            "\\\\begin\\{tabular\\}(\\[[^]]*\\])?\\{([^}]*)\\}",
            "\\\\begin{tabular*}{\\\\linewidth}{@{\\\\extracolsep{\\\\fill}}\\2}",
            copo_latex,
            perl = TRUE
        )

        copo_latex <- sub(
            "\\\\end\\{tabular\\}",
            "\\\\end{tabular*}",
            copo_latex
        )

        cat(
            "\\begin{table}[!h]\n",
            "\\centering\n",
            copo_latex,
            "\n\\end{table}\n",
            sep = ""
        )

    } else {

        print(
            kableExtra::kbl(
                copo_matrix,
                align = "c"
            ) |>
                kableExtra::kable_styling(
                    bootstrap_options = c("striped")
                ) |>
                kableExtra::row_spec(
                    nrow(copo_matrix),
                    bold = TRUE
                )
        )
    }

    cat(
        "\n\nMapping scale: ",
        "1 = Slight (low), ",
        "2 = Moderate (medium), ",
        "3 = Substantial (high); ",
        "- = Not mapped. ",
        "Averages exclude unmapped values.\n\n",
        sep = ""
    )

    invisible(copo_long)
}


#' Render the per-CO mapping-justification tables that follow the CO-PO/PSO
#' matrix. `copo_long` is the long-format data.frame returned (invisibly) by
#' render_copo_mapping().

#' Render CO-PO/PSO mapping justification tables.
#' Skip rows where Level or Justification is blank, NA, N/A, or "-".

render_copo_justification <- function(copo_long) {

    if (is.null(copo_long)) {
        notify_workbook_missing()
        return(invisible(NULL))
    }

    # Normalize Level and Justification values
    copo_long$Level <- trimws(as.character(copo_long$Level))
    copo_long$Justification <- trimws(
        as.character(copo_long$Justification)
    )

    # Exclude unmapped or unjustified PO entries
    valid_rows <- !is.na(copo_long$Level) &
        !(toupper(copo_long$Level) %in% c("", "-", "NA", "N/A")) &
        !is.na(copo_long$Justification) &
        !(toupper(copo_long$Justification) %in% c("", "-", "NA", "N/A"))

    copo_long <- copo_long[valid_rows, , drop = FALSE]

    # Stop if no valid mappings remain
    if (nrow(copo_long) == 0L) {
        return(invisible(NULL))
    }

    cos <- unique(copo_long$CO)

    for (co in cos) {

        justification_df <- copo_long[
            copo_long$CO == co,
            c("PO", "Level", "Justification"),
            drop = FALSE
        ]

        names(justification_df) <- c(
            "PO",
            "Level",
            "Mapping Justification"
        )

        rownames(justification_df) <- NULL

        co_num <- sub(".*\\.", "", co)

        heading_label <- paste0(
            co, " (CO", co_num, ") Mapping Statements"
        )

        cat(
            "\n\n#### ",
            heading_label,
            " {.unnumbered}\n\n",
            sep = ""
        )

        if (knitr::is_latex_output()) {

            tbl <- kableExtra::kbl(
                justification_df,
                format = "latex",
                booktabs = TRUE,
                longtable = TRUE,
                align = c("c", "c", "l")
            ) |>
                kableExtra::kable_styling(
                    latex_options = c(
                        "repeat_header",
                        "striped"
                    ),
                    stripe_color = "gray!12",
                    font_size = 8,
                    full_width = FALSE
                ) |>
                kableExtra::column_spec(
                    1,
                    width = "0.45in"
                ) |>
                kableExtra::column_spec(
                    2,
                    width = "0.45in"
                ) |>
                kableExtra::column_spec(
                    3,
                    width = "4.65in"
                )

            print(tbl)

        } else {

            print(
                kableExtra::kbl(justification_df) |>
                    kableExtra::kable_styling(
                        bootstrap_options = c("striped")
                    )
            )
        }
    }

    invisible(NULL)
}
