# Install air R Code Formatter

Downloads and installs the `air` R code formatter binary from the
official GitHub releases. Supports Linux (x86_64, aarch64), macOS (Intel
and Apple Silicon), and Windows.

## Usage

``` r
install_air(version = "latest", force = FALSE)
```

## Arguments

- version:

  Specific version or `"latest"`. Default `"latest"`.

- force:

  Logical. Reinstall even if already present. Default `FALSE`.

## Value

The path to the installed binary (invisibly).

## See also

[`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md)
