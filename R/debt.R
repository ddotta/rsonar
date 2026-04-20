#' Estimate Technical Debt
#'
#' Computes a technical debt index inspired by the SQALE model used by
#' SonarQube. The index is expressed in estimated remediation minutes and as
#' a rating from A (excellent) to E (critical).
#'
#' @param x An `rsonar_result` object returned by [sonar_analyse()].
#' @param cost_lint_error Cost in minutes per lint issue of type `error`.
#'   Default `30`.
#' @param cost_lint_warning Cost in minutes per lint warning. Default `10`.
#' @param cost_lint_style Cost in minutes per lint style violation. Default `2`.
#' @param cost_style Cost in minutes per improperly formatted file (styler).
#'   Default `5`.
#' @param cost_gp Cost in minutes per goodpractice failure. Default `20`.
#' @param coverage_target Target coverage in %. Default `80`.
#' @param cost_coverage_point Cost in minutes per missing coverage point
#'   below the target. Default `5`.
#'
#' @return An `rsonar_debt` object (list) containing:
#'   \describe{
#'     \item{`minutes`}{Total estimated debt in minutes}
#'     \item{`hours`}{Total estimated debt in hours}
#'     \item{`rating`}{SQALE rating: "A", "B", "C", "D" or "E"}
#'     \item{`breakdown`}{Data frame with details by category}
#'   }
#'
#' @examples
#' \dontrun{
#' res <- sonar_analyse(".")
#' d <- debt_index(res)
#' print(d)
#' # Total debt: 2.5h — Rating: B
#' }
#'
#' @export
debt_index <- function(
    x,
    cost_lint_error     = 30,
    cost_lint_warning   = 10,
    cost_lint_style     = 2,
    cost_style          = 5,
    cost_gp             = 20,
    coverage_target     = 80,
    cost_coverage_point = 5) {

  if (!inherits(x, "rsonar_result")) {
    cli::cli_abort("{.arg x} must be an {.cls rsonar_result} object.")
  }

  m <- x$metrics

  debt_lint_errors   <- m$n_lint_errors   * cost_lint_error
  debt_lint_warnings <- m$n_lint_warnings * cost_lint_warning
  debt_lint_style    <- m$n_lint_style    * cost_lint_style
  debt_style         <- m$n_style_issues  * cost_style

  debt_gp <- if (!is.na(m$gp_fails)) m$gp_fails * cost_gp else 0L

  debt_coverage <- if (!is.na(m$coverage_pct)) {
    missing_pts <- max(0, coverage_target - m$coverage_pct)
    round(missing_pts * cost_coverage_point)
  } else 0L

  total_minutes <- debt_lint_errors + debt_lint_warnings + debt_lint_style +
                   debt_style + debt_gp + debt_coverage

  # SQALE rating (based on debt/size ratio)
  # Ratio = debt (min) / (n_files * 30 min per file)
  base_effort <- max(1, m$n_files) * 30
  ratio <- total_minutes / base_effort

  rating <- dplyr_style_case(ratio,
    list(c(0, 0.05) ~ "A",
         c(0.05, 0.10) ~ "B",
         c(0.10, 0.20) ~ "C",
         c(0.20, 0.50) ~ "D",
         c(0.50, Inf)  ~ "E")
  )

  breakdown <- data.frame(
    category = c("Lint (errors)", "Lint (warnings)", "Lint (style)",
                 "Style (styler)", "Best practices", "Coverage"),
    issues   = c(m$n_lint_errors, m$n_lint_warnings, m$n_lint_style,
                 m$n_style_issues, if (!is.na(m$gp_fails)) m$gp_fails else 0L,
                 if (!is.na(m$coverage_pct)) round(max(0, coverage_target - m$coverage_pct)) else 0L),
    minutes  = c(debt_lint_errors, debt_lint_warnings, debt_lint_style,
                 debt_style, debt_gp, debt_coverage),
    stringsAsFactors = FALSE
  )

  structure(
    list(
      minutes   = total_minutes,
      hours     = round(total_minutes / 60, 2),
      rating    = rating,
      ratio     = ratio,
      breakdown = breakdown
    ),
    class = "rsonar_debt"
  )
}

# Internal helper: simple dplyr::case_when equivalent
# Each case is a formula: c(lower, upper) ~ "label"
dplyr_style_case <- function(value, cases) {
  for (case in cases) {
    range <- eval(case[[2]])
    label <- eval(case[[3]])
    if (value >= range[1] && value < range[2]) return(label)
  }
  "E"
}

#' @export
print.rsonar_debt <- function(x, ...) {
  rating_color <- c(A = "green", B = "cyan", C = "yellow", D = "magenta", E = "red")
  col <- rating_color[[x$rating]]

  cli::cli_h2("rsonar Technical Debt")
  cli::cli_inform(c(
    "i" = "Estimated duration: {x$hours}h ({x$minutes} min)",
    "i" = cli::col_br_white("SQALE rating: ") %+% cli::style_bold(x$rating)
  ))
  cli::cli_h3("Breakdown by category")
  print(x$breakdown[x$breakdown$minutes > 0, c("category", "issues", "minutes")])
  invisible(x)
}
