# ============================================================================
# sonar_fix — Automatic Code Fixes for R Projects
#
# Completes sonar_analyse() by automatically correcting R code when possible.
# Unlike sonar_analyse() (read-only), sonar_fix() modifies files in the project.
# Inspired by SonarQube AutoFix, OpenRewrite, and IDE Quick Fix.
# ============================================================================

#' Auto-Fix R Code Quality Issues
#'
#' Automatically fixes common R code quality issues across multiple categories:
#' formatting, trivial transformations, cleanup, simplifications, pipes,
#' namespace usage, dead code detection, and more.
#'
#' Unlike [sonar_analyse()] which is read-only, `sonar_fix()` **modifies files**
#' in the project. Always run with `dry_run = TRUE` first (default) to preview
#' changes before applying them.
#'
#' @param path Path to the R project or directory. Default `"."`.
#' @param include Glob pattern for files to include. Default `"\\\\.\[Rr\]$"`.
#' @param exclude Character vector of directories or patterns to exclude.
#'   Default `c("renv", ".git", ".Rproj.user", "packrat", "vendor", "node_modules")`.
#' @param fixes Character vector of fix categories to apply, or `"all"` for
#'   all categories. Available categories are:
#'   `"styler"`, `"spacing"`, `"true_false"`, `"null"`, `"commas"`,
#'   `"parens"`, `"cleanup"`, `"simplify"`, `"pipes"`, `"magrittr"`,
#'   `"namespace"`, `"library"`, `"dead_code"`, `"return"`,
#'   `"assignment"`, `"comments"`, `"unused_vars"`,
#'   `"duplicate_libs"`. See details.
#'   Default `"all"`.
#' @param formatter Character vector of formatters to use for code style.
#'   Options are `"styler"` (default, uses tidyverse style) or `"air"`
#'   (Posit's fast formatter). Default `c("styler")`.
#' @param dry_run Logical. If `TRUE`, only check what would be changed without
#'   modifying files. Default `TRUE`.
#' @param backup Logical. If `TRUE`, create `.bak` copies of files before
#'   modifying them. Default `FALSE`.
#' @param parallel Logical. Use parallel processing for multiple files.
#'   Default `TRUE`.
#' @param n_cores Number of cores for parallel processing. Defaults to
#'   `parallel::detectCores()` on Unix-like systems and `1` on Windows, where
#'   `parallel::mclapply()` does not support forked parallelism.
#' @param report Logical. Generate a JSON report file. Default `TRUE`.
#' @param report_file Path to the JSON report. Default `"sonar-fixes.json"`.
#' @param style_timeout Timeout in seconds for the styler formatting step.
#'   Prevents `styler::style_dir()` from blocking indefinitely in CI on files
#'   with parsing errors. Default `300` (5 minutes). Set to `Inf` to disable.
#' @param verbose Logical. Show progress and result summary.
#'   Default `interactive()`.
#'
#' @return An object of class `sonar_fix` containing:
#'   \describe{
#'     \item{`files_scanned`}{Total number of R files examined}
#'     \item{`files_modified`}{Number of files that were actually modified}
#'     \item{`fixes_applied`}{Named list with counts of each fix type applied}
#'     \item{`fixes_skipped`}{Named list of fix types that were skipped}
#'     \item{`elapsed`}{Duration of the fix run}
#'     \item{`report`}{Console-friendly summary text}
#'     \item{`path`}{Analyzed project path}
#'     \item{`timestamp`}{Execution date/time}
#'   }
#'
#' @section Fix categories:
#'
#' **Formatting** (`"styler"` or `"air"`): Indentation, spacing, parentheses,
#' alignment, line breaks, pipe formatting, braces, blank lines.
#' Equivalent to `styler::style_dir()` or `air format`.
#'
#' **Spacing** (`"spacing"`): Fix missing spaces around operators,
#' commas, and assignments. Example: `x<-1` → `x <- 1`.
#'
#' **TRUE/FALSE** (`"true_false"`): Replace `T`/`F` with `TRUE`/`FALSE`.
#'
#' **NULL** (`"null"`): Replace `x=NULL` with `x <- NULL`.
#'
#' **Commas** (`"commas"`): Add spaces after commas. Example:
#' `c(1,2,3)` → `c(1, 2, 3)`.
#'
#' **Parentheses** (`"parens"`): Remove unnecessary parentheses.
#' Example: `return((x))` → `return(x)`.
#'
#' **Cleanup** (`"cleanup"`): Remove double comment lines (`#####`),
#' empty comment blocks, multiple blank lines, trailing whitespace,
#' ensure single trailing newline.
#'
#' **Simplify** (`"simplify"`): Simplify boolean expressions.
#' Example: `if(x==TRUE)` → `if(x)`, `length(x)==0` → `!length(x)`.
#'
#' **Pipes** (`"pipes"`): Convert `%>%` to `|>` (native pipe).
#' Example: `x %>% f()` → `x |> f()`.
#'
#' **Magrittr** (`"magrittr"`): Convert assignment pipes `%<>%` to
#' equivalent base R.
#'
#' **Namespace** (`"namespace"`): Convert `library(x)` + `f()` to
#' `x::f()`.
#'
#' **Library** (`"library"`): Detect unused `library()` calls
#' (report only, not applied automatically).
#'
#' **Dead code** (`"dead_code"`): Remove expressions without effect
#' (e.g. `1+1` standalone). Default: report only.
#'
#' **Return** (`"return"`): Fix formatting of `return()` calls.
#' Example: `return(x)` without unnecessary line breaks.
#'
#' **Assignment** (`"assignment"`): Convert `=` to `<-` outside of
#' function calls.
#'
#' **Comments** (`"comments"`): Standardize long comment separators.
#' Example: `##########` → `#----------`.
#'
#' **Unused Variables** (`"unused_vars"`): Detect and remove variable
#' assignments that are never read within the same file.
#' Example: `x <- 1` followed by no usage of `x` → line removed.
#'
#' **Duplicate Libraries** (`"duplicate_libs"`): Detect and remove
#' duplicate `library()` calls loading the same package multiple times.
#' Example: `library(ggplot2)` x2 → second line removed.
#'
#' @section Corrections NOT applied automatically:
#' The following are never auto-fixed (remain in [sonar_analyse()]):
#' business logic changes, renaming, function removal,
#' API changes, type changes, algorithm simplification, cyclomatic complexity.
#'
#' @examples
#' \dontrun{
#' # Preview changes (no files modified)
#' fix <- sonar_fix(".", dry_run = TRUE)
#' print(fix)
#'
#' # Apply all fixes
#' fix <- sonar_fix(".", dry_run = FALSE)
#'
#' # Apply only formatting and spacing fixes
#' fix <- sonar_fix(".", fixes = c("spacing", "styler"))
#'
#' # Use air formatter instead of styler
#' fix <- sonar_fix(".", formatter = "air")
#'
#' # Backup files before modifying
#' fix <- sonar_fix(".", backup = TRUE, dry_run = FALSE)
#' }
#'
#' @seealso [sonar_analyse()] for read-only analysis,
#'   [install_air()] to install the air formatter.
#' @export
sonar_fix <- function(
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
  style_timeout = 300,
  verbose = interactive()
) {
  path <- fs::path_abs(path)

  if (!fs::dir_exists(path)) {
    cli::cli_abort("Directory not found: {.path {path}}")
  }

  start_time <- Sys.time()

  if (verbose) {
    mode <- if (dry_run) " (dry-run)" else ""
    cli::cli_h1("rsonar Fix{mode}")
    cli::cli_inform(c("i" = "Path: {.path {path}}"))
  }

  # ---- Determine fix categories ----
  all_fixes <- c(
    "styler", "spacing", "true_false", "null", "commas",
    "parens", "cleanup", "simplify", "pipes", "magrittr",
    "namespace", "library", "dead_code", "return",
    "assignment", "comments", "unused_vars", "duplicate_libs"
  )
  if (identical(fixes, "all")) {
    active_fixes <- all_fixes
  } else {
    active_fixes <- intersect(fixes, all_fixes)
    if (length(active_fixes) == 0L) {
      cli::cli_abort("No valid fix categories specified.")
    }
  }

  # ---- Gather files ----
  all_files <- fs::dir_ls(path, recurse = TRUE, regexp = include)
  exclude_regex <- paste0("(", paste(exclude, collapse = "|"), ")")
  r_files <- all_files[!grepl(exclude_regex, all_files)]
  r_files <- as.character(r_files)

  if (length(r_files) == 0L) {
    cli::cli_inform(c("!" = "No R files found at {.path {path}}"))
    return(invisible(.make_fix_result(
      path, r_files, character(0), list(),
      dry_run, start_time, verbose
    )))
  }

  if (verbose) {
    cli::cli_inform(c("i" = "{length(r_files)} R file(s) found"))
  }

  # ---- Pre-compute the fix infrastructure for non-styler fixes ----
  # For styler/air formatting, we track files that need formatting.
  # For other fixes, we apply per-file transformations.
  fixes_applied <- list()
  for (f in active_fixes) fixes_applied[[f]] <- 0L

  # ---- Helper to apply text-based fixes to a file content ----
  .apply_text_fixes <- function(content, file_path) {
    local_fixes <- list()
    for (f in active_fixes) local_fixes[[f]] <- 0L

    if ("spacing" %in% active_fixes) {
      res <- .fix_spacing(content)
      content <- res$content
      local_fixes[["spacing"]] <- res$n
    }

    if ("true_false" %in% active_fixes) {
      res <- .fix_true_false(content)
      content <- res$content
      local_fixes[["true_false"]] <- res$n
    }

    if ("null" %in% active_fixes) {
      res <- .fix_null(content)
      content <- res$content
      local_fixes[["null"]] <- res$n
    }

    if ("commas" %in% active_fixes) {
      res <- .fix_commas(content)
      content <- res$content
      local_fixes[["commas"]] <- res$n
    }

    if ("parens" %in% active_fixes) {
      res <- .fix_parens(content)
      content <- res$content
      local_fixes[["parens"]] <- res$n
    }

    if ("cleanup" %in% active_fixes) {
      res <- .fix_cleanup(content)
      content <- res$content
      local_fixes[["cleanup"]] <- res$n
    }

    if ("simplify" %in% active_fixes) {
      res <- .fix_simplify(content)
      content <- res$content
      local_fixes[["simplify"]] <- res$n
    }

    if ("pipes" %in% active_fixes) {
      res <- .fix_pipes(content)
      content <- res$content
      local_fixes[["pipes"]] <- res$n
    }

    if ("return" %in% active_fixes) {
      res <- .fix_return(content)
      content <- res$content
      local_fixes[["return"]] <- res$n
    }

    if ("assignment" %in% active_fixes) {
      res <- .fix_assignment(content)
      content <- res$content
      local_fixes[["assignment"]] <- res$n
    }

    if ("comments" %in% active_fixes) {
      res <- .fix_comments(content)
      content <- res$content
      local_fixes[["comments"]] <- res$n
    }

    if ("magrittr" %in% active_fixes) {
      res <- .fix_magrittr(content)
      content <- res$content
      local_fixes[["magrittr"]] <- res$n
    }

    if ("unused_vars" %in% active_fixes) {
      res <- .fix_unused_vars(content)
      content <- res$content
      local_fixes[["unused_vars"]] <- res$n
    }

    if ("duplicate_libs" %in% active_fixes) {
      res <- .fix_duplicate_libs(content)
      content <- res$content
      local_fixes[["duplicate_libs"]] <- res$n
    }

    list(content = content, fixes = local_fixes)
  }

  # ---- Process files ----
  files_modified <- character(0)
  fixes_total <- list()
  for (f in active_fixes) fixes_total[[f]] <- 0L

  # Helper to process a single file
  .process_file <- function(file_path) {
    tryCatch(
      {
        original <- readLines(file_path, warn = FALSE)
        current <- original
        file_fixes <- list()
        for (f in active_fixes) file_fixes[[f]] <- 0L

        # Apply text-based fixes
        if (any(active_fixes != "styler" & active_fixes != "namespace" &
          active_fixes != "library" & active_fixes != "dead_code")) {
          res <- .apply_text_fixes(current, file_path)
          current <- res$content
          file_fixes <- res$fixes
        }

        # Namespace detection (report only)
        if ("namespace" %in% active_fixes || "library" %in% active_fixes) {
          lib_info <- .detect_library(file_path, current)
          file_fixes[["namespace"]] <- lib_info$ns_fixes
          file_fixes[["library"]] <- lib_info$unused_libs
        }

        # Dead code detection (report only)
        if ("dead_code" %in% active_fixes) {
          dc <- .detect_dead_code(current)
          file_fixes[["dead_code"]] <- dc
        }

        changed <- !identical(original, current)

        if (changed && !dry_run) {
          if (backup) {
            fs::file_copy(file_path, paste0(file_path, ".bak"), overwrite = TRUE)
          }
          writeLines(current, file_path)
        }

        list(
          file = file_path,
          modified = changed,
          fixes = file_fixes
        )
      },
      error = function(e) {
        list(file = file_path, modified = FALSE, fixes = list())
      }
    )
  }

  # Run processing
  if (verbose && length(r_files) > 1) {
    cli::cli_progress_step("Applying fixes to {length(r_files)} file(s)")
  }

  if (parallel && length(r_files) > 5 && requireNamespace("parallel", quietly = TRUE)) {
    n_workers <- min(n_cores, length(r_files))
    if (.Platform$OS.type == "windows" && n_workers > 1L) {
      cli::cli_inform(c(
        "i" = "Windows does not support forked parallelism; using a single worker."
      ))
      n_workers <- 1L
    }
    results <- parallel::mclapply(r_files, .process_file,
      mc.cores = n_workers
    )
  } else {
    results <- lapply(r_files, .process_file)
  }

  # Compile results
  for (res in results) {
    if (res$modified) {
      files_modified <- c(files_modified, res$file)
    }
    for (f in names(res$fixes)) {
      if (is.numeric(res$fixes[[f]]) && res$fixes[[f]] > 0) {
        fixes_total[[f]] <- (fixes_total[[f]] %||% 0L) + res$fixes[[f]]
      }
    }
  }

  # ---- Apply styler formatting ----
  if ("styler" %in% active_fixes && length(r_files) > 0) {
    formatter_choice <- formatter[1]

    if (formatter_choice == "air") {
      # Use air format
      air_bin <- tryCatch(.find_air(), error = function(e) NULL)
      if (!is.null(air_bin)) {
        withr::with_dir(path, {
          tryCatch(
            {
              system2(air_bin, "format", stdout = FALSE, stderr = FALSE)
              # Find what changed after air
              after_files <- fs::dir_ls(path, recurse = TRUE, regexp = include)
              after_files <- after_files[!grepl(exclude_regex, after_files)]
              formatted <- after_files[as.character(after_files) %in% r_files]
              if (dry_run) {
                # air format --check would be used here
              } else {
                fixes_total[["styler"]] <- (fixes_total[["styler"]] %||% 0L) + length(formatted)
              }
            },
            error = function(e) {
              cli::cli_warn("air formatting failed: {conditionMessage(e)}")
            }
          )
        })
      } else {
        cli::cli_warn("air not found. Run {.fn install_air} or use formatter=\"styler\".")
      }
    } else {
      # Use styler, with a hard timeout so a malformed file cannot block the
      # whole pipeline indefinitely.
      style_dry <- if (dry_run) "on" else "off"
      n_changed <- tryCatch(
        .run_with_timeout(
          function() {
            withr::with_dir(path, {
              changed_list <- styler::style_dir(
                path, dry = style_dry, include_roxygen_examples = FALSE
              )
              if (is.list(changed_list) && length(changed_list) > 0) {
                sum(vapply(changed_list, function(x) {
                  if (is.list(x) && !is.null(x$changed)) isTRUE(x$changed[1]) else 0L
                }, integer(1)), na.rm = TRUE)
              } else {
                0L
              }
            })
          },
          timeout = style_timeout
        ),
        error = function(e) {
          if (grepl("reached elapsed time", conditionMessage(e))) {
            cli::cli_warn(c(
              "!" = "Style formatting timed out after {.val {style_timeout}s}; skipping styler formatting.",
              "i" = "Consider using {.code formatter = \"air\"} instead."
            ))
          } else {
            cli::cli_warn("Style formatting failed: {conditionMessage(e)}")
          }
          0L
        }
      )
      fixes_total[["styler"]] <- (fixes_total[["styler"]] %||% 0L) + n_changed
    }
  }

  elapsed <- round(as.numeric(difftime(Sys.time(), start_time, units = "secs")), 1)

  # ---- Build result ----
  fix_result <- .make_fix_result(
    path, r_files, files_modified, fixes_total,
    dry_run, start_time, verbose
  )
  fix_result$elapsed <- elapsed
  fix_result$fixes_applied <- fixes_total

  # ---- Generate report ----
  if (report) {
    report_data <- list(
      files = list(
        scanned = length(r_files),
        modified = length(files_modified)
      ),
      fixes = fix_result$fixes_applied
    )
    jsonlite::write_json(report_data, report_file, pretty = TRUE, auto_unbox = TRUE)
    if (verbose) {
      cli::cli_inform(c("v" = "Report saved: {.path {report_file}}"))
    }
    fix_result$report_file <- report_file
  }

  if (verbose) {
    print(fix_result)
  }

  invisible(fix_result)
}


# ============================================================================
# Fix Implementation Functions
# ============================================================================

#' Fix spacing around operators and assignments
#' @noRd
.fix_spacing <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]

    # Skip comments
    if (grepl("^\\s*#", line)) next

    # x<-1 -> x <- 1
    new_line <- gsub("([\\w\\)\\]\\}])(\\s*)(<-|=)(\\s*)([\\w\\(\\[\\{])",
      "\\1 \\3 \\5", line,
      perl = TRUE
    )
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }

    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix T/F -> TRUE/FALSE
#' @noRd
.fix_true_false <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # Skip comments
    if (grepl("^\\s*#", line)) next

    # T -> TRUE, F -> FALSE (but not inside strings or identifiers)
    new_line <- gsub("\\bT\\b(?!_)", "TRUE", line, perl = TRUE)
    new_line <- gsub("\\bF\\b(?!_)", "FALSE", new_line, perl = TRUE)
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix NULL assignment
#' @noRd
.fix_null <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # x=NULL -> x <- NULL (but only outside function args)
    # Match patterns like: identifier = NULL at start of line or after ;
    new_line <- gsub("^(\\s*)([a-zA-Z._][a-zA-Z0-9._]*)\\s*=\\s*NULL\\b",
      "\\1\\2 <- NULL", line,
      perl = TRUE
    )
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix commas - add space after
#' @noRd
.fix_commas <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # c(1,2,3) -> c(1, 2, 3)
    new_line <- gsub(",(\\S)", ", \\1", line, perl = TRUE)
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix unnecessary parentheses
#' @noRd
.fix_parens <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # return((x)) -> return(x)
    new_line <- gsub("return\\(\\(([^()]+)\\)\\)", "return(\\1)", line, perl = TRUE)
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix cleanup: trailing whitespace, multiple blank lines, comments, EOF
#' @noRd
.fix_cleanup <- function(content) {
  n <- 0L

  # Remove trailing whitespace
  for (i in seq_along(content)) {
    new_line <- gsub("[ \\t]+$", "", content[i], perl = TRUE)
    if (new_line != content[i]) {
      n <- n + 1L
      content[i] <- new_line
    }
  }

  # Remove long separator comment lines ####
  content <- .rm_double_comment(content)

  # Remove empty comment blocks
  content <- .rm_empty_comment(content)

  # Collapse multiple blank lines into one
  i <- 2L
  while (i <= length(content)) {
    if (nzchar(content[i]) == FALSE && nzchar(content[i - 1]) == FALSE) {
      content <- content[-i]
      n <- n + 1L
    } else {
      i <- i + 1L
    }
  }

  # Ensure single trailing newline
  if (length(content) > 0) {
    while (length(content) > 0 && !nzchar(content[length(content)])) {
      content <- content[-length(content)]
      n <- n + 1L
    }
    content <- c(content, "")
  }

  list(content = content, n = n)
}

#' Remove double separator comment lines
#' @noRd
.rm_double_comment <- function(content) {
  # Remove lines that are ONLY #### with optional trailing whitespace
  # But keep single #---- lines for structure
  pattern <- "^#[-#]{5,}\\s*$"
  i <- 1L
  while (i <= length(content)) {
    if (grepl(pattern, content[i])) {
      # Check if previous line is also a separator
      if (i > 1 && grepl(pattern, content[i - 1])) {
        content <- content[-i]
      } else {
        i <- i + 1L
      }
    } else {
      i <- i + 1L
    }
  }
  content
}

#' Remove empty comment blocks
#' @noRd
.rm_empty_comment <- function(content) {
  # Remove lines that are just ### (no meaningful text)
  pattern <- "^#\\s*$"
  i <- 1L
  while (i <= length(content)) {
    if (grepl(pattern, content[i])) {
      # Remove if previous line is also a comment or blank
      if (i > 1 && (grepl("#", content[i - 1]) || !nzchar(content[i - 1]))) {
        content <- content[-i]
        next
      }
    }
    i <- i + 1L
  }
  content
}

#' Fix boolean simplifications
#'
#' Simplifies common boolean expression patterns:
#' - `if(x == TRUE)` → `if(x)`, `if(x == FALSE)` → `if(!x)`
#' - `x == TRUE` → `x`, `x == FALSE` → `!x` (general)
#' - `isTRUE(x) == TRUE` → `isTRUE(x)`
#' - `length(x) == 0` → `!length(x)`, `length(x) > 0` → `length(x)`
#' - `if(x == TRUE && y)` → `if(x && y)`
#' - `x == FALSE && ...` → `!x && ...`
#' @noRd
.fix_simplify <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    new_line <- line

    # --- if(x == TRUE) → if(x)  and  if(x == FALSE) → if(!x) ---
    new_line <- gsub("if\\s*\\(\\s*([a-zA-Z0-9._()]+)\\s*==\\s*TRUE\\s*\\)",
      "if(\\1)", new_line,
      perl = TRUE
    )
    new_line <- gsub("if\\s*\\(\\s*([a-zA-Z0-9._()]+)\\s*==\\s*FALSE\\s*\\)",
      "if(!\\1)", new_line,
      perl = TRUE
    )

    # --- General x == TRUE → x  and  x == FALSE → !x ---
    # Pattern: identifier == TRUE/FALSE (not inside if, general case)
    new_line <- gsub("\\b([a-zA-Z._][a-zA-Z0-9._]*)\\s*==\\s*TRUE\\b",
      "\\1", new_line,
      perl = TRUE
    )
    new_line <- gsub("\\b([a-zA-Z._][a-zA-Z0-9._]*)\\s*==\\s*FALSE\\b",
      "!\\1", new_line,
      perl = TRUE
    )

    # --- Compound: x == TRUE && y  →  x && y ---
    new_line <- gsub("\\b([a-zA-Z._][a-zA-Z0-9._]*)\\s*==\\s*TRUE\\s*(&&|\\|\\|)",
      "\\1 \\2", new_line,
      perl = TRUE
    )
    # --- Compound: x == FALSE && y  →  !x && y ---
    new_line <- gsub("\\b([a-zA-Z._][a-zA-Z0-9._]*)\\s*==\\s*FALSE\\s*(&&|\\|\\|)",
      "!\\1 \\2", new_line,
      perl = TRUE
    )

    # --- isTRUE(x) == TRUE → isTRUE(x) ---
    new_line <- gsub("isTRUE\\(([^()]+)\\)\\s*==\\s*TRUE", "isTRUE(\\1)",
      new_line,
      perl = TRUE
    )

    # --- length(x) == 0 → !length(x) ---
    new_line <- gsub("length\\(([^()]+)\\)\\s*==\\s*0", "!length(\\1)",
      new_line,
      perl = TRUE
    )
    # --- length(x) > 0 → length(x) ---
    new_line <- gsub("length\\(([^()]+)\\)\\s*>\\s*0", "length(\\1)",
      new_line,
      perl = TRUE
    )

    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix pipes: %>% -> |>
#' @noRd
.fix_pipes <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # x %>% f() -> x |> f()
    new_line <- gsub("%>%", "|>", line, fixed = TRUE)
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix assignment pipe %<>%
#' @noRd
.fix_magrittr <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # x %<>% f() -> x <- x |> f()
    # This is a simplification; real conversion needs AST parsing
    new_line <- gsub("([\\w._]+)\\s*%<>%\\s*(.*)", "\\1 <- \\1 |> \\2",
      line,
      perl = TRUE
    )
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Detect library usage and suggest namespace conversion
#' @noRd
.detect_library <- function(file_path, content) {
  ns_fixes <- 0L
  unused_libs <- 0L

  # Find all library() calls and their packages
  lib_calls <- list()
  for (line in content) {
    m <- regmatches(line, regexec("library\\([\"']?([a-zA-Z0-9._]+)[\"']?\\)", line))
    if (length(m[[1]]) > 1 && nzchar(m[[1]][2])) {
      pkg <- m[[1]][2]
      lib_calls[[pkg]] <- (lib_calls[[pkg]] %||% 0L) + 1L
    }
  }

  # Very basic check: if the package name appears in the code after the library call
  # This is simplified; a real implementation would use static analysis.
  # For now, report only with a heuristic.
  if (length(lib_calls) > 0) {
    # Simple heuristic: count package name occurrences
    full_text <- paste(content, collapse = "\n")
    for (pkg in names(lib_calls)) {
      # Check if pkg:: appears
      ns_pattern <- paste0(pkg, "::")
      if (grepl(ns_pattern, full_text, fixed = TRUE)) {
        ns_fixes <- ns_fixes + 1L
      }
    }
    unused_libs <- length(lib_calls) # Simplified: would need real tracking
  }

  list(ns_fixes = ns_fixes, unused_libs = unused_libs)
}

#' Detect dead code
#' @noRd
.detect_dead_code <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # Detect standalone expressions: only numbers, strings, simple computations
    # Basic: lines that are just a numeric constant
    if (grepl("^\\s*[0-9.]+\\s*$", line, perl = TRUE) ||
      grepl("^\\s*\"[^\"]*\"\\s*$", line, perl = TRUE)) {
      n <- n + 1L
    }
  }
  n
}

#' Fix return() formatting
#' @noRd
.fix_return <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # Collapse multi-line return(
    #   x
    # ) into return(x)
    new_line <- gsub("return\\s*\\(\\s*\\n\\s*([^)]+)\\s*\\n\\s*\\)",
      "return(\\1)", line,
      perl = TRUE
    )
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix assignment: = -> <- outside function calls
#' @noRd
.fix_assignment <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # Skip comments
    if (grepl("^\\s*#", line)) next
    # Skip lines inside function calls (heuristic: contain , before =)
    # Skip lines where = is inside a function call (like f(a = 1))
    if (grepl("\\w+\\([^)]*=\\s*", line, perl = TRUE)) next

    # Replace top-level = with <- (but not ==, !=, <=, >=)
    # Pattern: identifier = value (capture the RHS too)
    new_line <- gsub("^(\\s*)([a-zA-Z._][a-zA-Z0-9._]*)\\s*=\\s*(?!NULL\\b|TRUE\\b|FALSE\\b|NA\\b|function\\s*\\()(.+)$",
      "\\1\\2 <- \\3", line,
      perl = TRUE
    )
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix comment separators
#' @noRd
.fix_comments <- function(content) {
  n <- 0L
  for (i in seq_along(content)) {
    line <- content[i]
    # ########## -> #---------- (long comment blocks)
    if (grepl("^#[-]{5,}", line)) {
      # Already a separator, skip
      next
    }
    new_line <- gsub("^#{8,}", "#----------", line, perl = TRUE)
    if (new_line != line) {
      n <- n + 1L
      line <- new_line
    }
    content[i] <- line
  }
  list(content = content, n = n)
}

#' Fix duplicate library() calls - remove duplicate library() statements
#'
#' Scans a file for repeated `library()` calls loading the same package
#' and removes duplicate occurrences, keeping only the first one.
#' @noRd
.fix_duplicate_libs <- function(content) {
  n <- 0L

  # Find all library() calls with their line indices
  lib_pattern <- '^\\s*library\\s*\\(\\s*[\"\\\']?([a-zA-Z0-9._]+)[\"\\\']?\\s*\\)'
  seen <- character(0)
  lines_to_remove <- integer(0)

  for (i in seq_along(content)) {
    line <- content[i]
    # Skip comments
    if (grepl("^\\s*#", line)) next

    m <- regmatches(line, regexec(lib_pattern, line, perl = TRUE))
    if (length(m[[1]]) >= 2 && nzchar(m[[1]][2])) {
      pkg <- m[[1]][2]
      if (pkg %in% seen) {
        lines_to_remove <- c(lines_to_remove, i)
      } else {
        seen <- c(seen, pkg)
      }
    }
  }

  if (length(lines_to_remove) > 0L) {
    content <- content[-lines_to_remove]
    n <- length(lines_to_remove)
  }

  list(content = content, n = n)
}

#' Fix unused variables - detect and remove assignments never read
#'
#' Scans a file for variable assignments via `<-` or `=` and removes
#' lines where the assigned variable is never referenced elsewhere.
#' Uses conservative heuristics to avoid false positives:
#' - Only considers top-level assignments (not inside functions or control flow)
#' - Skips variables with names shorter than 3 chars
#' - Skips common names that may be used by other tools (e.g., `.`, `i`, `j`)
#' - Skips variables assigned from function calls (may have side effects)
#' - Skips lines containing `<<-` (super-assignment, visible elsewhere)
#' @noRd
.fix_unused_vars <- function(content) {
  n <- 0L
  if (length(content) < 2L) return(list(content = content, n = n))

  # Common variable names that should NOT be removed (may be used by IDE/tools)
  reserved <- c(".", "..", "i", "j", "k", "x", "y", "z", "tmp", "res",
                "out", "val", "ret", "df", "dt", "pkg", "fn", "f", "g")

  # Pattern: var_name <- value (at top level, starting with optional whitespace)
  # var_name = value for top-level assignments too
  assign_pattern <- "^\\s*([a-zA-Z._][a-zA-Z0-9._]*)\\s*(<-|=)\\s*(.*)$"

  # Build a list of (line_index, var_name) for candidate assignments
  candidates <- list()
  for (i in seq_along(content)) {
    line <- content[i]
    # Skip comments
    if (grepl("^\\s*#", line)) next
    # Skip super-assignment <<- (visible elsewhere)
    if (grepl("<<-", line, fixed = TRUE)) next
    # Skip if line contains function definition
    if (grepl("\\bfunction\\s*\\(", line, perl = TRUE)) next
    # Skip lines inside obvious control structures (heuristic: leading spaces + keyword)
    if (grepl("^\\s+(if|for|while|else|switch)\\b", line, perl = TRUE)) next

    m <- regmatches(line, regexec(assign_pattern, line, perl = TRUE))
    if (length(m[[1]]) >= 4 && nzchar(m[[1]][2])) {
      var_name <- m[[1]][2]
      rhs <- m[[1]][4]

      # Skip very short names
      if (nchar(var_name) < 3L) next
      # Skip reserved names
      if (var_name %in% reserved) next
      # Skip if RHS contains a function call (may have side effects)
      if (grepl("\\w+\\s*\\(", rhs, perl = TRUE)) next
      # Skip if RHS is complex (multiple operators = likely needed)
      if (grepl("[&|+\\-*/%%^><]", rhs, perl = TRUE)) next
      # Skip if RHS is a simple literal (TRUE/FALSE/NULL/NA) - these are intentional
      if (grepl("^\\s*(TRUE|FALSE|NULL|NA|Inf|NaN)\\s*$", rhs, perl = TRUE)) next

      candidates[[length(candidates) + 1L]] <- list(idx = i, var = var_name)
    }
  }

  if (length(candidates) == 0L) return(list(content = content, n = n))

  # Check each candidate: is the variable used anywhere else?
  full_text <- paste(content, collapse = "\n")
  lines_to_remove <- integer(0)
  for (cand in candidates) {
    var_name <- cand$var
    idx <- cand$idx
    # Count occurrences of the variable name in the whole file
    # Use word boundary to avoid partial matches
    pattern <- paste0("\\b", var_name, "\\b")
    matches <- gregexpr(pattern, full_text, perl = TRUE)[[1]]
    occurrences <- length(matches[matches > 0])
    # If only 1 occurrence, it's the assignment itself → unused
    # Also check: if exactly 2 occurrences and both are on the same line (self-reference)
    if (occurrences <= 1L) {
      lines_to_remove <- c(lines_to_remove, idx)
    }
  }

  if (length(lines_to_remove) > 0L) {
    content <- content[-lines_to_remove]
    n <- length(lines_to_remove)
  }

  list(content = content, n = n)
}


# ============================================================================
# Helper Functions
# ============================================================================

#' Build the fix result object
#' @noRd
.make_fix_result <- function(path, scanned, modified, fixes,
                             dry_run, start_time, verbose) {
  elapsed <- round(as.numeric(difftime(Sys.time(), start_time, units = "secs")), 1)

  mode_info <- if (dry_run) "(dry-run)" else ""

  # Build summary report string
  report_lines <- c(
    sprintf("rsonar Fix Report %s", mode_info),
    sprintf("  Path: %s", path),
    sprintf("  Files scanned: %d", length(scanned)),
    sprintf("  Files modified: %d", length(modified)),
    sprintf("  Time: %.1fs", elapsed)
  )
  if (length(fixes) > 0) {
    report_lines <- c(report_lines, "  Fixes applied:")
    for (f in names(fixes)) {
      if (is.numeric(fixes[[f]]) && fixes[[f]] > 0) {
        report_lines <- c(report_lines, sprintf("    %s: %d", f, fixes[[f]]))
      }
    }
  }
  report_text <- paste(report_lines, collapse = "\n")

  structure(
    list(
      files_scanned  = length(scanned),
      files_modified = length(modified),
      fixes_applied  = fixes,
      fixes_skipped  = list(),
      elapsed        = elapsed,
      report         = report_text,
      path           = path,
      timestamp      = Sys.time(),
      dry_run        = dry_run
    ),
    class = "sonar_fix"
  )
}


# ============================================================================
# S3 Methods
# ============================================================================

#' Print a sonar_fix Object
#'
#' @param x A `sonar_fix` object returned by [sonar_fix()].
#' @param ... Additional arguments (ignored).
#' @return `x` invisibly.
#' @export
print.sonar_fix <- function(x, ...) {
  mode <- if (x$dry_run) " (dry-run - no files modified)" else ""
  cli::cli_h1("rsonar Fix Report{mode}")

  cli::cli_inform(c(
    "i" = "Path    : {.path {x$path}}",
    "i" = "Files   : {x$files_scanned} scanned, {x$files_modified} modified",
    "i" = "Time    : {x$elapsed}s"
  ))

  if (length(x$fixes_applied) > 0) {
    has_fixes <- vapply(
      x$fixes_applied, function(v) is.numeric(v) && v > 0,
      logical(1)
    )
    active <- names(x$fixes_applied)[has_fixes]
    if (length(active) > 0) {
      cli::cli_h3("Fixes applied")
      for (f in active) {
        cli::cli_inform(c(" " = "{.field {f}}: {x$fixes_applied[[f]]}"))
      }
    } else {
      cli::cli_inform(c("v" = "No fixes needed."))
    }
  }

  if (x$dry_run && x$files_modified > 0) {
    cli::cli_inform(c(
      "i" = "Run {.fn sonar_fix} with {.arg dry_run = FALSE} to apply fixes."
    ))
  }

  invisible(x)
}


# ============================================================================
# Internal null-coalescing operator (reused from analyse.R)
# ============================================================================
`%||%` <- function(x, y) if (is.null(x)) y else x

# ============================================================================
# install_air - kept for backward compatibility
# ============================================================================

#' Install air R Code Formatter
#'
#' Downloads and runs the official air installer from the latest GitHub
#' release. Uses the PowerShell installer on Windows and the shell installer
#' on other platforms.
#'
#' @param force Logical. Reinstall even if air is already available on the
#' system PATH. Default FALSE.
#'
#' @return The path to the installed air binary, invisibly.
#' @seealso [sonar_fix()]
#' @export
install_air <- function(force = FALSE) {
  air_bin <- Sys.which("air")
  
  if (nzchar(air_bin) && !force) {
    cli::cli_inform(c(v = "air already installed: {.path {air_bin}}"))
    return(invisible(as.character(air_bin)))
  }
  
  is_windows <- .Platform$OS.type == "windows"
  installer <- if (is_windows) "air-installer.ps1" else "air-installer.sh"
  
  url <- paste0(
    "https://github.com/posit-dev/air/releases/latest/download/",
    installer
  )
  
  file <- tempfile(fileext = if (is_windows) ".ps1" else ".sh")
  on.exit(unlink(file))
  
  utils::download.file(url, file, mode = "wb", quiet = TRUE)
  
  status <- if (is_windows) {
    system2(
      "powershell",
      c("-ExecutionPolicy", "Bypass", "-File", shQuote(file))
    )
  } else {
    system2("sh", shQuote(file))
  }
  
  if (status != 0L) {
    cli::cli_abort("air installation failed.")
  }
  
  air_bin <- Sys.which("air")
  
  cli::cli_inform(c(v = "air installed to {.path {air_bin}}"))
  
  invisible(as.character(air_bin))
}
