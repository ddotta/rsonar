# Export Results in SARIF Format

Generates a [SARIF](https://sarifweb.azurewebsites.net/) (Static
Analysis Results Interchange Format) file. SARIF is supported by GitHub
Code Scanning, VS Code, Azure DevOps and many other tools.

## Usage

``` r
export_sarif(x, output = "rsonar.sarif")
```

## Arguments

- x:

  An `rsonar_result` object returned by
  [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md).

- output:

  Path to the output SARIF file. Default `"rsonar.sarif"`.

## Value

The path to the generated SARIF file (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
res <- sonar_analyse(".")
export_sarif(res, "results.sarif")
} # }
```
