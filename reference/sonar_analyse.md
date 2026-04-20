# Complete R Project Quality Analysis

Main function of `rsonar`. Orchestrates static analysis (lintr), style
checking (styler), test coverage measurement (covr) and packaging best
practices (goodpractice), then returns an `rsonar_result` object
summarizing all results.

## Usage

``` r
sonar_analyse(
  path = ".",
  include_lint = TRUE,
  include_style = TRUE,
  include_coverage = fs::dir_exists(fs::path(path, "tests")),
  include_goodpractice = fs::file_exists(fs::path(path, "DESCRIPTION")),
  exclude_pattern = "(\\.git|\\.ci|renv|packrat|vendor|node_modules|_snaps)",
  lintr_config = NULL,
  verbose = TRUE
)
```

## Arguments

- path:

  Path to the R project or package to analyze. Defaults to the current
  directory.

- include_lint:

  Logical. Enable lintr static analysis. Default `TRUE`.

- include_style:

  Logical. Enable styler style checking. Default `TRUE`.

- include_coverage:

  Logical. Enable covr coverage measurement. Default `TRUE` if a
  `tests/` directory exists.

- include_goodpractice:

  Logical. Enable goodpractice checks. Default `TRUE` if a `DESCRIPTION`
  file exists.

- exclude_pattern:

  Regular expression to exclude files. Default
  `"(\\.git|\\.ci|renv|packrat|vendor|node_modules|_snaps)"`.

- lintr_config:

  Path to a custom `.lintr` file. If `NULL`, rsonar automatically looks
  for `.lintr` in `path`.

- verbose:

  Logical. Show progress in the console. Default `TRUE`.

## Value

An object of class `rsonar_result` containing:

- `lint`:

  List of lintr issues (class `lints`)

- `style`:

  Data frame of files with style issues

- `coverage`:

  A covr object or `NULL`

- `goodpractice`:

  A goodpractice object or `NULL`

- `metrics`:

  Data frame of consolidated metrics

- `debt`:

  Technical debt estimate

- `path`:

  Analyzed path

- `timestamp`:

  Analysis date/time

## See also

[`sonar_report()`](https://ddotta.github.io/rsonar/reference/sonar_report.md),
[`debt_index()`](https://ddotta.github.io/rsonar/reference/debt_index.md),
[`quality_gate()`](https://ddotta.github.io/rsonar/reference/quality_gate.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Analyze the current package
res <- sonar_analyse(".")
print(res)

# Analyze without coverage (faster)
res <- sonar_analyse(".", include_coverage = FALSE)

# With a custom .lintr file
res <- sonar_analyse(".", lintr_config = "custom.lintr")
} # }
```
