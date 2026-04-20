# Copy a Reference .lintr File into a Project

Copies the default `.lintr` configuration file recommended by `rsonar`
into the target directory. This file enables linters equivalent to the
most common SonarQube rules for R.

## Usage

``` r
use_rsonar_lintr(path = ".", overwrite = FALSE)
```

## Arguments

- path:

  Target directory. Default: current directory.

- overwrite:

  Overwrite if a `.lintr` file already exists. Default `FALSE`.

## Value

The path to the created `.lintr` file (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
use_rsonar_lintr()
} # }
```
