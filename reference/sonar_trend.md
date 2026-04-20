# Record Analysis History for Trend Tracking

Appends the current analysis results to a JSON history file, enabling
debt trend tracking over time. Each entry records the timestamp, commit
SHA (from CI environment variables), key metrics and SQALE rating. This
is analogous to SonarQube's project history.

## Usage

``` r
sonar_trend(x, file = "rsonar-history.json")
```

## Arguments

- x:

  An `rsonar_result` object returned by
  [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md).

- file:

  Path to the JSON history file. Default `"rsonar-history.json"`.
  Created automatically if it does not exist.

## Value

The new history entry (invisibly), a list with `timestamp`, `commit`,
`metrics` and `debt` fields.

## Examples

``` r
if (FALSE) { # \dontrun{
res <- sonar_analyse(".")
sonar_trend(res)
sonar_trend(res, file = "quality-history.json")
} # }
```
