# Copy a CI Pipeline Template into a Project

Copies a pre-configured pipeline template for rsonar.

## Usage

``` r
use_rsonar_ci(type = c("gitlab", "github"), path = ".", overwrite = FALSE)
```

## Arguments

- type:

  CI type: `"gitlab"` or `"github"`. Default `"gitlab"`.

- path:

  Project root directory. Default `.`.

- overwrite:

  Overwrite if the file already exists. Default `FALSE`.

## Value

The path to the created file (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
use_rsonar_ci("gitlab")
use_rsonar_ci("github")
} # }
```
