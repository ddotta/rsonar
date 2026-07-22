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

  Specific version to install (e.g., `"v0.1.0"`). If `"latest"`
  (default), the latest stable release is installed.

- force:

  Logical. If `TRUE`, reinstall even if `air` is already present.
  Default `FALSE`.

## Value

The path to the installed `air` binary (invisibly).

## Details

On Linux and macOS, the binary is installed to `~/.local/bin/air`. On
Windows, it is installed to `~/bin/air.exe`.

## See also

[`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md)
to use air for auto-fixing R code.

## Examples

``` r
if (FALSE) { # \dontrun{
# Install the latest version
install_air()

# Install a specific version
install_air(version = "v0.1.0")

# Reinstall even if already present
install_air(force = TRUE)
} # }
```
