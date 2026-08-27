# Auto-Fix R Code Quality Issues

Automatically fixes common R code quality issues across multiple
categories: formatting, trivial transformations, cleanup,
simplifications, pipes, namespace usage, dead code detection, and more.

## Usage

``` r
sonar_fix(
  path = ".",
  include = "\\.[Rr]$",
  exclude = c("renv", ".git", ".Rproj.user", "packrat", "vendor", "node_modules"),
  fixes = "all",
  formatter = c("styler", "air"),
  dry_run = TRUE,
  backup = FALSE,
  parallel = TRUE,
  n_cores = if (.Platform$OS.type == "windows") 1L else parallel::detectCores(),
  report = TRUE,
  report_file = "sonar-fixes.json",
  verbose = interactive()
)
```

## Arguments

- path:

  Path to the R project or directory. Default `"."`.

- include:

  Glob pattern for files to include. Default `"\\\\.\[Rr\]$"`.

- exclude:

  Character vector of directories or patterns to exclude. Default
  `c("renv", ".git", ".Rproj.user", "packrat", "vendor", "node_modules")`.

- fixes:

  Character vector of fix categories to apply, or `"all"` for all
  categories. Available categories are: `"styler"`, `"spacing"`,
  `"true_false"`, `"null"`, `"commas"`, `"parens"`, `"cleanup"`,
  `"simplify"`, `"pipes"`, `"magrittr"`, `"namespace"`, `"library"`,
  `"dead_code"`, `"return"`, `"assignment"`, `"comments"`,
  `"unused_vars"`, `"duplicate_libs"`. See details. Default `"all"`.

- formatter:

  Character vector of formatters to use for code style. Options are
  `"styler"` (default, uses tidyverse style) or `"air"` (Posit's fast
  formatter). Default `c("styler")`.

- dry_run:

  Logical. If `TRUE`, only check what would be changed without modifying
  files. Default `TRUE`.

- backup:

  Logical. If `TRUE`, create `.bak` copies of files before modifying
  them. Default `FALSE`.

- parallel:

  Logical. Use parallel processing for multiple files. Default `TRUE`.

- n_cores:

  Number of cores for parallel processing. Defaults to
  [`parallel::detectCores()`](https://rdrr.io/r/parallel/detectCores.html)
  on Unix-like systems and `1` on Windows, where
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  does not support forked parallelism.

- report:

  Logical. Generate a JSON report file. Default `TRUE`.

- report_file:

  Path to the JSON report. Default `"sonar-fixes.json"`.

- verbose:

  Logical. Show progress and result summary. Default
  [`interactive()`](https://rdrr.io/r/base/interactive.html).

## Value

An object of class `sonar_fix` containing:

- `files_scanned`:

  Total number of R files examined

- `files_modified`:

  Number of files that were actually modified

- `fixes_applied`:

  Named list with counts of each fix type applied

- `fixes_skipped`:

  Named list of fix types that were skipped

- `elapsed`:

  Duration of the fix run

- `report`:

  Console-friendly summary text

- `path`:

  Analyzed project path

- `timestamp`:

  Execution date/time

## Details

Unlike
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md)
which is read-only, `sonar_fix()` **modifies files** in the project.
Always run with `dry_run = TRUE` first (default) to preview changes
before applying them.

## Fix categories

**Formatting** (`"styler"` or `"air"`): Indentation, spacing,
parentheses, alignment, line breaks, pipe formatting, braces, blank
lines. Equivalent to
[`styler::style_dir()`](https://styler.r-lib.org/reference/style_dir.html)
or `air format`.

**Spacing** (`"spacing"`): Fix missing spaces around operators, commas,
and assignments. Example: `x<-1` → `x <- 1`.

**TRUE/FALSE** (`"true_false"`): Replace `T`/`F` with `TRUE`/`FALSE`.

**NULL** (`"null"`): Replace `x=NULL` with `x <- NULL`.

**Commas** (`"commas"`): Add spaces after commas. Example: `c(1,2,3)` →
`c(1, 2, 3)`.

**Parentheses** (`"parens"`): Remove unnecessary parentheses. Example:
`return((x))` → `return(x)`.

**Cleanup** (`"cleanup"`): Remove double comment lines (`#####`), empty
comment blocks, multiple blank lines, trailing whitespace, ensure single
trailing newline.

**Simplify** (`"simplify"`): Simplify boolean expressions. Example:
`if(x==TRUE)` → `if(x)`, `length(x)==0` → `!length(x)`.

**Pipes** (`"pipes"`): Convert `%>%` to `|>` (native pipe). Example:
`x %>% f()` → `x |> f()`.

**Magrittr** (`"magrittr"`): Convert assignment pipes `%<>%` to
equivalent base R.

**Namespace** (`"namespace"`): Convert
[`library(x)`](https://rdrr.io/r/base/library.html) + `f()` to `x::f()`.

**Library** (`"library"`): Detect unused
[`library()`](https://rdrr.io/r/base/library.html) calls (report only,
not applied automatically).

**Dead code** (`"dead_code"`): Remove expressions without effect (e.g.
`1+1` standalone). Default: report only.

**Return** (`"return"`): Fix formatting of
[`return()`](https://rdrr.io/r/base/function.html) calls. Example:
`return(x)` without unnecessary line breaks.

**Assignment** (`"assignment"`): Convert `=` to `<-` outside of function
calls.

**Comments** (`"comments"`): Standardize long comment separators.
Example: `##########` → `#----------`.

**Unused Variables** (`"unused_vars"`): Detect and remove variable
assignments that are never read within the same file. Example: `x <- 1`
followed by no usage of `x` → line removed.

**Duplicate Libraries** (`"duplicate_libs"`): Detect and remove
duplicate [`library()`](https://rdrr.io/r/base/library.html) calls
loading the same package multiple times. Example:
[`library(ggplot2)`](https://ggplot2.tidyverse.org) x2 → second line
removed.

## Corrections NOT applied automatically

The following are never auto-fixed (remain in
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md)):
business logic changes, renaming, function removal, API changes, type
changes, algorithm simplification, cyclomatic complexity.

## See also

[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md)
for read-only analysis,
[`install_air()`](https://ddotta.github.io/rsonar/reference/install_air.md)
to install the air formatter.

## Examples

``` r
if (FALSE) { # \dontrun{
# Preview changes (no files modified)
fix <- sonar_fix(".", dry_run = TRUE)
print(fix)

# Apply all fixes
fix <- sonar_fix(".", dry_run = FALSE)

# Apply only formatting and spacing fixes
fix <- sonar_fix(".", fixes = c("spacing", "styler"))

# Use air formatter instead of styler
fix <- sonar_fix(".", formatter = "air")

# Backup files before modifying
fix <- sonar_fix(".", backup = TRUE, dry_run = FALSE)
} # }
```
