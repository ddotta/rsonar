# Generate an HTML Quality Report

Produces an interactive HTML report summarizing all results from
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md):
consolidated metrics, lint issues with file navigation, style
violations, test coverage and technical debt.

## Usage

``` r
sonar_report(
  x,
  output = "rsonar_report.html",
  title = "rsonar Quality Report",
  open = interactive()
)
```

## Arguments

- x:

  An `rsonar_result` object returned by
  [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md).

- output:

  Path to the output HTML file. Default `"rsonar_report.html"`.

- title:

  Report title. Default `"rsonar Quality Report"`.

- open:

  Open the report in a browser after generation. Default
  [`interactive()`](https://rdrr.io/r/base/interactive.html).

## Value

The path to the generated HTML file (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
res <- sonar_analyse(".")
sonar_report(res, output = "quality.html")
} # }
```
