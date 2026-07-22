# Locate the air binary

Searches for `air` on the system PATH. If not found, tries common
installation locations. If still not found, raises an informative error
suggesting to call
[`install_air()`](https://ddotta.github.io/rsonar/reference/install_air.md).

## Usage

``` r
.find_air()
```

## Value

Path to the air binary.
