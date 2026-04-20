# Estimate Technical Debt

Computes a technical debt index inspired by the SQALE model used by
SonarQube. The index is expressed in estimated remediation minutes and
as a rating from A (excellent) to E (critical).

## Usage

``` r
debt_index(
  x,
  cost_lint_error = 30,
  cost_lint_warning = 10,
  cost_lint_style = 2,
  cost_style = 5,
  cost_gp = 20,
  coverage_target = 80,
  cost_coverage_point = 5
)
```

## Arguments

- x:

  An `rsonar_result` object returned by
  [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md).

- cost_lint_error:

  Cost in minutes per lint issue of type `error`. Default `30`.

- cost_lint_warning:

  Cost in minutes per lint warning. Default `10`.

- cost_lint_style:

  Cost in minutes per lint style violation. Default `2`.

- cost_style:

  Cost in minutes per improperly formatted file (styler). Default `5`.

- cost_gp:

  Cost in minutes per goodpractice failure. Default `20`.

- coverage_target:

  Target coverage in %. Default `80`.

- cost_coverage_point:

  Cost in minutes per missing coverage point below the target. Default
  `5`.

## Value

An `rsonar_debt` object (list) containing:

- `minutes`:

  Total estimated debt in minutes

- `hours`:

  Total estimated debt in hours

- `rating`:

  SQALE rating: "A", "B", "C", "D" or "E"

- `breakdown`:

  Data frame with details by category

## Examples

``` r
if (FALSE) { # \dontrun{
res <- sonar_analyse(".")
d <- debt_index(res)
print(d)
# Total debt: 2.5h — Rating: B
} # }
```
