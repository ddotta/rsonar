#' Export Results in SonarQube Generic Issue Import Format
#'
#' Generates a JSON file compatible with the
#' [Generic Issue Import](https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/importing-external-issues/generic-issue-import-format/)
#' format of SonarQube. Allows injecting lintr results into an existing
#' SonarQube/SonarCloud instance via the
#' `sonar.externalIssuesReportPaths` property.
#'
#' @param x An `rsonar_result` object returned by [sonar_analyse()].
#' @param output Path to the output JSON file. Default `"sonar-issues.json"`.
#'
#' @return The path to the generated JSON file (invisibly).
#'
#' @examples
#' \dontrun{
#' res <- sonar_analyse(".")
#' export_sonar_json(res, "sonar-issues.json")
#' }
#'
#' @export
export_sonar_json <- function(x, output = "sonar-issues.json") {
  if (!inherits(x, "rsonar_result")) {
    cli::cli_abort("{.arg x} must be an {.cls rsonar_result} object.")
  }

  issues <- lapply(x$lint, function(issue) {
    severity <- switch(issue$type,
      error   = "CRITICAL",
      warning = "MAJOR",
      style   = "MINOR",
      "INFO"
    )
    list(
      engineId        = "lintr",
      ruleId          = issue$linter,
      severity        = severity,
      type            = if (issue$type == "error") "BUG" else "CODE_SMELL",
      primaryLocation = list(
        message   = issue$message,
        filePath  = fs::path_rel(issue$filename, x$path),
        textRange = list(
          startLine   = issue$line_number,
          endLine     = issue$line_number,
          startOffset = issue$column_number - 1L,
          endOffset   = issue$column_number
        )
      )
    )
  })

  json <- jsonlite::toJSON(list(issues = issues), auto_unbox = TRUE, pretty = TRUE)
  writeLines(json, output)
  cli::cli_inform(c("v" = "SonarQube JSON export: {.path {output}} ({length(issues)} issue(s))"))
  invisible(output)
}

#' Export Results in JUnit XML Format
#'
#' Generates a JUnit XML report consumable by GitLab CI, Jenkins,
#' GitHub Actions and SonarQube. Each lintr issue becomes a `<failure>`
#' within a `<testcase>`.
#'
#' @param x An `rsonar_result` object returned by [sonar_analyse()].
#' @param output Path to the output XML file. Default `"rsonar-junit.xml"`.
#'
#' @return The path to the generated XML file (invisibly).
#'
#' @examples
#' \dontrun{
#' res <- sonar_analyse(".")
#' export_junit(res, "junit-results.xml")
#' }
#'
#' @export
export_junit <- function(x, output = "rsonar-junit.xml") {
  if (!inherits(x, "rsonar_result")) {
    cli::cli_abort("{.arg x} must be an {.cls rsonar_result} object.")
  }

  m <- x$metrics
  n_failures <- m$n_lint_issues + m$n_style_issues

  testcases <- character(0)

  # Lint issues → failures
  for (issue in x$lint) {
    rel_path <- fs::path_rel(issue$filename, x$path)
    testcases <- c(testcases, glue::glue(
      '    <testcase name="{htmlEscape(issue$linter)}" classname="{htmlEscape(rel_path)}">\n',
      '      <failure type="{issue$type}" message="{htmlEscape(issue$message)}">',
      '{htmlEscape(rel_path)}:{issue$line_number}:{issue$column_number} [{issue$type}] {htmlEscape(issue$message)}',
      '</failure>\n',
      '    </testcase>\n'
    ))
  }

  # Style issues → failures
  if (!is.null(x$style)) {
    bad_files <- x$style[!is.na(x$style$changed) & x$style$changed, "file"]
    for (f in bad_files) {
      rel_path <- fs::path_rel(f, x$path)
      testcases <- c(testcases, glue::glue(
        '    <testcase name="style_check" classname="{htmlEscape(rel_path)}">\n',
        '      <failure type="style" message="File not formatted (styler)">',
        '{htmlEscape(rel_path)}: code does not follow the tidyverse style',
        '</failure>\n',
        '    </testcase>\n'
      ))
    }
  }

  xml <- paste0(
    '<?xml version="1.0" encoding="UTF-8"?>\n',
    '<testsuites>\n',
    '  <testsuite name="rsonar" tests="', n_failures, '" failures="', n_failures,
    '" errors="', m$n_lint_errors, '" timestamp="', format(x$timestamp, "%Y-%m-%dT%H:%M:%S"), '">\n',
    paste(testcases, collapse = ""),
    '  </testsuite>\n',
    '</testsuites>\n'
  )

  writeLines(xml, output)
  cli::cli_inform(c("v" = "JUnit XML export: {.path {output}} ({n_failures} failure(s))"))
  invisible(output)
}

#' Export Results in SARIF Format
#'
#' Generates a [SARIF](https://sarifweb.azurewebsites.net/) (Static Analysis
#' Results Interchange Format) file. SARIF is supported by GitHub Code Scanning,
#' VS Code, Azure DevOps and many other tools.
#'
#' @param x An `rsonar_result` object returned by [sonar_analyse()].
#' @param output Path to the output SARIF file. Default `"rsonar.sarif"`.
#'
#' @return The path to the generated SARIF file (invisibly).
#'
#' @examples
#' \dontrun{
#' res <- sonar_analyse(".")
#' export_sarif(res, "results.sarif")
#' }
#'
#' @export
export_sarif <- function(x, output = "rsonar.sarif") {
  if (!inherits(x, "rsonar_result")) {
    cli::cli_abort("{.arg x} must be an {.cls rsonar_result} object.")
  }

  results <- lapply(x$lint, function(issue) {
    level <- switch(issue$type,
      error   = "error",
      warning = "warning",
      style   = "note",
      "note"
    )
    list(
      ruleId  = issue$linter,
      level   = level,
      message = list(text = issue$message),
      locations = list(list(
        physicalLocation = list(
          artifactLocation = list(
            uri = fs::path_rel(issue$filename, x$path)
          ),
          region = list(
            startLine   = issue$line_number,
            startColumn = issue$column_number
          )
        )
      ))
    )
  })

  # Collect unique rule IDs for the rules array
  rule_ids <- unique(vapply(x$lint, `[[`, character(1), "linter"))
  rules <- lapply(rule_ids, function(rid) {
    list(
      id = rid,
      shortDescription = list(text = paste("lintr rule:", rid))
    )
  })

  sarif <- list(
    version = "2.1.0",
    `$schema` = "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json",
    runs = list(list(
      tool = list(
        driver = list(
          name            = "rsonar",
          informationUri  = "https://github.com/ddotta/rsonar",
          version         = as.character(utils::packageVersion("rsonar")),
          rules           = rules
        )
      ),
      results = results
    ))
  )

  json <- jsonlite::toJSON(sarif, auto_unbox = TRUE, pretty = TRUE)
  writeLines(json, output)
  cli::cli_inform(c("v" = "SARIF export: {.path {output}} ({length(results)} result(s))"))
  invisible(output)
}
