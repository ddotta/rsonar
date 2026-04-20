# 📦 Package `rsonar` ![](reference/figures/hex_rsonar.png)

## Overview

`rsonar` is the R equivalent of [SonarQube](https://www.sonarqube.org/):
it centralizes code quality analysis into a single interactive report,
estimates **technical debt** and integrates natively into GitLab CI and
GitHub Actions pipelines.

See [this repository](https://github.com/ddotta/rsonar-examples) that
illustrates some features of the rsonar package.

It orchestrates four proven tools:

| Tool                                                       | Role                                      |
|------------------------------------------------------------|-------------------------------------------|
| [lintr](https://lintr.r-lib.org/)                          | Static analysis — bugs, style, complexity |
| [styler](https://styler.r-lib.org/)                        | Code formatting (tidyverse style guide)   |
| [covr](https://covr.r-lib.org/)                            | Test coverage                             |
| [goodpractice](http://mangothecat.github.io/goodpractice/) | R packaging best practices                |

## SonarQube → rsonar Analogies

| SonarQube                  | rsonar                                                                        |
|----------------------------|-------------------------------------------------------------------------------|
| Issues (bugs, code smells) | lintr issues                                                                  |
| Style violations           | styler violations                                                             |
| Coverage                   | covr (line + branch)                                                          |
| Maintainability rating     | [`debt_index()`](https://ddotta.github.io/rsonar/reference/debt_index.md)     |
| Quality Gate               | [`quality_gate()`](https://ddotta.github.io/rsonar/reference/quality_gate.md) |
| HTML report                | [`sonar_report()`](https://ddotta.github.io/rsonar/reference/sonar_report.md) |
| Generic Issue Import       | SonarQube JSON export                                                         |
| New Code analysis          | [`sonar_diff()`](https://ddotta.github.io/rsonar/reference/sonar_diff.md)     |
| Project history            | [`sonar_trend()`](https://ddotta.github.io/rsonar/reference/sonar_trend.md)   |
| SARIF integration          | [`export_sarif()`](https://ddotta.github.io/rsonar/reference/export_sarif.md) |

## Installation

``` r
# From GitHub
remotes::install_github("SSM-Agriculture/rsonar")
```

## Quick Start

``` r
library(rsonar)

# Full analysis of an R package
res <- sonar_analyse("path/to/my/package")

# Console summary
print(res)

# Interactive HTML report
sonar_report(res, output = "quality.html")

# Technical debt index (A to E)
debt_index(res)

# Quality Gate (pass/fail like SonarQube)
quality_gate(res, coverage_min = 80, lint_errors_max = 0)

# Compare two analyses (regression detection)
diff <- sonar_diff(current_res, baseline_res)

# Track quality trends over time
sonar_trend(res)

# Export SonarQube Generic Issue Import format
export_sonar_json(res, "sonar-issues.json")

# Export SARIF for GitHub Code Scanning
export_sarif(res, "results.sarif")

# Export JUnit XML (for GitLab CI artifacts)
export_junit(res, "test-results.xml")
```

## Alternatives and Added Value

See the [full
documentation](https://SSM-Agriculture.github.io/rsonar/articles/alternatives.html).

## CI Integration

See the [CI/CD
examples](https://SSM-Agriculture.github.io/rsonar/articles/ci-integration.html).
