# Course-file table helpers: source this AFTER your existing _data_helpers.R.
# Existing workbook helpers (read_workbook_sheet, cf_sheet, cf_range,
# cf_value, notify_workbook_missing) remain unchanged.

course_table_output <- function(df, widths = NULL, font_size = 9,
                                caption = NULL, average_row = FALSE,
                                align = NULL,
                                merge_first_column = FALSE) {
  df <- as.data.frame(df, check.names = FALSE, stringsAsFactors = FALSE)
  df[] <- lapply(df, as.character)
  n <- nrow(df)
  if (is.null(align)) align <- c(rep("c", max(0, ncol(df) - 1)), "l")

  if (knitr::pandoc_to("docx")) {
    if (!requireNamespace("flextable", quietly = TRUE))
      stop("Please install flextable: install.packages('flextable')")
    ft <- flextable::flextable(df)
    ft <- flextable::theme_booktabs(ft)
    ft <- flextable::bold(ft, part = "header")
    ft <- flextable::bg(ft, part = "header", bg = "#E9EDF2")
    if (n > 1L) {
      idx <- seq.int(2L, n, by = 2L)
      if (average_row) idx <- idx[idx != n]
      if (length(idx)) ft <- flextable::bg(ft, i = idx, bg = "#F5F6F8", part = "body")
    }
    if (average_row && n) {
      ft <- flextable::bold(ft, i = n, part = "body")
      ft <- flextable::bg(ft, i = n, bg = "#E9EDF2", part = "body")
    }
    ft <- flextable::fontsize(ft, size = font_size, part = "all")
    ft <- flextable::valign(ft, valign = "center", part = "all")
    ft <- flextable::padding(ft, padding = 4, part = "all")
    for (j in seq_len(ncol(df))) {
      a <- switch(align[j], c = "center", r = "right", "left")
      ft <- flextable::align(ft, j = j, align = a, part = "all")
    }
    if (!is.null(widths)) {
      stopifnot(length(widths) == ncol(df))
      for (j in seq_along(widths))
        ft <- flextable::width(ft, j = j, width = widths[j])
    } else {
      ft <- flextable::autofit(ft)
    }
    if (!is.null(caption)) ft <- flextable::set_caption(ft, caption = caption)
    if (merge_first_column && nrow(df) > 1L) {
    ft <- flextable::merge_v(
        ft,
        j = 1,
        part = "body"
    )

    ft <- flextable::valign(
        ft,
        j = 1,
        valign = "center",
        part = "body"
    )
}
    ft <- flextable::set_table_properties(
      ft, layout = "fixed",
      opts_word = list(repeat_headers = TRUE, split = FALSE)
    )
    # This function is specifically for flextables inside loops/helpers in
    # Quarto/R Markdown chunks with results: asis.
    flextable::flextable_to_rmd(ft)

  } else if (knitr::is_latex_output()) {
    if (!requireNamespace("kableExtra", quietly = TRUE))
      stop("Please install kableExtra: install.packages('kableExtra')")
    tab <- kableExtra::kbl(df, format = "latex", booktabs = TRUE,
                            longtable = n > 15L, caption = caption,
                            row.names = FALSE, align = align)
    opts <- if (n > 15L) c("repeat_header", "striped") else "striped"
    tab <- kableExtra::kable_styling(tab, latex_options = opts,
                                     stripe_color = "gray!10",
                                     font_size = font_size, full_width = FALSE)
    if (!is.null(widths)) {
      stopifnot(length(widths) == ncol(df))
      for (j in seq_along(widths))
        tab <- kableExtra::column_spec(tab, j, width = paste0(widths[j], "in"))
    }
    if (average_row && n) tab <- kableExtra::row_spec(tab, n, bold = TRUE)
    if (merge_first_column && nrow(df) > 1L) {
    tab <- kableExtra::collapse_rows(
        tab,
        columns = 1,
        valign = "middle"
    )
}
    cat(as.character(tab), "\n\n", sep = "")

  } else if (knitr::is_html_output()) {
    if (!requireNamespace("kableExtra", quietly = TRUE))
      stop("Please install kableExtra: install.packages('kableExtra')")
    tab <- kableExtra::kbl(df, format = "html", caption = caption,
                            row.names = FALSE, align = align)
    tab <- kableExtra::kable_styling(tab,
               bootstrap_options = c("striped", "bordered", "condensed"),
               full_width = FALSE)
    if (average_row && n) tab <- kableExtra::row_spec(tab, n, bold = TRUE)
    if (merge_first_column && nrow(df) > 1L) {
    tab <- kableExtra::collapse_rows(
        tab,
        columns = 1,
        valign = "middle"
    )
}
    cat(as.character(tab), "\n\n", sep = "")
  } else {
    print(knitr::kable(df, caption = caption))
  }
  invisible(NULL)
}

get_co_table <- function(sheet, range) {
  x <- read_workbook_sheet(sheet, range = range)
  if (is.null(x)) return(NULL)
  x <- as.data.frame(x)
  if (ncol(x) != 3L) stop("CO table range must have three columns")
  names(x) <- c("CO", "Bloom_Level", "Course_Outcome")
  x$CO <- trimws(as.character(x$CO))
  x <- x[!is.na(x$CO) & nzchar(x$CO), , drop = FALSE]
  rownames(x) <- NULL
  x
}

render_course_header <- function(sheet, range) {
  x <- read_workbook_sheet(sheet, range = range)
  if (is.null(x)) {
    notify_workbook_missing()
    return(invisible(NULL))
  }
  x <- as.data.frame(x)
  if (nrow(x) < 1L || ncol(x) < 2L) stop("Course header needs at least two cells")
  cat("**Course Code:** ", trimws(as.character(x[1, 1])), "  \n",
      "**Course Name:** ", trimws(as.character(x[1, 2])), "\n\n", sep = "")
  invisible(x)
}

render_co_table <- function(sheet, range) {
  x <- get_co_table(sheet, range)
  if (is.null(x)) {
    notify_workbook_missing()
    return(invisible(NULL))
  }
  display <- x
  names(display) <- c("CO", "Bloom's Knowledge Level", "Course Outcome")
  course_table_output(display, widths = c(0.55, 1.15, 4.4),
                      align = c("c", "c", "l"))
  invisible(x)
}

render_copo_mapping <- function(sheet, range) {
  x <- read_workbook_sheet(sheet, range = range)
  if (is.null(x)) {
    notify_workbook_missing()
    return(invisible(NULL))
  }
  x <- as.data.frame(x)
  if (ncol(x) != 4L) stop("CO-PO mapping range must have four columns")
  names(x) <- c("CO", "PO", "Level", "Justification")
  x$CO <- trimws(as.character(x$CO))
  x$PO <- trimws(as.character(x$PO))
  x <- x[!is.na(x$CO) & nzchar(x$CO) &
           !is.na(x$PO) & nzchar(x$PO), , drop = FALSE]
  if (!nrow(x)) return(invisible(x))
  x$Level <- trimws(as.character(x$Level))
  x$Level[is.na(x$Level) | toupper(x$Level) %in%
            c("", "-", "NA", "N/A")] <- "-"
  cos <- unique(x$CO)
  pos <- unique(x$PO)
  po_number <- suppressWarnings(as.integer(gsub("\\D", "", pos)))
  pos <- pos[order(po_number, pos, na.last = TRUE)]
  mat <- matrix("-", nrow = length(cos), ncol = length(pos),
                dimnames = list(cos, pos))
  for (i in seq_len(nrow(x))) mat[x$CO[i], x$PO[i]] <- x$Level[i]
  out <- data.frame(CO = rownames(mat), mat, check.names = FALSE,
                    row.names = NULL)
  names(out) <- c("CO", pos)
  averages <- vapply(pos, function(po) {
    v <- suppressWarnings(as.numeric(mat[, po]))
    if (all(is.na(v))) "-" else sprintf("%.2f", mean(v, na.rm = TRUE))
  }, character(1))
  avg <- as.data.frame(as.list(c("Average", unname(averages))),
                       check.names = FALSE)
  names(avg) <- names(out)
  out <- rbind(out, avg)
  course_table_output(out, widths = c(0.9, rep(0.63, length(pos))),
                      align = rep("c", ncol(out)), average_row = TRUE)
  cat("\n\nMapping scale: 1 = Slight (low), 2 = Moderate (medium), ",
      "3 = Substantial (high); - = Not mapped. ",
      "PO-wise averages exclude unmapped values.\n\n", sep = "")
  invisible(x)
}

render_copo_justification <- function(copo_long) {
  if (is.null(copo_long)) {
    notify_workbook_missing()
    return(invisible(NULL))
  }
  x <- as.data.frame(copo_long)
  x$Level <- trimws(as.character(x$Level))
  x$Justification <- trimws(as.character(x$Justification))
  good <- !is.na(x$Level) & !toupper(x$Level) %in% c("", "-", "NA", "N/A") &
          !is.na(x$Justification) &
          !toupper(x$Justification) %in% c("", "-", "NA", "N/A")
  x <- x[good, , drop = FALSE]
  if (!nrow(x)) return(invisible(NULL))
  for (co in unique(x$CO)) {
    df <- x[x$CO == co, c("PO", "Level", "Justification"), drop = FALSE]
    names(df) <- c("PO", "Level", "Mapping Justification")
    rownames(df) <- NULL
    suffix <- sub(".*\\.", "", co)
    label <- if (grepl("^[0-9]+$", suffix))
      paste0(co, " (CO", suffix, ") Mapping Statements") else
      paste0(co, " Mapping Statements")
    cat("\n\n#### ", label, " {.unnumbered}\n\n", sep = "")
    course_table_output(df, widths = c(0.55, 0.55, 4.75), font_size = 8,
                        align = c("c", "c", "l"))
  }
  invisible(NULL)
}
