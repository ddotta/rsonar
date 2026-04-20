#' @export
print.rsonar_result <- function(x, ...) {
  m    <- x$metrics
  debt <- x$debt

  cli::cli_h1("rsonar \u2014 Quality Report")
  cli::cli_inform(c(
    "i" = "Project  : {.path {x$path}}",
    "i" = "Analysis : {format(x$timestamp, '%Y-%m-%d %H:%M')}",
    "i" = "Files    : {m$n_files} R file(s)"
  ))

  cli::cli_h2("Metrics")
  cli::cli_inform(c(
    " " = glue::glue("Lint        : {m$n_lint_issues} issue(s) ",
                     "({m$n_lint_errors} err / {m$n_lint_warnings} warn / {m$n_lint_style} style)"),
    " " = glue::glue("Style       : {m$n_style_issues} non-compliant file(s)"),
    " " = glue::glue("Coverage    : {if (!is.na(m$coverage_pct)) paste0(m$coverage_pct, '%') else 'N/A'}"),
    " " = glue::glue("Goodpractice: {if (!is.na(m$gp_fails)) paste0(m$gp_fails, ' failure(s)') else 'N/A'}")
  ))

  if (!is.null(debt)) {
    rating_sym <- c(A = "\U0001f7e2", B = "\U0001f535", C = "\U0001f7e1",
                    D = "\U0001f7e0", E = "\U0001f534")
    cli::cli_h2("Technical Debt")
    cli::cli_inform(c(
      " " = "{rating_sym[[debt$rating]]} SQALE rating: {debt$rating}",
      " " = "\u23f1  Estimated duration: {debt$hours}h ({debt$minutes} min)"
    ))
  }

  cli::cli_inform(c(
    "i" = "Use {.fn sonar_report} to generate a full HTML report."
  ))
  invisible(x)
}

#' @export
summary.rsonar_result <- function(object, ...) {
  print(object, ...)
}
