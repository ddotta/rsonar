# Quick Quality Score for IDE Usage

Computes a quick quality percentage score for a project, designed for
fast feedback directly in the IDE without any CI platform.

## Usage

``` r
quality_score(
  x = ".",
  include_coverage = FALSE,
  include_goodpractice = FALSE,
  verbose = TRUE
)
```

## Arguments

- x:

  A path to analyze (character) or an `rsonar_result` object. Default
  `"."`.

- include_coverage:

  Logical. Include coverage in quick analysis when `x` is a path.
  Default `FALSE` for speed.

- include_goodpractice:

  Logical. Include goodpractice checks in quick analysis when `x` is a
  path. Default `FALSE` for speed.

- verbose:

  Logical. Show progress and summary in console. Default `TRUE`.

## Value

An object of class `rsonar_score` with fields: `score` (0-100), `rating`
(A-E), `ratio`, `path`, `timestamp`.

## Details

You can pass either:

- a path to an R project/package, or

- an existing `rsonar_result` object.

The score is derived from the technical debt ratio:
`score = 100 * (1 - min(1, debt_ratio))`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Fast local check directly in IDE
quality_score(".")

# Reuse an existing analysis
res <- sonar_analyse(".")
quality_score(res)
} # }
```
