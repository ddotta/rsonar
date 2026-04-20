# Changelog

## rsonar 0.2.0 (2026-04-20)

#### New features

- [`sonar_diff()`](https://ddotta.github.io/rsonar/reference/sonar_diff.md):
  compare two analyses to detect regressions or improvements, similar to
  SonarQube’s “New Code” analysis
  ([\#9](https://github.com/ddotta/rsonar/issues/9))
- [`export_sarif()`](https://ddotta.github.io/rsonar/reference/export_sarif.md):
  export results in SARIF format for GitHub Code Scanning, VS Code and
  Azure DevOps integration
  ([\#10](https://github.com/ddotta/rsonar/issues/10))
- [`sonar_trend()`](https://ddotta.github.io/rsonar/reference/sonar_trend.md):
  persist analysis history to a JSON file for tracking quality metrics
  over time ([\#11](https://github.com/ddotta/rsonar/issues/11))

#### Documentation

- All documentation rewritten in English (roxygen, vignettes, README,
  pkgdown site)
- Vignettes updated with
  [`sonar_diff()`](https://ddotta.github.io/rsonar/reference/sonar_diff.md),
  [`export_sarif()`](https://ddotta.github.io/rsonar/reference/export_sarif.md)
  and
  [`sonar_trend()`](https://ddotta.github.io/rsonar/reference/sonar_trend.md)
  examples

## rsonar 0.1.0 (2026-04-20)

#### New features

- [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md):
  complete R project analysis (lintr + styler + covr + goodpractice)
  ([\#1](https://github.com/ddotta/rsonar/issues/1))
- [`sonar_report()`](https://ddotta.github.io/rsonar/reference/sonar_report.md):
  interactive HTML dashboard report
  ([\#2](https://github.com/ddotta/rsonar/issues/2))
- [`quality_gate()`](https://ddotta.github.io/rsonar/reference/quality_gate.md):
  configurable quality thresholds with CI exit code
  ([\#3](https://github.com/ddotta/rsonar/issues/3))
- [`debt_index()`](https://ddotta.github.io/rsonar/reference/debt_index.md):
  technical debt estimation using the SQALE model
  ([\#4](https://github.com/ddotta/rsonar/issues/4))
- [`export_sonar_json()`](https://ddotta.github.io/rsonar/reference/export_sonar_json.md):
  export in SonarQube Generic Issue Import format
  ([\#5](https://github.com/ddotta/rsonar/issues/5))
- [`export_junit()`](https://ddotta.github.io/rsonar/reference/export_junit.md):
  JUnit XML export for GitLab CI / GitHub Actions
  ([\#6](https://github.com/ddotta/rsonar/issues/6))
- [`use_rsonar_lintr()`](https://ddotta.github.io/rsonar/reference/use_rsonar_lintr.md):
  copy the rsonar reference `.lintr` file
  ([\#7](https://github.com/ddotta/rsonar/issues/7))
- [`use_rsonar_ci()`](https://ddotta.github.io/rsonar/reference/use_rsonar_ci.md):
  copy a CI pipeline template (GitLab or GitHub)
  ([\#8](https://github.com/ddotta/rsonar/issues/8))

#### Bundled templates

- `inst/templates/default.lintr`: lintr configuration aligned with
  SonarQube rules
- `inst/templates/ci/gitlab-rsonar.yml`: complete GitLab CI pipeline
  with separate stages
- `inst/templates/ci/github-rsonar.yml`: complete GitHub Actions
  workflow

#### Documentation

- 4 vignettes: introduction, CI/CD, technical debt, alternatives
- pkgdown site with Bootstrap 5
