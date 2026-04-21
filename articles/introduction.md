# Introduction to rsonar

## Why rsonar?

Teams developing in **Python, Java or JavaScript** benefit from
[SonarQube](https://www.sonarqube.org/): a centralized tool that
analyzes code quality, measures test coverage, detects *code smells* and
calculates **technical debt**. R developers, however, must juggle
several disparate tools.

`rsonar` bridges this gap by orchestrating the best R tools available:

| Dimension       | Underlying tool                                                               | SonarQube equivalent       |
|-----------------|-------------------------------------------------------------------------------|----------------------------|
| Static analysis | `lintr`                                                                       | Issues (bugs, code smells) |
| Code style      | `styler`                                                                      | Style violations           |
| Test coverage   | `covr`                                                                        | Code coverage              |
| Best practices  | `goodpractice`                                                                | Maintainability checks     |
| Technical debt  | SQALE model                                                                   | Technical debt             |
| Quality Gate    | [`quality_gate()`](https://ddotta.github.io/rsonar/reference/quality_gate.md) | Quality Gate               |

------------------------------------------------------------------------

## Installation

``` r
# From GitHub (recommended)
remotes::install_github("ddotta/rsonar")
```

------------------------------------------------------------------------

## Typical Workflow

### 1. Analyze a project

``` r
library(rsonar)

# Full analysis (from the root of an R package)
res <- sonar_analyse("path/to/my/package")
```

The
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md)
function:

1.  Lists all `.R` files, excluding cache directories (`renv`,
    `packrat`, etc.)
2.  Runs
    [`lintr::lint_dir()`](https://lintr.r-lib.org/reference/lint.html)
    using the project’s `.lintr` file if present
3.  Checks style with `styler::style_file(..., dry = "on")`
4.  Measures coverage with
    [`covr::package_coverage()`](http://covr.r-lib.org/reference/package_coverage.md)
5.  Runs
    [`goodpractice::gp()`](https://docs.ropensci.org/goodpractice/reference/gp.html)
    on the package
6.  Computes **technical debt** using the SQALE model

### 2. View the console summary

``` r
print(res)
```

### 2bis. Get a quick quality percentage in your IDE

For rapid local feedback during development (without CI):

``` r
quality_score(".")
```

By default,
[`quality_score()`](https://ddotta.github.io/rsonar/reference/quality_score.md)
runs a fast analysis (coverage and goodpractice disabled) and displays a
percentage score plus the SQALE rating.

    ── rsonar — Quality Report ──────────────────────────────────
    ℹ Project  : /home/user/mypackage
    ℹ Analysis : 2026-04-20 14:32
    ℹ Files    : 8 R file(s)

    ── Metrics ──────────────────────────────────────────────────
      Lint        : 3 issue(s) (1 err / 2 warn / 0 style)
      Style       : 1 non-compliant file(s)
      Coverage    : 72.4%
      Goodpractice: 2 failure(s)

    ── Technical Debt ───────────────────────────────────────────
    🟡 SQALE rating: C
    ⏱  Estimated duration: 1.42h (85 min)

### 3. Generate the HTML report

``` r
sonar_report(res, output = "quality.html")
```

The HTML report contains:

- **Dashboard** with consolidated metrics and SQALE A→E rating
- **Lint issues list** with severity, file, line and rule
- **Improperly formatted files** detected by styler
- **Technical debt breakdown** by category and in minutes

### 4. Check the Quality Gate

``` r
gate <- quality_gate(res,
  coverage_min     = 80,   # 80% minimum coverage
  lint_errors_max  = 0,    # 0 errors tolerated
  style_issues_max = 0,    # all code must be formatted
  rating_min       = "C"   # minimum SQALE rating
)
print(gate)
```

    ── Quality Gate: PASSED ──────────────────────────────────────
    ✔ Coverage >= 80% [82.1%]
    ✔ Lint errors <= 0 [0]
    ✔ Style issues <= 0 [0]
    ✔ SQALE rating >= C [B]

### 5. Set up the project

``` r
# Add the recommended rsonar .lintr
use_rsonar_lintr()

# Add a pre-configured GitLab CI pipeline
use_rsonar_ci("gitlab")

# Or GitHub Actions
use_rsonar_ci("github")
```

------------------------------------------------------------------------

## Analyzing non-package projects (plain R scripts)

`rsonar` also works on projects that are **not** R packages:

``` r
res <- sonar_analyse(
  "path/to/project",
  include_coverage     = FALSE,  # no tests/
  include_goodpractice = FALSE   # no DESCRIPTION
)
sonar_report(res)
```

------------------------------------------------------------------------

## Comparing analyses

Use
[`sonar_diff()`](https://ddotta.github.io/rsonar/reference/sonar_diff.md)
to compare two analyses and detect regressions:

``` r
baseline <- sonar_analyse(".", include_coverage = FALSE)
# ... make changes ...
current  <- sonar_analyse(".", include_coverage = FALSE)
diff     <- sonar_diff(current, baseline)
print(diff)
```

------------------------------------------------------------------------

## Tracking trends over time

Use
[`sonar_trend()`](https://ddotta.github.io/rsonar/reference/sonar_trend.md)
in your CI pipeline to build a history of quality metrics:

``` r
res <- sonar_analyse(".")
sonar_trend(res, file = "rsonar-history.json")
```

------------------------------------------------------------------------

## Export for SonarQube

If your organization already uses SonarQube for other languages, you can
inject `rsonar` results via the **Generic Issue Import**:

``` r
export_sonar_json(res, "sonar-issues.json")
```

Then in `sonar-project.properties`:

    sonar.externalIssuesReportPaths=sonar-issues.json

## Export for GitHub Code Scanning (SARIF)

``` r
export_sarif(res, "results.sarif")
```

For GitLab CI with JUnit artifacts:

``` r
export_junit(res, "junit-results.xml")
```

------------------------------------------------------------------------

## Next steps

- [Alternatives and added value of
  rsonar](https://ddotta.github.io/rsonar/articles/alternatives.md)
- [Complete CI/CD
  integration](https://ddotta.github.io/rsonar/articles/ci-integration.md)
- [Understanding technical
  debt](https://ddotta.github.io/rsonar/articles/technical-debt.md)
