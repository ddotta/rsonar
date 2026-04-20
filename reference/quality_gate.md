# Define and Check a Quality Gate

Reproduces the behavior of the SonarQube **Quality Gate**: defines
quality thresholds and returns `TRUE`/`FALSE` based on whether the
project meets them. In CI, the R process exit code can be set to 1 to
block the pipeline on failure.

## Usage

``` r
quality_gate(
  x,
  coverage_min = 80,
  lint_errors_max = 0,
  lint_warnings_max = Inf,
  style_issues_max = 0,
  gp_fails_max = Inf,
  rating_min = "C",
  fail_on_error = FALSE
)
```

## Arguments

- x:

  An `rsonar_result` object returned by
  [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md).

- coverage_min:

  Minimum required coverage in %. Default `80`. `NULL` to disable this
  threshold.

- lint_errors_max:

  Maximum number of tolerated lint errors. Default `0`.

- lint_warnings_max:

  Maximum number of tolerated lint warnings. Default `Inf`.

- style_issues_max:

  Maximum number of improperly formatted files. Default `0`.

- gp_fails_max:

  Maximum number of goodpractice failures. Default `Inf`.

- rating_min:

  Minimum required SQALE rating (`"A"` to `"E"`). Default `"C"`.

- fail_on_error:

  If `TRUE`, stops the R process with `quit(status = 1)` when the gate
  fails. Useful in CI. Default `FALSE`.

## Value

An `rsonar_gate` object (list) with:

- `passed`:

  `TRUE` if all thresholds are met

- `checks`:

  Detailed data frame of each check

## Examples

``` r
if (FALSE) { # \dontrun{
res <- sonar_analyse(".")

# Strict gate: 0 errors, 80% coverage
gate <- quality_gate(res, coverage_min = 80, lint_errors_max = 0)
print(gate)

# In CI: exit with code 1 on failure
quality_gate(res, coverage_min = 80, fail_on_error = TRUE)
} # }
```
