# News

## rsonar 0.2.0 (2026-04-20)

### New features

* `sonar_diff()`: compare two analyses to detect regressions or improvements,
  similar to SonarQube's "New Code" analysis (#9)
* `export_sarif()`: export results in SARIF format for GitHub Code Scanning,
  VS Code and Azure DevOps integration (#10)
* `sonar_trend()`: persist analysis history to a JSON file for tracking
  quality metrics over time (#11)

### Documentation

* All documentation rewritten in English (roxygen, vignettes, README, pkgdown site)
* Vignettes updated with `sonar_diff()`, `export_sarif()` and `sonar_trend()`
  examples

## rsonar 0.1.0 (2026-04-20)

### New features

* `sonar_analyse()`: complete R project analysis (lintr + styler + covr + goodpractice) (#1)
* `sonar_report()`: interactive HTML dashboard report (#2)
* `quality_gate()`: configurable quality thresholds with CI exit code (#3)
* `debt_index()`: technical debt estimation using the SQALE model (#4)
* `export_sonar_json()`: export in SonarQube Generic Issue Import format (#5)
* `export_junit()`: JUnit XML export for GitLab CI / GitHub Actions (#6)
* `use_rsonar_lintr()`: copy the rsonar reference `.lintr` file (#7)
* `use_rsonar_ci()`: copy a CI pipeline template (GitLab or GitHub) (#8)

### Bundled templates

* `inst/templates/default.lintr`: lintr configuration aligned with SonarQube rules
* `inst/templates/ci/gitlab-rsonar.yml`: complete GitLab CI pipeline with separate stages
* `inst/templates/ci/github-rsonar.yml`: complete GitHub Actions workflow

### Documentation

* 4 vignettes: introduction, CI/CD, technical debt, alternatives
* pkgdown site with Bootstrap 5
