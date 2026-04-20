# Export Results in SonarQube Generic Issue Import Format

Generates a JSON file compatible with the [Generic Issue
Import](https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/importing-external-issues/generic-issue-import-format/)
format of SonarQube. Allows injecting lintr results into an existing
SonarQube/SonarCloud instance via the `sonar.externalIssuesReportPaths`
property.

## Usage

``` r
export_sonar_json(x, output = "sonar-issues.json")
```

## Arguments

- x:

  An `rsonar_result` object returned by
  [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md).

- output:

  Path to the output JSON file. Default `"sonar-issues.json"`.

## Value

The path to the generated JSON file (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
res <- sonar_analyse(".")
export_sonar_json(res, "sonar-issues.json")
} # }
```
