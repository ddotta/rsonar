# rsonar (development version)

### New features

* `sonar_hotspots()`: ranks files by estimated technical debt so developers
  know which ones to fix first, similar to SonarQube's "Code Smells" /
  hotspots view. Previously `debt_index()` only reported a single
  project-wide score with no per-file breakdown (#12)
* `sonar_report()`: the HTML report now includes a "Hotspots - Files to
  Fix First" section (top 10 files by debt), placed right after the
  Technical Debt summary (#12)
* `sonar_fix()`: new `unused_vars` category detects and removes variable
  assignments that are never read within the same file, using conservative
  heuristics to avoid false positives (#13)
* `sonar_fix()`: new `duplicate_libs` category detects and removes duplicate
  `library()` calls loading the same package multiple times (#13)

### Improvements

* `sonar_fix()`: the `simplify` category now handles compound boolean
  expressions (`x == TRUE && y` → `x && y`, `x == FALSE \|\| y` → `!x \|\| y`)
  in addition to simple patterns (#13)
* `sonar_fix()`: fixed a bug in `assignment` where the right-hand side of
  `y = 2` was lost during `=` → `<-` conversion (#13)

# rsonar 0.2.0 (2026-04-20)

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

### Improvements

* Added `quality_score()` for fast local IDE feedback as a quality percentage
* Improved analysis robustness in CI:
  - style checks no longer require `roxygen2` for roxygen examples
  - coverage checks reuse installed dependencies (`clean = FALSE`)

# rsonar 0.1.0 (2026-04-20)

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
