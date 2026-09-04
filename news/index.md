# Changelog

## rsonar 0.3.0 (2026-04-20)

#### New features

- [`sonar_hotspots()`](https://ddotta.github.io/rsonar/reference/sonar_hotspots.md):
  ranks files by estimated technical debt so developers know which ones
  to fix first, similar to SonarQube’s “Code Smells” / hotspots view.
  Previously
  [`debt_index()`](https://ddotta.github.io/rsonar/reference/debt_index.md)
  only reported a single project-wide score with no per-file breakdown
  ([\#12](https://github.com/ddotta/rsonar/issues/12))
- [`sonar_report()`](https://ddotta.github.io/rsonar/reference/sonar_report.md):
  the HTML report now includes a “Hotspots - Files to Fix First” section
  (top 10 files by debt), placed right after the Technical Debt summary
  ([\#12](https://github.com/ddotta/rsonar/issues/12))
- [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md):
  new `unused_vars` category detects and removes variable assignments
  that are never read within the same file, using conservative
  heuristics to avoid false positives
  ([\#13](https://github.com/ddotta/rsonar/issues/13))
- [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md):
  new `duplicate_libs` category detects and removes duplicate
  [`library()`](https://rdrr.io/r/base/library.html) calls loading the
  same package multiple times
  ([\#13](https://github.com/ddotta/rsonar/issues/13))

#### Improvements

- [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md):
  the `simplify` category now handles compound boolean expressions
  (`x == TRUE && y` → `x && y`, `x == FALSE \|\| y` → `!x \|\| y`) in
  addition to simple patterns
  ([\#13](https://github.com/ddotta/rsonar/issues/13))
- [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md):
  fixed a bug in `assignment` where the right-hand side of `y = 2` was
  lost during `=` → `<-` conversion
  ([\#13](https://github.com/ddotta/rsonar/issues/13))
- [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md):
  `n_cores` now defaults to `1` on Windows, where
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  does not support forked parallelism, and the parallel branch
  gracefully falls back to a single worker instead of erroring
  ([\#13](https://github.com/ddotta/rsonar/issues/13))
- [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md):
  the default `n_cores` is now capped at `4` on Unix-like systems,
  avoiding excessive forking inside CI containers
  ([\#13](https://github.com/ddotta/rsonar/issues/13))
- [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md):
  style checking now uses a hard per-file timeout that reliably
  interrupts `styler` even when it blocks in native code, preventing CI
  pipelines from hanging indefinitely on malformed files
  ([\#13](https://github.com/ddotta/rsonar/issues/13))
- [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md):
  styler formatting now runs per file behind a hard timeout
  (`style_timeout`, default 30s), so a single malformed file is skipped
  instead of stalling the whole pipeline
  ([\#13](https://github.com/ddotta/rsonar/issues/13))
- [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md):
  the `air` formatter now works, by defining the previously missing
  `.find_air()` helper that locates the `air` binary
  ([\#13](https://github.com/ddotta/rsonar/issues/13))
- [`sonar_autofix()`](https://ddotta.github.io/rsonar/reference/sonar_autofix.md):
  `git push` / `git checkout` / `git add` failures are now detected and
  reported instead of silently claiming the Merge Request was created
  (e.g. when the CI token lacks the `write_repository` scope)
  ([\#13](https://github.com/ddotta/rsonar/issues/13))

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

#### Improvements

- Added
  [`quality_score()`](https://ddotta.github.io/rsonar/reference/quality_score.md)
  for fast local IDE feedback as a quality percentage
- Improved analysis robustness in CI:
  - style checks no longer require `roxygen2` for roxygen examples
  - coverage checks reuse installed dependencies (`clean = FALSE`)

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
