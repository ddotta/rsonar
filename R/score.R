#' Quick Quality Score for IDE Usage
#'
#' Computes a quick quality percentage score for a project, designed for
#' fast feedback directly in the IDE without any CI platform.
#'
#' You can pass either:
#' - a path to an R project/package, or
#' - an existing `rsonar_result` object.
#'
#' The score is derived from the technical debt ratio:
#' `score = 100 * (1 - min(1, debt_ratio))`.
#'
#' @param x A path to analyze (character) or an `rsonar_result` object.
#'   Default `"."`.
#' @param include_coverage Logical. Include coverage in quick analysis when
#'   `x` is a path. Default `FALSE` for speed.
#' @param include_goodpractice Logical. Include goodpractice checks in quick
#'   analysis when `x` is a path. Default `FALSE` for speed.
#' @param verbose Logical. Show progress and summary in console.
#'   Default `TRUE`.
#'
#' @return An object of class `rsonar_score` with fields:
#'   `score` (0-100), `rating` (A-E), `ratio`, `path`, `timestamp`.
#'
#' @examples
#' \dontrun{
#' # Fast local check directly in IDE
#' quality_score(".")
#'
#' # Reuse an existing analysis
#' res <- sonar_analyse(".")
#' quality_score(res)
#' }
#'
#' @export
quality_score <- function(
    x = ".",
    include_coverage = FALSE,
    include_goodpractice = FALSE,
    verbose = TRUE) {

  res <- if (inherits(x, "rsonar_result")) {
    x
  } else if (is.character(x) && length(x) == 1L) {
    sonar_analyse(
      path = x,
      include_coverage = include_coverage,
      include_goodpractice = include_goodpractice,
      verbose = verbose
    )
  } else {
    cli::cli_abort("{.arg x} must be a path or an {.cls rsonar_result} object.")
  }

  if (is.null(res$debt) || is.null(res$debt$ratio)) {
    cli::cli_abort("Could not compute technical debt ratio for score calculation.")
  }

  ratio <- as.numeric(res$debt$ratio)
  score <- round(100 * (1 - min(1, ratio)), 1)

  out <- structure(
    list(
      score = score,
      rating = res$debt$rating,
      ratio = ratio,
      path = res$path,
      timestamp = res$timestamp
    ),
    class = "rsonar_score"
  )

  if (verbose) {
    print(out)
  }

  out
}

#' Print an rsonar_score Object
#'
#' @param x An `rsonar_score` object.
#' @param ... Additional arguments (ignored).
#' @return `x` invisibly.
#' @export
print.rsonar_score <- function(x, ...) {
  color <- if (x$score >= 80) "green" else if (x$score >= 60) "yellow" else "red"
  score_txt <- switch(
    color,
    green = cli::col_green(cli::style_bold(sprintf("%.1f%%", x$score))),
    yellow = cli::col_br_white(cli::style_bold(sprintf("%.1f%%", x$score))),
    cli::col_red(cli::style_bold(sprintf("%.1f%%", x$score)))
  )

  cli::cli_h2("Quick Quality Score")
  cli::cli_inform(c(
    "i" = "Path   : {.path {x$path}}",
    "i" = "Score  : {score_txt}",
    "i" = "Rating : {x$rating}",
    "i" = "Time   : {format(x$timestamp, '%Y-%m-%d %H:%M')}"
  ))
  invisible(x)
}
