# Auto-Fix Code Quality Issues with air

Runs `air` (Posit's R code formatter) on R files to automatically fix
code style and lint issues. Optionally creates a git branch and pushes
changes for review via Merge Request (GitLab) or Pull Request (GitHub).

## Usage

``` r
sonar_fix(
  path = ".",
  files = NULL,
  create_mr = FALSE,
  branch_name = NULL,
  commit_message = "style: auto-format code with air via rsonar",
  mr_title = "Auto-fix: code style improvements via rsonar",
  dry_run = FALSE,
  verbose = TRUE
)
```

## Arguments

- path:

  Path to the R project or directory. Default current directory.

- files:

  Character vector of specific R files to fix. If `NULL` (default), all
  R files in `path` are processed.

- create_mr:

  Logical. If `TRUE`, attempts to create a git branch, commit changes,
  push, and open a Merge Request (GitLab CI) or Pull Request (GitHub
  Actions). Requires `git` and appropriate CI environment variables.
  Default `FALSE`.

- branch_name:

  Name of the branch to create. If `NULL`, an automatic name
  `"rsonar/auto-fix-{timestamp}"` is generated. Default `NULL`.

- commit_message:

  Commit message. Default
  `"style: auto-format code with air via rsonar"`.

- mr_title:

  Title of the MR / PR. Default
  `"Auto-fix: code style improvements via rsonar"`.

- dry_run:

  Logical. If `TRUE`, only check what would be changed without modifying
  files (uses `air format --check`). Default `FALSE`.

- verbose:

  Logical. Show progress and result summary. Default `TRUE`.

## Value

An object of class `rsonar_fix` containing:

- `files_changed`:

  Character vector of modified file paths

- `diff_summary`:

  Summary string from air output

- `branch`:

  Name of the created branch (if `create_mr = TRUE`)

- `mr_url`:

  URL of the created MR/PR (if applicable)

- `dry_run`:

  Whether dry-run mode was used

- `path`:

  Analyzed project path

- `timestamp`:

  Execution timestamp

## Details

`air` is a fast, opinionated R code formatter developed by Posit. It
reformats R code according to modern style conventions. See
<https://github.com/posit-dev/air> for installation instructions.

## See also

[`sonar_analyse()`](https://ddotta.github.io/rsonar/reference/sonar_analyse.md)
for code quality analysis,
[`install_air()`](https://ddotta.github.io/rsonar/reference/install_air.md)
to install the air formatter.

## Examples

``` r
if (FALSE) { # \dontrun{
# Check what would be changed (no file modification)
fix <- sonar_fix(".", dry_run = TRUE)
print(fix)

# Auto-fix all R files in the current project
fix <- sonar_fix(".")

# Fix specific files only
fix <- sonar_fix(".", files = c("R/analyse.R", "R/export.R"))

# Auto-fix and create a Merge Request (in GitLab CI)
fix <- sonar_fix(".", create_mr = TRUE)
} # }
```
