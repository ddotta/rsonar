# Compare Two rsonar Analyses

Computes the difference between two `rsonar_result` objects, similar to
SonarQube's "New Code" analysis. This is useful for detecting
regressions or improvements between two analysis runs (e.g., before and
after a pull request).

## Usage

``` r
sonar_diff(current, baseline)
```

## Arguments

- current:

  An `rsonar_result` object representing the current state.

- baseline:

  An `rsonar_result` object representing the baseline (e.g., main
  branch).

## Value

An `rsonar_diff` object (list) containing:

- `delta`:

  Data frame of metric deltas (metric, baseline, current, change)

- `improved`:

  Logical. `TRUE` if all metrics improved or stayed the same

- `new_issues`:

  Lint issues present in current but not in baseline

- `fixed_issues`:

  Lint issues present in baseline but not in current

## Examples

``` r
if (FALSE) { # \dontrun{
baseline <- sonar_analyse(".", include_coverage = FALSE)
# ... make changes ...
current  <- sonar_analyse(".", include_coverage = FALSE)
diff     <- sonar_diff(current, baseline)
print(diff)
} # }
```
