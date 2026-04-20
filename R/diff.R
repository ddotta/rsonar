#' Compare Two rsonar Analyses
#'
#' Computes the difference between two `rsonar_result` objects, similar
#' to SonarQube's "New Code" analysis. This is useful for detecting
#' regressions or improvements between two analysis runs (e.g., before
#' and after a pull request).
#'
#' @param current An `rsonar_result` object representing the current state.
#' @param baseline An `rsonar_result` object representing the baseline
#'   (e.g., main branch).
#'
#' @return An `rsonar_diff` object (list) containing:
#'   \describe{
#'     \item{`delta`}{Data frame of metric deltas (metric, baseline, current, change)}
#'     \item{`improved`}{Logical. `TRUE` if all metrics improved or stayed the same}
#'     \item{`new_issues`}{Lint issues present in current but not in baseline}
#'     \item{`fixed_issues`}{Lint issues present in baseline but not in current}
#'   }
#'
#' @examples
#' \dontrun{
#' baseline <- sonar_analyse(".", include_coverage = FALSE)
#' # ... make changes ...
#' current  <- sonar_analyse(".", include_coverage = FALSE)
#' diff     <- sonar_diff(current, baseline)
#' print(diff)
#' }
#'
#' @export
sonar_diff <- function(current, baseline) {
  if (!inherits(current, "rsonar_result")) {
    cli::cli_abort("{.arg current} must be an {.cls rsonar_result} object.")
  }
  if (!inherits(baseline, "rsonar_result")) {
    cli::cli_abort("{.arg baseline} must be an {.cls rsonar_result} object.")
  }

  mc <- current$metrics
  mb <- baseline$metrics

  metrics <- c("n_lint_issues", "n_lint_errors", "n_lint_warnings",
                "n_lint_style", "n_style_issues", "coverage_pct", "gp_fails")

  labels <- c("Lint issues", "Lint errors", "Lint warnings",
               "Lint style", "Style issues", "Coverage (%)", "Goodpractice failures")

  delta <- data.frame(
    metric   = labels,
    baseline = vapply(metrics, function(m) as.numeric(mb[[m]]), numeric(1)),
    current  = vapply(metrics, function(m) as.numeric(mc[[m]]), numeric(1)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  delta$change <- delta$current - delta$baseline

  # For coverage, improvement means increase, so invert the "worse" logic
  worse <- rep(FALSE, nrow(delta))
  for (i in seq_len(nrow(delta))) {
    if (is.na(delta$change[i])) next
    if (metrics[i] == "coverage_pct") {
      worse[i] <- delta$change[i] < 0
    } else {
      worse[i] <- delta$change[i] > 0
    }
  }

  # Debt comparison
  debt_current  <- if (!is.null(current$debt)) current$debt$minutes else 0
  debt_baseline <- if (!is.null(baseline$debt)) baseline$debt$minutes else 0
  debt_delta    <- debt_current - debt_baseline

  delta <- rbind(delta, data.frame(
    metric   = "Technical debt (min)",
    baseline = debt_baseline,
    current  = debt_current,
    change   = debt_delta,
    stringsAsFactors = FALSE,
    row.names = NULL
  ))
  worse <- c(worse, debt_delta > 0)

  # Identify new and fixed lint issues
  current_sigs  <- .lint_signatures(current$lint, current$path)
  baseline_sigs <- .lint_signatures(baseline$lint, baseline$path)

  new_issues   <- current$lint[!current_sigs %in% baseline_sigs]
  fixed_issues <- baseline$lint[!baseline_sigs %in% current_sigs]

  improved <- !any(worse, na.rm = TRUE)

  structure(
    list(
      delta        = delta,
      improved     = improved,
      new_issues   = new_issues,
      fixed_issues = fixed_issues
    ),
    class = "rsonar_diff"
  )
}

# Create a unique signature for each lint issue for comparison
.lint_signatures <- function(lint_list, base_path) {
  if (length(lint_list) == 0) return(character(0))
  vapply(lint_list, function(issue) {
    paste0(
      fs::path_rel(issue$filename, base_path), ":",
      issue$line_number, ":",
      issue$linter, ":",
      issue$type
    )
  }, character(1))
}

#' @export
print.rsonar_diff <- function(x, ...) {
  status <- if (x$improved) {
    cli::col_green(cli::style_bold("IMPROVED"))
  } else {
    cli::col_red(cli::style_bold("REGRESSED"))
  }
  cli::cli_h2("rsonar Diff: {status}")

  for (i in seq_len(nrow(x$delta))) {
    row <- x$delta[i, ]
    if (is.na(row$change) || row$change == 0) {
      icon <- cli::col_cyan("\u2500")
      sign <- ""
    } else if ((row$metric == "Coverage (%)" && row$change > 0) ||
               (row$metric != "Coverage (%)" && row$change < 0)) {
      icon <- cli::col_green("\u2193")
      sign <- ""
    } else {
      icon <- cli::col_red("\u2191")
      sign <- "+"
    }
    cli::cli_inform("{icon} {row$metric}: {row$baseline} -> {row$current} ({sign}{row$change})")
  }

  if (length(x$new_issues) > 0) {
    cli::cli_inform(c("!" = "{length(x$new_issues)} new issue(s) introduced"))
  }
  if (length(x$fixed_issues) > 0) {
    cli::cli_inform(c("v" = "{length(x$fixed_issues)} issue(s) fixed"))
  }

  invisible(x)
}
