# 📦 Package `rsonar` ![](reference/figures/hex_rsonar.png)

## Overview

`rsonar` is the R equivalent of [SonarQube](https://www.sonarqube.org/):
it centralizes code quality analysis into a single interactive report,
estimates **technical debt** and integrates natively into GitLab CI and
GitHub Actions pipelines.

For a quick local check (without CI/forge), run `quality_score(".")` to
display a quality percentage directly in your IDE console.

See [this repository](https://github.com/ddotta/rsonar-examples) that
illustrates some features of the rsonar package.

It orchestrates four proven tools:

| Tool | Role |
|----|----|
| [lintr](https://lintr.r-lib.org/) | Static analysis — bugs, style, complexity |
| [styler](https://styler.r-lib.org/) | Code formatting (tidyverse style guide) |
| [covr](https://covr.r-lib.org/) | Test coverage |
| [goodpractice](http://mangothecat.github.io/goodpractice/) | R packaging best practices |

## SonarQube → rsonar Analogies

| SonarQube | rsonar |
|----|----|
| Issues (bugs, code smells) | lintr issues |
| Style violations | styler violations |
| Coverage | covr (line + branch) |
| Maintainability rating | [`debt_index()`](https://ddotta.github.io/rsonar/reference/debt_index.md) |
| Quality Gate | [`quality_gate()`](https://ddotta.github.io/rsonar/reference/quality_gate.md) |
| HTML report | [`sonar_report()`](https://ddotta.github.io/rsonar/reference/sonar_report.md) |
| Generic Issue Import | SonarQube JSON export |
| New Code analysis | [`sonar_diff()`](https://ddotta.github.io/rsonar/reference/sonar_diff.md) |
| Project history | [`sonar_trend()`](https://ddotta.github.io/rsonar/reference/sonar_trend.md) |
| SARIF integration | [`export_sarif()`](https://ddotta.github.io/rsonar/reference/export_sarif.md) |
| Hotspots / files to fix first | [`sonar_hotspots()`](https://ddotta.github.io/rsonar/reference/sonar_hotspots.md) |

## Installation

``` r

# From GitHub
remotes::install_github("ddotta/rsonar")
```

## Quick Start

``` r

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

# Hotspots: the files to fix first, ranked by debt
sonar_hotspots(res)

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

`print(res)` now also displays the **quality score (%)** alongside the
SQALE rating.

## Quick Local IDE Check

If you want instant feedback while coding (without CI), run:

``` r

library(rsonar)

# Fast local score (by default: no coverage/goodpractice for speed)
quality_score(".")
```

Typical output:

    ── Quick Quality Score ─────────────────────────────────────
    ℹ Path   : /path/to/project
    ℹ Score  : 82.4%
    ℹ Rating : B
    ℹ Time   : 2026-04-21 10:15

## Alternatives and Added Value

See the [full
documentation](https://ddotta.github.io/rsonar/index.html).

## Auto-Fix with air

`rsonar` integrates with [**air**](https://github.com/posit-dev/air),
Posit’s fast R code formatter, to automatically fix code style issues:

``` r

library(rsonar)

# Install air (once per machine)
install_air()

# Check what would be changed (dry-run)
fix <- sonar_fix(".", dry_run = TRUE)
print(fix)

# Auto-fix all R files in the project
fix <- sonar_fix(".")

# Auto-fix and create a Merge Request (GitLab CI)
fix <- sonar_fix(".", create_mr = TRUE)
```

In CI pipelines, `rsonar-fix` is an **optional manual job** that: 1.
Installs `air` via
[`install_air()`](https://ddotta.github.io/rsonar/reference/install_air.md)
2. Runs
[`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md)
to format all R files automatically 3. Creates a Merge Request (GitLab)
or Pull Request (GitHub) with the changes

This allows developers to review and merge auto-formatted code easily,
without manual intervention.

| Function | Purpose |
|----|----|
| [`install_air()`](https://ddotta.github.io/rsonar/reference/install_air.md) | Download and install the air formatter binary |
| [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md) | Run air on R files, optionally create MR/PR |

## CI Integration

See the [CI/CD
examples](https://ddotta.github.io/rsonar/articles/ci-integration.html).
