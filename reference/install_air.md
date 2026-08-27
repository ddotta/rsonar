# Install air R Code Formatter

Downloads and runs the official air installer from the latest GitHub
release. Uses the PowerShell installer on Windows and the shell
installer on other platforms.

## Usage

``` r
install_air(force = FALSE)
```

## Arguments

- force:

  Logical. Reinstall even if air is already available on the system
  PATH. Default FALSE.

## Value

The path to the installed air binary, invisibly.

## See also

[`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md)
