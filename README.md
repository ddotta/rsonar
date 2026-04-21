# :package: Package `rsonar` <img src="man/figures/hex_rsonar.png" width=110 align="right"/>

<!-- badges: start -->
[![R-CMD-check](https://github.com/SSM-Agriculture/rsonar/workflows/R-CMD-check/badge.svg)](https://github.com/SSM-Agriculture/rsonar/actions)
[![Codecov](https://codecov.io/gh/SSM-Agriculture/rsonar/branch/main/graph/badge.svg)](https://codecov.io/gh/SSM-Agriculture/rsonar)
[![CRAN status](https://www.r-pkg.org/badges/version/rsonar)](https://CRAN.R-project.org/package=rsonar)
<!-- badges: end -->

## Overview

`rsonar` is the R equivalent of [SonarQube](https://www.sonarqube.org/): it centralizes code quality analysis into a single interactive report, estimates **technical debt** and integrates natively into GitLab CI and GitHub Actions pipelines.  

For a quick local check (without CI/forge), run `quality_score(".")` to display a quality percentage directly in your IDE console.

See [this repository](https://github.com/ddotta/rsonar-examples) that illustrates some features of the rsonar package.  

It orchestrates four proven tools:

| Tool | Role |
|---|---|
| [lintr](https://lintr.r-lib.org/) | Static analysis — bugs, style, complexity |
| [styler](https://styler.r-lib.org/) | Code formatting (tidyverse style guide) |
| [covr](https://covr.r-lib.org/) | Test coverage |
| [goodpractice](http://mangothecat.github.io/goodpractice/) | R packaging best practices |

## SonarQube → rsonar Analogies

| SonarQube | rsonar |
|---|---|
| Issues (bugs, code smells) | lintr issues |
| Style violations | styler violations |
| Coverage | covr (line + branch) |
| Maintainability rating | `debt_index()` |
| Quality Gate | `quality_gate()` |
| HTML report | `sonar_report()` |
| Generic Issue Import | SonarQube JSON export |
| New Code analysis | `sonar_diff()` |
| Project history | `sonar_trend()` |
| SARIF integration | `export_sarif()` |

## Installation

```r
# From GitHub
remotes::install_github("SSM-Agriculture/rsonar")
```

## Quick Start

```r
library(rsonar)

# Full analysis of an R package
res <- sonar_analyse("path/to/my/package")

# Console summary
print(res)

# Quick local quality percentage in IDE
quality_score(res)

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

`print(res)` now also displays the **quality score (%)** alongside the SQALE rating.

## Quick Local IDE Check

If you want instant feedback while coding (without CI), run:

```r
library(rsonar)

# Fast local score (by default: no coverage/goodpractice for speed)
quality_score(".")
```

Typical output:

```
── Quick Quality Score ─────────────────────────────────────
ℹ Path   : /path/to/project
ℹ Score  : 82.4%
ℹ Rating : B
ℹ Time   : 2026-04-21 10:15
```

## Alternatives and Added Value

See the [full documentation](https://SSM-Agriculture.github.io/rsonar/articles/alternatives.html).

## CI Integration

See the [CI/CD examples](https://SSM-Agriculture.github.io/rsonar/articles/ci-integration.html).
