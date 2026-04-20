#' Define and Check a Quality Gate
#'
#' Reproduces the behavior of the SonarQube **Quality Gate**:
#' defines quality thresholds and returns `TRUE`/`FALSE` based on whether
#' the project meets them. In CI, the R process exit code can be set to 1
#' to block the pipeline on failure.
#'
#' @param x An `rsonar_result` object returned by [sonar_analyse()].
#' @param coverage_min Minimum required coverage in %. Default `80`. `NULL`
#'   to disable this threshold.
#' @param lint_errors_max Maximum number of tolerated lint errors. Default `0`.
#' @param lint_warnings_max Maximum number of tolerated lint warnings. Default `Inf`.
#' @param style_issues_max Maximum number of improperly formatted files. Default `0`.
#' @param gp_fails_max Maximum number of goodpractice failures. Default `Inf`.
#' @param rating_min Minimum required SQALE rating (`"A"` to `"E"`). Default `"C"`.
#' @param fail_on_error If `TRUE`, stops the R process with `quit(status = 1)`
#'   when the gate fails. Useful in CI. Default `FALSE`.
#'
#' @return An `rsonar_gate` object (list) with:
#'   \describe{
#'     \item{`passed`}{`TRUE` if all thresholds are met}
#'     \item{`checks`}{Detailed data frame of each check}
#'   }
#'
#' @examples
#' \dontrun{
#' res <- sonar_analyse(".")
#'
#' # Strict gate: 0 errors, 80% coverage
#' gate <- quality_gate(res, coverage_min = 80, lint_errors_max = 0)
#' print(gate)
#'
#' # In CI: exit with code 1 on failure
#' quality_gate(res, coverage_min = 80, fail_on_error = TRUE)
#' }
#'
#' @export
quality_gate <- function(
    x,
    coverage_min      = 80,
    lint_errors_max   = 0,
    lint_warnings_max = Inf,
    style_issues_max  = 0,
    gp_fails_max      = Inf,
    rating_min        = "C",
    fail_on_error     = FALSE) {

  if (!inherits(x, "rsonar_result")) {
    cli::cli_abort("{.arg x} must be an {.cls rsonar_result} object.")
  }

  m <- x$metrics
  debt <- x$debt

  checks <- list()

  # Coverage
  if (!is.null(coverage_min)) {
    cov_val <- if (!is.na(m$coverage_pct)) m$coverage_pct else 0
    checks[["coverage"]] <- data.frame(
      check    = paste0("Coverage >= ", coverage_min, "%"),
      value    = paste0(cov_val, "%"),
      expected = paste0(">= ", coverage_min, "%"),
      passed   = cov_val >= coverage_min,
      stringsAsFactors = FALSE
    )
  }

  # Lint errors
  checks[["lint_errors"]] <- data.frame(
    check    = paste0("Lint errors <= ", lint_errors_max),
    value    = as.character(m$n_lint_errors),
    expected = paste0("<= ", lint_errors_max),
    passed   = m$n_lint_errors <= lint_errors_max,
    stringsAsFactors = FALSE
  )

  # Lint warnings
  if (is.finite(lint_warnings_max)) {
    checks[["lint_warnings"]] <- data.frame(
      check    = paste0("Lint warnings <= ", lint_warnings_max),
      value    = as.character(m$n_lint_warnings),
      expected = paste0("<= ", lint_warnings_max),
      passed   = m$n_lint_warnings <= lint_warnings_max,
      stringsAsFactors = FALSE
    )
  }

  # Style
  checks[["style"]] <- data.frame(
    check    = paste0("Style issues <= ", style_issues_max),
    value    = as.character(m$n_style_issues),
    expected = paste0("<= ", style_issues_max),
    passed   = m$n_style_issues <= style_issues_max,
    stringsAsFactors = FALSE
  )

  # Goodpractice
  if (is.finite(gp_fails_max) && !is.na(m$gp_fails)) {
    checks[["gp"]] <- data.frame(
      check    = paste0("Goodpractice failures <= ", gp_fails_max),
      value    = as.character(m$gp_fails),
      expected = paste0("<= ", gp_fails_max),
      passed   = m$gp_fails <= gp_fails_max,
      stringsAsFactors = FALSE
    )
  }

  # SQALE rating
  rating_order <- c(A = 1, B = 2, C = 3, D = 4, E = 5)
  if (!is.null(debt)) {
    checks[["rating"]] <- data.frame(
      check    = paste0("SQALE rating >= ", rating_min),
      value    = debt$rating,
      expected = paste0("<= ", rating_min),
      passed   = rating_order[[debt$rating]] <= rating_order[[rating_min]],
      stringsAsFactors = FALSE
    )
  }

  checks_df <- do.call(rbind, checks)
  all_passed <- all(checks_df$passed)

  gate <- structure(
    list(passed = all_passed, checks = checks_df),
    class = "rsonar_gate"
  )

  if (!all_passed && fail_on_error) {
    print(gate)
    cli::cli_abort("Quality Gate \u00e9chou\u00e9 — arr\u00eat de la pipeline.")
  }

  gate
}

#' @export
print.rsonar_gate <- function(x, ...) {
  status <- if (x$passed) {
    cli::col_green(cli::style_bold("PASSED"))
  } else {
    cli::col_red(cli::style_bold("FAILED"))
  }
  cli::cli_h2("Quality Gate : {status}")
  for (i in seq_len(nrow(x$checks))) {
    row <- x$checks[i, ]
    icon <- if (row$passed) cli::col_green("\u2714") else cli::col_red("\u2718")
    cli::cli_inform("{icon} {row$check} [{row$value}]")
  }
  invisible(x)
}
