#' Record Analysis History for Trend Tracking
#'
#' Appends the current analysis results to a JSON history file, enabling
#' debt trend tracking over time. Each entry records the timestamp, commit
#' SHA (from CI environment variables), key metrics and SQALE rating.
#' This is analogous to SonarQube's project history.
#'
#' @param x An `rsonar_result` object returned by [sonar_analyse()].
#' @param file Path to the JSON history file. Default `"rsonar-history.json"`.
#'   Created automatically if it does not exist.
#'
#' @return The new history entry (invisibly), a list with `timestamp`, `commit`,
#'   `metrics` and `debt` fields.
#'
#' @examples
#' \dontrun{
#' res <- sonar_analyse(".")
#' sonar_trend(res)
#' sonar_trend(res, file = "quality-history.json")
#' }
#'
#' @export
sonar_trend <- function(x, file = "rsonar-history.json") {
  if (!inherits(x, "rsonar_result")) {
    cli::cli_abort("{.arg x} must be an {.cls rsonar_result} object.")
  }

  m <- x$metrics
  debt <- x$debt

  entry <- list(
    timestamp      = format(x$timestamp, "%Y-%m-%dT%H:%M:%S"),
    commit         = Sys.getenv("CI_COMMIT_SHA",
                       Sys.getenv("GITHUB_SHA", "local")),
    branch         = Sys.getenv("CI_COMMIT_REF_NAME",
                       Sys.getenv("GITHUB_REF_NAME", "local")),
    n_files        = m$n_files,
    lint_issues    = m$n_lint_issues,
    lint_errors    = m$n_lint_errors,
    style_issues   = m$n_style_issues,
    coverage_pct   = if (!is.na(m$coverage_pct)) m$coverage_pct else NULL,
    gp_fails       = if (!is.na(m$gp_fails)) m$gp_fails else NULL,
    debt_minutes   = if (!is.null(debt)) debt$minutes else 0,
    debt_rating    = if (!is.null(debt)) debt$rating else NA_character_
  )

  history <- if (file.exists(file)) {
    jsonlite::read_json(file)
  } else {
    list()
  }

  history <- c(history, list(entry))
  jsonlite::write_json(history, file, pretty = TRUE, auto_unbox = TRUE)

  cli::cli_inform(c(
    "v" = "History updated: {.path {file}} ({length(history)} entries)"
  ))

  invisible(entry)
}
