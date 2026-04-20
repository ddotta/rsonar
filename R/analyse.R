#' Complete R Project Quality Analysis
#'
#' Main function of `rsonar`. Orchestrates static analysis (lintr),
#' style checking (styler), test coverage measurement (covr) and
#' packaging best practices (goodpractice), then returns an
#' `rsonar_result` object summarizing all results.
#'
#' @param path Path to the R project or package to analyze. Defaults to
#'   the current directory.
#' @param include_lint Logical. Enable lintr static analysis. Default `TRUE`.
#' @param include_style Logical. Enable styler style checking.
#'   Default `TRUE`.
#' @param include_coverage Logical. Enable covr coverage measurement.
#'   Default `TRUE` if a `tests/` directory exists.
#' @param include_goodpractice Logical. Enable goodpractice checks. Default
#'   `TRUE` if a `DESCRIPTION` file exists.
#' @param exclude_pattern Regular expression to exclude files.
#'   Default `"(\\.git|\\.ci|renv|packrat|vendor|node_modules|_snaps)"`.
#' @param lintr_config Path to a custom `.lintr` file. If `NULL`,
#'   rsonar automatically looks for `.lintr` in `path`.
#' @param verbose Logical. Show progress in the console. Default `TRUE`.
#'
#' @return An object of class `rsonar_result` containing:
#'   \describe{
#'     \item{`lint`}{List of lintr issues (class `lints`)}
#'     \item{`style`}{Data frame of files with style issues}
#'     \item{`coverage`}{A covr object or `NULL`}
#'     \item{`goodpractice`}{A goodpractice object or `NULL`}
#'     \item{`metrics`}{Data frame of consolidated metrics}
#'     \item{`debt`}{Technical debt estimate}
#'     \item{`path`}{Analyzed path}
#'     \item{`timestamp`}{Analysis date/time}
#'   }
#'
#' @examples
#' \dontrun{
#' # Analyze the current package
#' res <- sonar_analyse(".")
#' print(res)
#'
#' # Analyze without coverage (faster)
#' res <- sonar_analyse(".", include_coverage = FALSE)
#'
#' # With a custom .lintr file
#' res <- sonar_analyse(".", lintr_config = "custom.lintr")
#' }
#'
#' @seealso [sonar_report()], [debt_index()], [quality_gate()]
#' @export
sonar_analyse <- function(
    path = ".",
    include_lint = TRUE,
    include_style = TRUE,
    include_coverage = fs::dir_exists(fs::path(path, "tests")),
    include_goodpractice = fs::file_exists(fs::path(path, "DESCRIPTION")),
    exclude_pattern = "(\\.git|\\.ci|renv|packrat|vendor|node_modules|_snaps)",
    lintr_config = NULL,
    verbose = TRUE) {

  path <- fs::path_abs(path)

  .msg <- function(...) if (verbose) cli::cli_progress_step(...)

  .msg("Initializing rsonar analysis for {.path {path}}")

  # --- Collect R files ---
  all_r_files <- fs::dir_ls(path, recurse = TRUE, regexp = "\\.[Rr]$")
  r_files <- all_r_files[!grepl(exclude_pattern, all_r_files)]

  if (verbose) {
    cli::cli_inform(c(
      "i" = "{length(r_files)} R file(s) found"
    ))
  }

  # --- Lint ---
  lint_results <- NULL
  if (include_lint && length(r_files) > 0) {
    .msg("Static analysis (lintr)...")
    lint_results <- .run_lint(r_files, lintr_config = lintr_config, path = path)
  }

  # --- Style ---
  style_results <- NULL
  if (include_style && length(r_files) > 0) {
    .msg("Style checking (styler)...")
    style_results <- .run_style(r_files)
  }

  # --- Coverage ---
  coverage_results <- NULL
  if (include_coverage) {
    .msg("Coverage measurement (covr)...")
    coverage_results <- .run_coverage(path)
  }

  # --- Goodpractice ---
  gp_results <- NULL
  if (include_goodpractice) {
    .msg("Best practices check (goodpractice)...")
    gp_results <- .run_goodpractice(path)
  }

  # --- Consolidated metrics ---
  .msg("Computing metrics...")
  metrics <- .compute_metrics(
    r_files, lint_results, style_results,
    coverage_results, gp_results
  )

  # --- Technical debt ---
  debt <- .estimate_debt(metrics)

  if (verbose) {
    cli::cli_inform(c("v" = "Analysis complete."))
  }

  result <- structure(
    list(
      lint        = lint_results,
      style       = style_results,
      coverage    = coverage_results,
      goodpractice = gp_results,
      metrics     = metrics,
      debt        = debt,
      path        = path,
      r_files     = r_files,
      timestamp   = Sys.time()
    ),
    class = "rsonar_result"
  )

  result
}

# ---- Internal helpers -------------------------------------------------------

.run_lint <- function(r_files, lintr_config, path) {
  tryCatch({
    # Look for a .lintr in the project
    if (is.null(lintr_config)) {
      candidate <- fs::path(path, ".lintr")
      if (fs::file_exists(candidate)) lintr_config <- candidate
    }

    if (!is.null(lintr_config) && fs::file_exists(lintr_config)) {
      withr::with_dir(path, {
        lintr::lint_dir(path, linters = lintr::read_settings(lintr_config)$linters)
      })
    } else {
      lintr::lint_dir(path)
    }
  }, error = function(e) {
    cli::cli_warn("Lint error: {conditionMessage(e)}")
    list()
  })
}

.run_style <- function(r_files) {
  results <- lapply(r_files, function(f) {
    tryCatch({
      res <- styler::style_file(as.character(f), dry = "on")
      data.frame(
        file    = as.character(f),
        changed = isTRUE(res$changed[1]),
        stringsAsFactors = FALSE
      )
    }, error = function(e) {
      data.frame(file = as.character(f), changed = NA, stringsAsFactors = FALSE)
    })
  })
  do.call(rbind, results)
}

.run_coverage <- function(path) {
  tryCatch({
    withr::with_dir(path, {
      covr::package_coverage(path = path)
    })
  }, error = function(e) {
    cli::cli_warn("Coverage could not be computed: {conditionMessage(e)}")
    NULL
  })
}

.run_goodpractice <- function(path) {
  tryCatch({
    goodpractice::gp(path = path)
  }, error = function(e) {
    cli::cli_warn("goodpractice failed: {conditionMessage(e)}")
    NULL
  })
}

.compute_metrics <- function(r_files, lint_results, style_results,
                              coverage_results, gp_results) {
  n_files <- length(r_files)

  # Lint
  n_lint_issues   <- length(lint_results)
  lint_by_severity <- if (n_lint_issues > 0) {
    tbl <- table(vapply(lint_results, `[[`, character(1), "type"))
    as.list(tbl)
  } else list(error = 0L, warning = 0L, style = 0L)

  # Style
  n_style_issues <- if (!is.null(style_results)) {
    sum(style_results$changed, na.rm = TRUE)
  } else 0L

  # Coverage
  coverage_pct <- if (!is.null(coverage_results)) {
    round(covr::percent_coverage(coverage_results), 2)
  } else NA_real_

  # Goodpractice
  gp_fails <- if (!is.null(gp_results)) {
    length(goodpractice::failed_checks(gp_results))
  } else NA_integer_

  data.frame(
    n_files          = n_files,
    n_lint_issues    = n_lint_issues,
    n_lint_errors    = as.integer(lint_by_severity[["error"]] %||% 0L),
    n_lint_warnings  = as.integer(lint_by_severity[["warning"]] %||% 0L),
    n_lint_style     = as.integer(lint_by_severity[["style"]] %||% 0L),
    n_style_issues   = n_style_issues,
    coverage_pct     = coverage_pct,
    gp_fails         = gp_fails,
    stringsAsFactors = FALSE
  )
}

# Internal null-coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Internal debt estimate from metrics (lightweight version for sonar_analyse)
.estimate_debt <- function(metrics) {
  m <- metrics

  debt_lint_errors   <- m$n_lint_errors   * 30

  debt_lint_warnings <- m$n_lint_warnings * 10
  debt_lint_style    <- m$n_lint_style    * 2
  debt_style         <- m$n_style_issues  * 5
  debt_gp            <- if (!is.na(m$gp_fails)) m$gp_fails * 20 else 0L

  debt_coverage <- if (!is.na(m$coverage_pct)) {
    round(max(0, 80 - m$coverage_pct) * 5)
  } else 0L

  total_minutes <- debt_lint_errors + debt_lint_warnings + debt_lint_style +
                   debt_style + debt_gp + debt_coverage

  base_effort <- max(1, m$n_files) * 30
  ratio <- total_minutes / base_effort

  rating <- dplyr_style_case(ratio,
    list(c(0, 0.05) ~ "A",
         c(0.05, 0.10) ~ "B",
         c(0.10, 0.20) ~ "C",
         c(0.20, 0.50) ~ "D",
         c(0.50, Inf)  ~ "E")
  )

  list(
    minutes = total_minutes,
    hours   = round(total_minutes / 60, 2),
    rating  = rating,
    ratio   = ratio
  )
}
