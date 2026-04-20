# Export Results in JUnit XML Format

Generates a JUnit XML report consumable by GitLab CI, Jenkins, GitHub
Actions and SonarQube. Each lintr issue becomes a `<failure>` within a
`<testcase>`.

## Usage

``` r
export_junit(x, output = "rsonar-junit.xml")
```

## Arguments

- x:

  An `rsonar_result` object returned by
  [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md).

- output:

  Path to the output XML file. Default `"rsonar-junit.xml"`.

## Value

The path to the generated XML file (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
res <- sonar_analyse(".")
export_junit(res, "junit-results.xml")
} # }
```
