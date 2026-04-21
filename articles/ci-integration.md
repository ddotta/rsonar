# Complete CI/CD Integration

## General Strategy

`rsonar` integrates into your CI pipelines following the same model as
SonarQube:

    Code push → Lint → Style → Tests + Coverage → Quality Gate → Report

If the **Quality Gate** fails, the pipeline is blocked (exit code 1) and
the merge is rejected.

------------------------------------------------------------------------

## GitLab CI

### Minimal configuration (single job)

The simplest configuration: a single job that analyzes everything and
fails if the gate does not pass.

``` yaml
# .gitlab-ci.yml
include:
  # Use the template provided by rsonar
  - project: 'ddotta/rsonar'
    ref: main
    file: '/inst/templates/ci/gitlab-rsonar.yml'
```

Or copy the template into your project:

``` r
library(rsonar)
use_rsonar_ci("gitlab")
```

### Full configuration with separate stages

``` yaml
# .gitlab-ci.yml
image: rocker/r-base:4.5.1

stages:
  - lint
  - style
  - coverage
  - quality_gate
  - report

variables:
  # Customize thresholds here
  COVERAGE_MIN: "80"
  LINT_ERRORS_MAX: "0"

before_script:
  - |
    R -q -e "
    pkgs <- c('remotes','lintr','styler','covr','goodpractice',
              'cli','jsonlite','xml2','glue','fs','rlang','withr','testthat')
    miss <- pkgs[!(pkgs %in% rownames(installed.packages()))]
    if (length(miss) > 0) install.packages(miss, repos='https://cloud.r-project.org')
    remotes::install_local('.', dependencies=FALSE, quiet=TRUE)
    "

rsonar-lint:
  stage: lint
  script:
    - |
      Rscript -e "
      library(rsonar)
      res <- sonar_analyse('.', include_coverage=FALSE, include_goodpractice=FALSE)
      export_junit(res, 'junit-lint.xml')
      export_sonar_json(res, 'sonar-issues.json')
      if (res\$metrics\$n_lint_errors > 0) stop('Lint errors detected')
      "
  artifacts:
    when: always
    reports:
      junit: junit-lint.xml
    paths:
      - sonar-issues.json

rsonar-style:
  stage: style
  script:
    - |
      Rscript -e "
      library(rsonar)
      res <- sonar_analyse('.', include_lint=FALSE,
                               include_coverage=FALSE,
                               include_goodpractice=FALSE)
      if (res\$metrics\$n_style_issues > 0)
        stop(res\$metrics\$n_style_issues, ' file(s) not formatted')
      "

rsonar-coverage:
  stage: coverage
  script:
    - |
      Rscript -e "
      library(rsonar)
      res <- sonar_analyse('.', include_lint=FALSE, include_style=FALSE,
                               include_goodpractice=FALSE)
      pct <- res\$metrics\$coverage_pct
      cat('Coverage:', pct, '%\n')
      if (!is.na(pct)) covr::to_cobertura(res\$coverage, 'coverage.xml')
      "
  coverage: '/Coverage: ([0-9.]+) %/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

rsonar-gate:
  stage: quality_gate
  script:
    - |
      Rscript -e "
      library(rsonar)
      res <- sonar_analyse('.')
      quality_gate(res,
        coverage_min     = as.numeric(Sys.getenv('COVERAGE_MIN', '80')),
        lint_errors_max  = as.integer(Sys.getenv('LINT_ERRORS_MAX', '0')),
        style_issues_max = 0,
        rating_min       = 'C',
        fail_on_error    = TRUE)
      "

rsonar-report:
  stage: report
  when: always
  script:
    - |
      Rscript -e "
      library(rsonar)
      res <- sonar_analyse('.')
      sonar_report(res, output='rsonar-report.html', open=FALSE)
      sonar_trend(res)
      "
  artifacts:
    paths:
      - rsonar-report.html
      - rsonar-history.json
    expire_in: 4 weeks
```

### Integration with an existing SonarQube instance

If your SonarQube instance already handles Java/Python, you can send R
results to it:

``` yaml
sonar-scan:
  stage: quality_gate
  image: sonarsource/sonar-scanner-cli:latest
  script:
    - sonar-scanner
      -Dsonar.projectKey=my-r-project
      -Dsonar.sources=R/
      -Dsonar.externalIssuesReportPaths=sonar-issues.json
      -Dsonar.host.url=$SONAR_HOST_URL
      -Dsonar.login=$SONAR_TOKEN
  needs: [rsonar-lint]
```

------------------------------------------------------------------------

## GitHub Actions

``` r
# Copy the workflow to .github/workflows/rsonar.yml
use_rsonar_ci("github")
```

### Complete workflow

``` yaml
# .github/workflows/rsonar.yml
name: rsonar — R Code Quality

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  rsonar:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: "release"

      - name: Install rsonar and dependencies
        run: |
          Rscript -e "
          remotes::install_github('ddotta/rsonar')
          "

      - name: Full analysis
        run: |
          Rscript -e "
          library(rsonar)
          res <- sonar_analyse('.')
          
          # HTML report (always)
          sonar_report(res, output='rsonar-report.html', open=FALSE)
          export_junit(res, 'junit-results.xml')
          export_sarif(res, 'rsonar.sarif')
          
          # Quality Gate (blocks on failure)
          quality_gate(res,
            coverage_min    = 80,
            lint_errors_max = 0,
            fail_on_error   = TRUE)
          "

      - name: Upload SARIF to GitHub Code Scanning
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: rsonar.sarif

      - name: Publish JUnit results
        if: always()
        uses: mikepenz/action-junit-report@v5
        with:
          report_paths: junit-results.xml

      - name: Upload HTML report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: rsonar-report
          path: rsonar-report.html
```

------------------------------------------------------------------------

## Jenkins

``` groovy
// Jenkinsfile
pipeline {
    agent {
        docker {
            image 'rocker/r-base:4.5.1'
        }
    }
    stages {
        stage('Install rsonar') {
            steps {
                sh '''
                Rscript -e "remotes::install_github('ddotta/rsonar')"
                '''
            }
        }
        stage('Quality analysis') {
            steps {
                sh '''
                Rscript -e "
                library(rsonar)
                res <- sonar_analyse('.')
                sonar_report(res, output='rsonar-report.html', open=FALSE)
                export_junit(res, 'junit-results.xml')
                quality_gate(res, coverage_min=80, lint_errors_max=0, fail_on_error=TRUE)
                "
                '''
            }
            post {
                always {
                    junit 'junit-results.xml'
                    publishHTML([
                        reportDir:   '.',
                        reportFiles: 'rsonar-report.html',
                        reportName:  'rsonar Quality Report'
                    ])
                }
            }
        }
    }
}
```

------------------------------------------------------------------------

## Makefile (local execution)

To make it easy to run locally before pushing:

If you only want a quick local indicator in your IDE, run:

``` r
library(rsonar)
quality_score(".")
```

``` makefile
# Makefile
.PHONY: quality lint style coverage report

quality:
    Rscript -e "library(rsonar); res <- sonar_analyse('.'); print(res)"

lint:
    Rscript -e "library(rsonar); res <- sonar_analyse('.', include_style=FALSE, include_coverage=FALSE, include_goodpractice=FALSE); print(res$$lint)"

style:
    Rscript -e "styler::style_dir('R')"

coverage:
    Rscript -e "library(rsonar); res <- sonar_analyse('.', include_lint=FALSE, include_style=FALSE); cat('Coverage:', res$$metrics$$coverage_pct, '%\n')"

report:
    Rscript -e "library(rsonar); res <- sonar_analyse('.'); sonar_report(res)"
```

------------------------------------------------------------------------

## Useful CI Environment Variables

| Variable          | Purpose             | Example                     |
|-------------------|---------------------|-----------------------------|
| `COVERAGE_MIN`    | Coverage threshold  | `80`                        |
| `LINT_ERRORS_MAX` | Maximum lint errors | `0`                         |
| `SONAR_HOST_URL`  | SonarQube URL       | `https://sonar.example.com` |
| `SONAR_TOKEN`     | SonarQube token     | `sqp_xxx`                   |
| `R_QUALITY_IMAGE` | Docker R image      | `rocker/r-base:4.5.1`       |

------------------------------------------------------------------------

## Tips for Existing Projects

If your project already has many issues, don’t block on everything
immediately:

``` r
# Phase 1: observe without blocking
quality_gate(res, lint_errors_max = Inf, style_issues_max = Inf,
             coverage_min = 0, fail_on_error = FALSE)

# Phase 2: block on new critical errors only
quality_gate(res, lint_errors_max = 5, style_issues_max = Inf,
             coverage_min = 0)

# Phase 3: strict gate
quality_gate(res, lint_errors_max = 0, style_issues_max = 0,
             coverage_min = 80, fail_on_error = TRUE)
```
