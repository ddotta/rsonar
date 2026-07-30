# Auto-Fix with sonar_fix()

## Overview

[`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md)
is the complement to
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md).
While
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md)
inspects your code and reports issues,
[`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md)
**automatically corrects** many of them — similar to SonarQube AutoFix,
OpenRewrite recipes, or IDE quick-fixes.

⚠️ **Unlike
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md)
which is read-only,
[`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md)
modifies files.** Always preview with `dry_run = TRUE` (the default)
first.

## Quick start

``` r

library(rsonar)

# Preview what would be changed (no files modified)
fix <- sonar_fix(".", dry_run = TRUE)
print(fix)

# Apply all fixes
fix <- sonar_fix(".", dry_run = FALSE)
```

## Fix categories

[`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md)
groups corrections into 18 categories. Use the `fixes` parameter to
select which ones to apply.

### Formatting (`"styler"` or `"air"`)

Uses
[`styler::style_dir()`](https://styler.r-lib.org/reference/style_dir.html)
or Posit’s `air` formatter to apply the tidyverse style guide:

``` r

# Use styler (default)
fix <- sonar_fix(".", fixes = "styler")

# Use air (faster, needs to be installed first)
install_air()
fix <- sonar_fix(".", fixes = "styler", formatter = "air")
```

Corrections include: indentation, spacing, parentheses alignment, line
breaks, pipe formatting, braces, blank lines.

### Spacing (`"spacing"`)

Fixes missing spaces around operators and assignments:

``` r

x<-1               # Before: no spaces
x <- 1             # After:  proper spacing

y = 2              # Before: space only before =
y <- 2             # After:  <- with spaces
```

### TRUE/FALSE (`"true_false"`)

Replaces `T`/`F` with `TRUE`/`FALSE`:

``` r

if(T)              # Before
if(TRUE)           # After

x <- F             # Before
x <- FALSE         # After
```

### NULL (`"null"`)

Converts `x=NULL` to `x <- NULL` (outside function arguments):

``` r

x = NULL           # Before
x <- NULL          # After
```

### Commas (`"commas"`)

Adds a space after each comma:

``` r

c(1,2,3)           # Before
c(1, 2, 3)         # After
```

### Parentheses (`"parens"`)

Removes unnecessary nested parentheses:

``` r

return((x))        # Before
return(x)          # After
```

### Cleanup (`"cleanup"`)

Multiple cleanup operations:

``` r

# Remove double comment separator lines
##########          # (removed if duplicated)

# Remove trailing whitespace
"hello "            # trailing space removed

# Remove multiple consecutive blank lines
                    # line 1
                    # line 2 (removed, only one blank line)

# Ensure single trailing newline at EOF
```

### Simplify (`"simplify"`)

Simplifies boolean expressions:

``` r

if(x == TRUE)       # Before:  if(x == TRUE)
if(x)               # After:   if(x)

if(x == FALSE)      # Before
if(!x)              # After

length(x) == 0      # Before
!length(x)          # After

length(x) > 0       # Before
isTRUE(x) == TRUE   # Before
isTRUE(x)           # After
```

### Pipes (`"pipes"`)

Converts `%>%` (magrittr pipe) to `|>` (base R native pipe):

``` r

x %>% f()           # Before
x |> f()            # After
```

### Return (`"return"`)

Fixes multi-line [`return()`](https://rdrr.io/r/base/function.html)
calls:

``` r

return(             # Before: multi-line
  x
)
return(x)           # After: one line
```

### Assignment (`"assignment"`)

Converts `=` to `<-` for assignment (outside function calls):

``` r

x = 5               # Before
x <- 5              # After
```

### Comments (`"comments"`)

Standardizes long comment separators:

``` r

##########          # Before
#----------         # After
```

### Unused Variables (`"unused_vars"`)

Detects and removes variable assignments that are never read within the
same file:

``` r

unused_value <- 42  # Before: variable never used elsewhere
                     # After:  line removed
```

Uses conservative heuristics to avoid false positives: - Skips variables
shorter than 3 characters - Skips common names (`i`, `j`, `tmp`, etc.) -
Skips assignments from function calls (may have side effects) - Skips
`<<-` super-assignments (visible elsewhere)

⚠️ **Enabled in `fixes = "all"`** — use with `dry_run = TRUE` first to
review what would be removed.

### Duplicate Libraries (`"duplicate_libs"`)

Detects and removes duplicate
[`library()`](https://rdrr.io/r/base/library.html) calls loading the
same package multiple times:

``` r

library(ggplot2)    # Before: first call (kept)
library(ggplot2)    # Before: duplicate (removed)
library(arrow)      # Before: different package (kept)

library(ggplot2)    # After:  only one call remains
library(arrow)
```

### Report-only categories

These categories detect issues but do **not** modify files:

- **`"library"`** — Detects
  [`library(x)`](https://rdrr.io/r/base/library.html) calls that may be
  unused (also counts duplicates)
- **`"namespace"`** — Suggests converting `library(x) + f()` to `x::f()`
- **`"dead_code"`** — Detects expressions without effect (e.g. `1+1`
  standalone)

## Selecting specific fixes

``` r

# Only formatting + spacing
fix <- sonar_fix(".", fixes = c("styler", "spacing"))

# Only TRUE/FALSE + NULL + assignment
fix <- sonar_fix(".", fixes = c("true_false", "null", "assignment"))
```

## Safety features

### Dry-run mode (default)

`dry_run = TRUE` previews changes without modifying anything. The result
shows which files would change and how many fixes of each type:

``` r

fix <- sonar_fix(".", dry_run = TRUE)
print(fix)
```

### Backup

Use `backup = TRUE` to create `.bak` copies before modifying:

``` r

fix <- sonar_fix(".", backup = TRUE, dry_run = FALSE)
```

### Parallel processing

Files are processed in parallel by default, using all available cores:

``` r

# Custom number of cores
fix <- sonar_fix(".", parallel = TRUE, n_cores = 4)
```

## JSON report

A JSON report is generated by default:

``` r

sonar_fix(".", dry_run = TRUE, report = TRUE, report_file = "sonar-fixes.json")
```

Example output:

``` json
{
  "files": {
    "scanned": 42,
    "modified": 18
  },
  "fixes": {
    "styler": 205,
    "spacing": 81,
    "true_false": 9,
    "pipes": 5,
    "duplicate_libs": 1,
    "unused_vars": 3
  }
}
```

## Integration with CI/CD

### GitLab CI: auto-fix + Merge Request

In your `.gitlab-ci.yml`, after running
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md),
trigger
[`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md)
to auto-correct issues and open a Merge Request:

``` yaml
rsonar-fix:
  stage: fix
  when: manual
  script:
    - |
      R -q -e "
      library(rsonar)
      fix <- sonar_fix('.', dry_run = FALSE)
      
      # If there are changes, create a branch and merge request
      if (fix$files_modified > 0) {
        system2('git', c('checkout', '-b', 'auto/style'))
        system2('git', c('add', '.'))
        system2('git', c('commit', '-m', 'style: auto-fix R code'))
        system2('git', c('push', '-o', 'merge_request.create',
                         'origin', 'auto/style'))
      }
      "
```

### GitHub Actions: auto-fix + Pull Request

Using the `rsonar/fix` action:

``` yaml
- uses: rsonar/fix@v1
```

## Corrections NOT applied

The following are never auto-fixed and remain in
[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md)
for developer review:

- Business logic changes
- Renaming
- Function removal
- API changes
- Type changes
- Algorithm simplification
- Cyclomatic complexity

## Comparison: `sonar_analyse()` vs `sonar_fix()`

| Aspect | [`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md) | [`sonar_fix()`](https://ddotta.github.io/rsonar/reference/sonar_fix.md) |
|----|----|----|
| Read-only | ✅ Yes | ❌ Modifies files |
| Reported issues | All | Only safe auto-fixes |
| Default mode | Analysis | Dry-run preview |
| Pre-commit usage | Check quality | Auto-format code |
| CI usage | Gate + Reports | Auto-correct + MR/PR |
| Categories | ~20 rule types | 18 fix families |

## See also

- [Introduction to
  rsonar](https://ddotta.github.io/rsonar/articles/introduction.md) for
  a general overview
- [CI/CD
  Integration](https://ddotta.github.io/rsonar/articles/ci-integration.md)
  for pipeline configuration
- [Technical
  Debt](https://ddotta.github.io/rsonar/articles/technical-debt.md) for
  debt estimation
