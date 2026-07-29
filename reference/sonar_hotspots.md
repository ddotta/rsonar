# Rank Files by Technical Debt (Hotspots)

[`debt_index()`](https://ddotta.github.io/rsonar/reference/debt_index.md)
and
[`quality_score()`](https://ddotta.github.io/rsonar/reference/quality_score.md)
give a single project-wide number, but they don't tell you **where** to
start fixing things. `sonar_hotspots()` fills that gap: it breaks the
technical debt down **per file** and ranks files from the most to the
least costly to remediate – the R equivalent of SonarQube's "Code
Smells" / hotspots view, which developers use to prioritize their first
pull request after an audit.

## Usage

``` r
sonar_hotspots(
  x,
  n = 10,
  cost_lint_error = 30,
  cost_lint_warning = 10,
  cost_lint_style = 2,
  cost_style = 5
)
```

## Arguments

- x:

  An `rsonar_result` object returned by
  [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md).

- n:

  Maximum number of files to return. Default `10`.

- cost_lint_error:

  Cost in minutes per lint issue of type `error`. Default `30`.

- cost_lint_warning:

  Cost in minutes per lint warning. Default `10`.

- cost_lint_style:

  Cost in minutes per lint style violation. Default `2`.

- cost_style:

  Cost in minutes per improperly formatted file (styler). Default `5`.

## Value

An `rsonar_hotspots` object (a data frame) with one row per file,
ordered by decreasing debt, containing the columns:

- `rank`:

  Rank position, `1` = highest debt

- `file`:

  File path, relative to the analyzed project

- `lint_errors`, `lint_warnings`, `lint_style`:

  Issue counts by severity, from lintr

- `style_issue`:

  `TRUE` if the file needs re-formatting (styler)

- `coverage_pct`:

  Line coverage for the file, or `NA` if coverage was not computed or
  the file has no coverage data

- `debt_minutes`:

  Estimated remediation effort, in minutes

## See also

[`debt_index()`](https://ddotta.github.io/rsonar/reference/debt_index.md),
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md),
[`quality_gate()`](https://ddotta.github.io/rsonar/reference/quality_gate.md)

## Examples

``` r
if (FALSE) { # \dontrun{
res <- sonar_analyse(".")

# The 10 files that concentrate the most technical debt
hotspots <- sonar_hotspots(res)
print(hotspots)

# Only the top 3, with custom weights
sonar_hotspots(res, n = 3, cost_lint_error = 60)
} # }
```
