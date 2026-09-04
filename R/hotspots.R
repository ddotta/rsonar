#' Rank Files by Technical Debt (Hotspots)
#'
#' `debt_index()` and `quality_score()` give a single project-wide number,
#' but they don't tell you **where** to start fixing things. `sonar_hotspots()`
#' fills that gap: it breaks the technical debt down **per file** and ranks
#' files from the most to the least costly to remediate -- the R equivalent
#' of SonarQube's "Code Smells" / hotspots view, which developers use to
#' prioritize their first pull request after an audit.
#'
#' @param x An `rsonar_result` object returned by [sonar_analyse()].
#' @param n Maximum number of files to return. Default `10`.
#' @param cost_lint_error Cost in minutes per lint issue of type `error`.
#'   Default `30`.
#' @param cost_lint_warning Cost in minutes per lint warning. Default `10`.
#' @param cost_lint_style Cost in minutes per lint style violation. Default `2`.
#' @param cost_style Cost in minutes per improperly formatted file (styler).
#'   Default `5`.
#'
#' @return An `rsonar_hotspots` object (a data frame) with one row per file,
#'   ordered by decreasing debt, containing the columns:
#'   \describe{
#'     \item{`rank`}{Rank position, `1` = highest debt}
#'     \item{`file`}{File path, relative to the analyzed project}
#'     \item{`lint_errors`, `lint_warnings`, `lint_style`}{Issue counts by
#'       severity, from lintr}
#'     \item{`style_issue`}{`TRUE` if the file needs re-formatting (styler)}
#'     \item{`coverage_pct`}{Line coverage for the file, or `NA` if
#'       coverage was not computed or the file has no coverage data}
#'     \item{`debt_minutes`}{Estimated remediation effort, in minutes}
#'   }
#'
#' @examples
#' \dontrun{
#' res <- sonar_analyse(".")
#'
#' # The 10 files that concentrate the most technical debt
#' hotspots <- sonar_hotspots(res)
#' print(hotspots)
#'
#' # Only the top 3, with custom weights
#' sonar_hotspots(res, n = 3, cost_lint_error = 60)
#' }
#'
#' @seealso [debt_index()], [sonar_analyse()], [quality_gate()]
#' @export
sonar_hotspots <- function(
    x,
    n = 10,
    cost_lint_error   = 30,
    cost_lint_warning = 10,
    cost_lint_style   = 2,
    cost_style        = 5) {

  if (!inherits(x, "rsonar_result")) {
    cli::cli_abort("{.arg x} must be an {.cls rsonar_result} object.")
  }

  files <- as.character(x$r_files)
  if (length(files) == 0) {
    cli::cli_abort("No R files were analyzed in {.arg x}.")
  }

  base <- data.frame(
    file             = files,
    lint_errors      = 0L,
    lint_warnings    = 0L,
    lint_style       = 0L,
    style_issue      = FALSE,
    coverage_pct     = NA_real_,
    stringsAsFactors = FALSE
  )
  rownames(base) <- base$file

  # --- Lint issues, per file --------------------------------------------
  if (length(x$lint) > 0) {
    lint_file <- vapply(x$lint, function(i) as.character(i$filename), character(1))
    lint_type <- vapply(x$lint, function(i) as.character(i$type), character(1))

    # Match lint filenames to x$r_files robustly: lintr may return relative,
    # absolute or symlink-resolved paths, so fall back to basename matching.
    base_files <- as.character(base$file)
    base_names <- basename(base_files)

    lint_key <- vapply(lint_file, function(f) {
      if (f %in% base_files) return(f)
      abs_f <- as.character(fs::path_abs(f, start = x$path))
      if (abs_f %in% base_files) return(abs_f)
      b <- basename(f)
      hits <- base_files[base_names == b]
      if (length(hits) == 1L) return(hits[[1L]])
      NA_character_
    }, character(1))

    keep <- !is.na(lint_key)
    lint_key <- lint_key[keep]
    lint_type <- lint_type[keep]

    if (length(lint_key) > 0L) {
      tab <- table(lint_key, lint_type)
      tab_files <- rownames(tab)
      tab_types <- colnames(tab)

      for (f in tab_files) {
        if ("error"   %in% tab_types) base[f, "lint_errors"]   <- tab[f, "error"]
        if ("warning" %in% tab_types) base[f, "lint_warnings"] <- tab[f, "warning"]
        if ("style"   %in% tab_types) base[f, "lint_style"]    <- tab[f, "style"]
      }
    }
  }

  # --- Style (styler) issues, per file -----------------------------------
  if (!is.null(x$style) && nrow(x$style) > 0) {
    for (i in seq_len(nrow(x$style))) {
      f <- x$style$file[i]
      if (f %in% base$file && isTRUE(x$style$changed[i])) {
        base[f, "style_issue"] <- TRUE
      }
    }
  }

  # --- Coverage, per file --------------------------------------------------
  # covr filenames are not guaranteed to match r_files verbatim (relative vs.
  # absolute, different working directory at collection time), so files are
  # matched by path suffix rather than exact equality.
  if (!is.null(x$coverage)) {
    cov_list <- tryCatch(covr::coverage_to_list(x$coverage), error = function(e) NULL)
    fc <- cov_list$filecoverage
    if (!is.null(fc) && length(fc) > 0) {
      for (fc_name in names(fc)) {
        match_idx <- which(endsWith(base$file, fc_name) | endsWith(fc_name, base$file))
        if (length(match_idx) >= 1) {
          base[match_idx[1], "coverage_pct"] <- round(unname(fc[[fc_name]]), 2)
        }
      }
    }
  }

  # --- Per-file debt score --------------------------------------------------
  base$debt_minutes <- base$lint_errors   * cost_lint_error +
                        base$lint_warnings * cost_lint_warning +
                        base$lint_style    * cost_lint_style +
                        base$style_issue   * cost_style

  base <- base[order(-base$debt_minutes, base$file), , drop = FALSE]
  base <- base[seq_len(min(n, nrow(base))), , drop = FALSE]

  base$file <- fs::path_rel(base$file, start = x$path)
  base$rank <- seq_len(nrow(base))
  rownames(base) <- NULL

  base <- base[, c("rank", "file", "lint_errors", "lint_warnings", "lint_style",
                    "style_issue", "coverage_pct", "debt_minutes")]

  structure(base, class = c("rsonar_hotspots", class(base)))
}

#' Print an rsonar_hotspots Object
#'
#' @param x An `rsonar_hotspots` object.
#' @param ... Additional arguments (ignored).
#' @return `x` invisibly.
#' @export
print.rsonar_hotspots <- function(x, ...) {
  if (nrow(x) == 0) {
    cli::cli_inform(c("v" = "No hotspots detected -- nothing to prioritize."))
    return(invisible(x))
  }

  cli::cli_h2("rsonar Hotspots \u2014 Files to Fix First")

  for (i in seq_len(nrow(x))) {
    row <- x[i, ]

    details <- c(
      sprintf("%d error(s)", row$lint_errors),
      sprintf("%d warning(s)", row$lint_warnings),
      sprintf("%d style lint(s)", row$lint_style)
    )
    if (isTRUE(row$style_issue)) details <- c(details, "needs re-format")
    if (!is.na(row$coverage_pct)) details <- c(details, sprintf("coverage %s%%", row$coverage_pct))

    minutes_txt <- cli::style_bold(sprintf("%d min", row$debt_minutes))
    cli::cli_inform(
      "{row$rank}. {.file {row$file}} \u2014 {minutes_txt} ({paste(details, collapse = ', ')})"
    )
  }

  invisible(x)
}
