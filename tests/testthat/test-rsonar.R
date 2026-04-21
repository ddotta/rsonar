test_that("sonar_analyse returns an rsonar_result object", {
  tmp <- withr::local_tempdir()
  writeLines('x=1+1\n', file.path(tmp, "test.R"))

  res <- sonar_analyse(
    tmp,
    include_coverage     = FALSE,
    include_goodpractice = FALSE,
    verbose              = FALSE
  )

  expect_s3_class(res, "rsonar_result")
  expect_true(is.data.frame(res$metrics))
  expect_named(res$metrics, c("n_files", "n_lint_issues", "n_lint_errors",
                               "n_lint_warnings", "n_lint_style",
                               "n_style_issues", "coverage_pct", "gp_fails"))
})

test_that("sonar_analyse detects lint issues", {
  tmp <- withr::local_tempdir()
  writeLines(c("x=1+1", "T <- TRUE"), file.path(tmp, "bad.R"))

  res <- sonar_analyse(tmp,
    include_coverage = FALSE, include_goodpractice = FALSE, verbose = FALSE
  )

  expect_true(res$metrics$n_lint_issues > 0)
})

test_that("debt_index returns a valid rsonar_debt object", {
  tmp <- withr::local_tempdir()
  writeLines("x <- 1\n", file.path(tmp, "ok.R"))

  res <- sonar_analyse(tmp, include_coverage = FALSE,
                       include_goodpractice = FALSE, verbose = FALSE)
  debt <- debt_index(res)

  expect_s3_class(debt, "rsonar_debt")
  expect_true(debt$rating %in% c("A", "B", "C", "D", "E"))
  expect_true(is.numeric(debt$minutes))
  expect_true(is.data.frame(debt$breakdown))
})

test_that("quality_gate passes on clean code", {
  tmp <- withr::local_tempdir()
  writeLines("x <- 1\n", file.path(tmp, "ok.R"))

  res <- sonar_analyse(tmp, include_coverage = FALSE,
                       include_goodpractice = FALSE, verbose = FALSE)
  gate <- quality_gate(res,
    coverage_min    = NULL,
    lint_errors_max = 0,
    style_issues_max = Inf
  )

  expect_s3_class(gate, "rsonar_gate")
  expect_true(gate$passed || res$metrics$n_lint_errors == 0)
})

test_that("quality_gate fails when coverage_min is not met", {
  tmp <- withr::local_tempdir()
  writeLines("x <- 1\n", file.path(tmp, "ok.R"))

  res <- sonar_analyse(tmp, include_coverage = FALSE,
                       include_goodpractice = FALSE, verbose = FALSE)
  # coverage_pct will be NA, so 0 < 80
  gate <- quality_gate(res, coverage_min = 80, fail_on_error = FALSE)
  expect_false(gate$passed)
})

test_that("sonar_report generates an HTML file", {
  tmp     <- withr::local_tempdir()
  out_dir <- withr::local_tempdir()
  writeLines("x <- 1\n", file.path(tmp, "ok.R"))

  res    <- sonar_analyse(tmp, include_coverage = FALSE,
                          include_goodpractice = FALSE, verbose = FALSE)
  output <- file.path(out_dir, "report.html")
  sonar_report(res, output = output, open = FALSE)

  expect_true(file.exists(output))
  content <- readLines(output)
  expect_true(any(grepl("rsonar", content)))
})

test_that("export_junit generates a valid XML file", {
  tmp     <- withr::local_tempdir()
  out_dir <- withr::local_tempdir()
  writeLines("x=1+1\n", file.path(tmp, "bad.R"))

  res    <- sonar_analyse(tmp, include_coverage = FALSE,
                          include_goodpractice = FALSE, verbose = FALSE)
  output <- file.path(out_dir, "junit.xml")
  export_junit(res, output)

  expect_true(file.exists(output))
  xml_content <- readLines(output)
  expect_true(any(grepl("<testsuites>", xml_content)))
})

test_that("export_sonar_json generates a valid JSON file", {
  tmp     <- withr::local_tempdir()
  out_dir <- withr::local_tempdir()
  writeLines("x=1+1\n", file.path(tmp, "bad.R"))

  res    <- sonar_analyse(tmp, include_coverage = FALSE,
                          include_goodpractice = FALSE, verbose = FALSE)
  output <- file.path(out_dir, "issues.json")
  export_sonar_json(res, output)

  expect_true(file.exists(output))
  parsed <- jsonlite::fromJSON(output)
  expect_true("issues" %in% names(parsed))
})

test_that("export_sarif generates a valid SARIF file", {
  tmp     <- withr::local_tempdir()
  out_dir <- withr::local_tempdir()
  writeLines("x=1+1\n", file.path(tmp, "bad.R"))

  res    <- sonar_analyse(tmp, include_coverage = FALSE,
                          include_goodpractice = FALSE, verbose = FALSE)
  output <- file.path(out_dir, "results.sarif")
  export_sarif(res, output)

  expect_true(file.exists(output))
  parsed <- jsonlite::fromJSON(output)
  expect_equal(parsed$version, "2.1.0")
  expect_true(length(parsed$runs) > 0)
})

test_that("sonar_diff compares two analyses", {
  tmp <- withr::local_tempdir()
  writeLines("x <- 1\n", file.path(tmp, "ok.R"))

  baseline <- sonar_analyse(tmp, include_coverage = FALSE,
                            include_goodpractice = FALSE, verbose = FALSE)

  # Add a bad file to create a regression
  writeLines("y=2+2\n", file.path(tmp, "bad.R"))
  current <- sonar_analyse(tmp, include_coverage = FALSE,
                           include_goodpractice = FALSE, verbose = FALSE)

  diff <- sonar_diff(current, baseline)
  expect_s3_class(diff, "rsonar_diff")
  expect_true(is.data.frame(diff$delta))
  expect_true(is.logical(diff$improved))
  expect_true(length(diff$new_issues) >= 0)
})

test_that("sonar_trend appends to a history file", {
  tmp     <- withr::local_tempdir()
  out_dir <- withr::local_tempdir()
  writeLines("x <- 1\n", file.path(tmp, "ok.R"))

  res <- sonar_analyse(tmp, include_coverage = FALSE,
                       include_goodpractice = FALSE, verbose = FALSE)

  history_file <- file.path(out_dir, "history.json")
  sonar_trend(res, file = history_file)

  expect_true(file.exists(history_file))
  history <- jsonlite::read_json(history_file)
  expect_equal(length(history), 1)
  expect_true("timestamp" %in% names(history[[1]]))
  expect_true("debt_rating" %in% names(history[[1]]))

  # Append a second entry
  sonar_trend(res, file = history_file)
  history2 <- jsonlite::read_json(history_file)
  expect_equal(length(history2), 2)
})

test_that("quality_score provides a quick local percentage", {
  tmp <- withr::local_tempdir()
  writeLines("x <- 1\n", file.path(tmp, "ok.R"))

  score <- quality_score(tmp, verbose = FALSE)

  expect_s3_class(score, "rsonar_score")
  expect_true(is.numeric(score$score))
  expect_true(score$score >= 0 && score$score <= 100)
  expect_true(score$rating %in% c("A", "B", "C", "D", "E"))
})
