#' Auto-Fix Code Quality Issues with air
#'
#' Runs `air` (Posit's R code formatter) on R files to automatically fix
#' code style and lint issues. Optionally creates a git branch and pushes
#' changes for review via Merge Request (GitLab) or Pull Request (GitHub).
#'
#' `air` is a fast, opinionated R code formatter developed by Posit.
#' It reformats R code according to modern style conventions.
#' See \url{https://github.com/posit-dev/air} for installation instructions.
#'
#' @param path Path to the R project or directory. Default current directory.
#' @param files Character vector of specific R files to fix. If `NULL`
#'   (default), all R files in `path` are processed.
#' @param create_mr Logical. If `TRUE`, attempts to create a git branch,
#'   commit changes, push, and open a Merge Request (GitLab CI) or
#'   Pull Request (GitHub Actions). Requires `git` and appropriate CI
#'   environment variables. Default `FALSE`.
#' @param branch_name Name of the branch to create. If `NULL`, an
#'   automatic name `"rsonar/auto-fix-{timestamp}"` is generated.
#'   Default `NULL`.
#' @param commit_message Commit message. Default
#'   `"style: auto-format code with air via rsonar"`.
#' @param mr_title Title of the MR / PR. Default
#'   `"Auto-fix: code style improvements via rsonar"`.
#' @param dry_run Logical. If `TRUE`, only check what would be changed
#'   without modifying files (uses `air format --check`).
#'   Default `FALSE`.
#' @param verbose Logical. Show progress and result summary.
#'   Default `TRUE`.
#'
#' @return An object of class `rsonar_fix` containing:
#'   \describe{
#'     \item{`files_changed`}{Character vector of modified file paths}
#'     \item{`diff_summary`}{Summary string from air output}
#'     \item{`branch`}{Name of the created branch (if `create_mr = TRUE`)}
#'     \item{`mr_url`}{URL of the created MR/PR (if applicable)}
#'     \item{`dry_run`}{Whether dry-run mode was used}
#'     \item{`path`}{Analyzed project path}
#'     \item{`timestamp`}{Execution timestamp}
#'   }
#'
#' @examples
#' \dontrun{
#' # Check what would be changed (no file modification)
#' fix <- sonar_fix(".", dry_run = TRUE)
#' print(fix)
#'
#' # Auto-fix all R files in the current project
#' fix <- sonar_fix(".")
#'
#' # Fix specific files only
#' fix <- sonar_fix(".", files = c("R/analyse.R", "R/export.R"))
#'
#' # Auto-fix and create a Merge Request (in GitLab CI)
#' fix <- sonar_fix(".", create_mr = TRUE)
#' }
#'
#' @seealso [sonar_analyse()] for code quality analysis,
#'   [install_air()] to install the air formatter.
#' @export
sonar_fix <- function(
    path = ".",
    files = NULL,
    create_mr = FALSE,
    branch_name = NULL,
    commit_message = "style: auto-format code with air via rsonar",
    mr_title = "Auto-fix: code style improvements via rsonar",
    dry_run = FALSE,
    verbose = TRUE) {

  path <- fs::path_abs(path)

  if (!fs::dir_exists(path)) {
    cli::cli_abort("Directory not found: {.path {path}}")
  }

  # ---- Locate air binary ----
  air_bin <- .find_air()

  if (verbose) {
    cli::cli_inform(c("i" = "Using air: {.path {air_bin}}"))
  }

  # ---- Build command ----
  args <- c("format")

  if (dry_run) {
    args <- c(args, "--check")
  }

  if (!is.null(files)) {
    # Convert to relative paths from `path`
    rel_files <- vapply(files, function(f) {
      as.character(fs::path_rel(f, path))
    }, character(1))
    args <- c(args, rel_files)
  } else {
    args <- c(args, ".")
  }

  if (verbose) {
    mode <- if (dry_run) " (dry-run)" else ""
    cli::cli_progress_step("Running air formatter{mode} on {.path {path}}")
  }

  # ---- Run air ----
  stdout_lines <- character(0)
  stderr_lines <- character(0)
  exit_code <- 0L

  withr::with_dir(path, {
    # Use pipe to capture both stdout and stderr
    tmp_stdout <- tempfile("air-stdout-")
    tmp_stderr <- tempfile("air-stderr-")
    on.exit(unlink(c(tmp_stdout, tmp_stderr)))

    exit_code <- system2(air_bin, args,
                         stdout = tmp_stdout,
                         stderr = tmp_stderr)

    if (file.exists(tmp_stdout)) {
      stdout_lines <- readLines(tmp_stdout, warn = FALSE)
    }
    if (file.exists(tmp_stderr)) {
      stderr_lines <- readLines(tmp_stderr, warn = FALSE)
    }
  })

  # ---- Parse output for changed files ----
  changed_files <- character(0)

  if (dry_run) {
    # air format --check outputs "Would reformat <file>" for each file
    all_output <- c(stdout_lines, stderr_lines)
    for (line in all_output) {
      if (grepl("^Would reformat", line)) {
        f <- sub("^Would reformat\\s+", "", line)
        f <- trimws(f)
        changed_files <- c(changed_files, f)
      }
    }
  } else if (exit_code == 0L) {
    # air format succeeded silently = all files formatted
    # Detect changed files via git diff if in a repo
    changed_files <- .git_changed_files(path)
    if (length(changed_files) == 0L) {
      # No git: air output may list formatted files
      all_output <- c(stdout_lines, stderr_lines)
      # air outputs formatted file paths on success
      for (line in all_output) {
        line <- trimws(line)
        if (grepl("\\.R$", line, ignore.case = TRUE) && fs::file_exists(fs::path(path, line))) {
          changed_files <- c(changed_files, line)
        }
      }
    }
  }

  diff_summary <- if (length(c(stdout_lines, stderr_lines)) > 0) {
    paste(c(stdout_lines, stderr_lines), collapse = "\n")
  } else {
    ""
  }

  if (verbose && length(changed_files) > 0L) {
    cli::cli_inform(c(
      "i" = "{length(changed_files)} file(s) changed by air"
    ))
  }

  if (verbose && length(changed_files) == 0L && !dry_run) {
    cli::cli_inform(c("v" = "All files already properly formatted."))
  }

  # ---- Create Merge Request ----
  mr_url <- NULL
  branch <- NULL

  if (create_mr && !dry_run && length(changed_files) > 0L) {
    if (is.null(branch_name)) {
      timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
      branch_name <- paste0("rsonar/auto-fix-", timestamp)
    }

    if (verbose) {
      cli::cli_progress_step("Creating Merge Request branch: {.val {branch_name}}")
    }

    mr_result <- tryCatch(
      .create_merge_request(path, branch_name, commit_message, mr_title),
      error = function(e) {
        cli::cli_warn("Could not create Merge Request: {conditionMessage(e)}")
        list(url = NULL, branch = branch_name)
      }
    )

    mr_url <- mr_result$url
    branch <- mr_result$branch
  }

  # ---- Build result object ----
  fix <- structure(
    list(
      files_changed = changed_files,
      diff_summary  = diff_summary,
      branch        = branch,
      mr_url        = mr_url,
      dry_run       = dry_run,
      path          = path,
      timestamp     = Sys.time()
    ),
    class = "rsonar_fix"
  )

  if (verbose) {
    print(fix)
  }

  invisible(fix)
}


# ---- Internal helpers -------------------------------------------------------

#' Locate the air binary
#'
#' Searches for `air` on the system PATH. If not found, tries common
#' installation locations. If still not found, raises an informative error
#' suggesting to call [install_air()].
#'
#' @return Path to the air binary.
#' @keywords internal
.find_air <- function() {
  air_bin <- Sys.which("air")

  if (air_bin != "" && nchar(air_bin) > 0L) {
    return(as.character(air_bin))
  }

  # Try common installation paths
  candidates <- c(
    fs::path(Sys.getenv("HOME"), ".local", "bin", "air"),
    fs::path(Sys.getenv("HOME"), ".cargo", "bin", "air"),
    fs::path(Sys.getenv("USERPROFILE"), "bin", "air.exe"),
    fs::path(Sys.getenv("USERPROFILE"), ".cargo", "bin", "air.exe"),
    "/usr/local/bin/air",
    "/opt/homebrew/bin/air"
  )

  for (candidate in candidates) {
    if (fs::file_exists(candidate)) {
      return(as.character(candidate))
    }
  }

  # Not found: provide helpful error
  cli::cli_abort(c(
    "x" = "air is not installed or not found on PATH.",
    "i" = "Install air from {.url https://github.com/posit-dev/air}",
    "i" = "Or call {.fn rsonar::install_air} to install it automatically.",
    "i" = "On macOS: {.code brew install posit-dev/posit/air}",
    "i" = "On Linux: download the binary from GitHub Releases",
    "i" = "On Windows: {.code scoop install air} or download from GitHub"
  ))
}

#' Get files changed in working tree
#'
#' Returns files modified (M) or untracked (?) relative to HEAD.
#'
#' @param path Project root.
#' @return Character vector of changed file paths relative to `path`.
#' @keywords internal
.git_changed_files <- function(path) {
  if (!fs::dir_exists(fs::path(path, ".git"))) {
    return(character(0L))
  }

  tryCatch({
    withr::with_dir(path, {
      # Modified + untracked R files
      modified <- system2("git", c("diff", "--name-only", "HEAD"),
                          stdout = TRUE, stderr = FALSE)
      untracked <- system2("git", c("ls-files", "--others", "--exclude-standard"),
                           stdout = TRUE, stderr = FALSE)
      all_changed <- unique(c(modified, untracked))
      all_changed <- all_changed[nzchar(all_changed)]
      all_changed
    })
  }, error = function(e) character(0L))
}

#' Create a Merge Request / Pull Request
#'
#' Detects the CI environment (GitLab CI or GitHub Actions) and opens
#' a Merge Request or Pull Request with the formatted changes.
#'
#' @param path Project root.
#' @param branch_name Name of the branch to create.
#' @param commit_message Git commit message.
#' @param mr_title Title of the MR/PR.
#'
#' @return A list with `url` (MR/PR URL) and `branch` (branch name).
#' @keywords internal
.create_merge_request <- function(path, branch_name, commit_message, mr_title) {
  withr::with_dir(path, {
    # Check if there are changes to commit
    diff_out <- system2("git", c("diff", "--stat"), stdout = TRUE, stderr = FALSE)
    if (length(diff_out) == 0L || all(!nzchar(diff_out))) {
      cli::cli_warn("No changes to commit. Skipping MR creation.")
      return(list(url = NULL, branch = branch_name))
    }

    # Create branch
    system2("git", c("checkout", "-b", branch_name))

    # Stage and commit
    system2("git", c("add", "."))
    system2("git", c("commit", "-m", commit_message))

    # Push branch
    push_args <- c("push", "origin", branch_name)

    # GitLab CI: use push options to create MR
    if (Sys.getenv("GITLAB_CI") != "") {
      push_args <- c(push_args,
        "-o", "merge_request.create",
        "-o", paste0("merge_request.title=", mr_title),
        "-o", "merge_request.description=Automatic code style fixes via rsonar + air.",
        "-o", "merge_request.target=", Sys.getenv("CI_DEFAULT_BRANCH", "main"),
        "-o", "merge_request.remove_source_branch=true"
      )
    }

    system2("git", push_args)

    # Try to extract MR URL from output (GitLab)
    mr_url <- NULL

    # GitHub Actions: use gh CLI
    if (Sys.getenv("GITHUB_ACTIONS") != "") {
      gh_bin <- Sys.which("gh")
      if (gh_bin != "" && nchar(gh_bin) > 0L) {
        pr_output <- system2(gh_bin, c("pr", "create",
          "--title", mr_title,
          "--body", "Automatic code style fixes via rsonar + air.",
          "--head", branch_name,
          "--base", Sys.getenv("GITHUB_BASE_REF", "main")
        ), stdout = TRUE, stderr = FALSE)
        mr_url <- if (length(pr_output) > 0L) pr_output[1] else NULL
      }
    }

    # For GitLab, construct URL from CI variables
    if (Sys.getenv("GITLAB_CI") != "") {
      ci_project_url <- Sys.getenv("CI_PROJECT_URL")
      if (ci_project_url != "") {
        mr_url <- paste0(ci_project_url, "/-/merge_requests")
      }
    }

    list(url = mr_url, branch = branch_name)
  })
}


#' Install air R Code Formatter
#'
#' Downloads and installs the `air` R code formatter binary from the
#' official GitHub releases. Supports Linux (x86_64, aarch64),
#' macOS (Intel and Apple Silicon), and Windows.
#'
#' On Linux and macOS, the binary is installed to `~/.local/bin/air`.
#' On Windows, it is installed to `~/bin/air.exe`.
#'
#' @param version Specific version to install (e.g., `"v0.1.0"`).
#'   If `"latest"` (default), the latest stable release is installed.
#' @param force Logical. If `TRUE`, reinstall even if `air` is already
#'   present. Default `FALSE`.
#'
#' @return The path to the installed `air` binary (invisibly).
#'
#' @examples
#' \dontrun{
#' # Install the latest version
#' install_air()
#'
#' # Install a specific version
#' install_air(version = "v0.1.0")
#'
#' # Reinstall even if already present
#' install_air(force = TRUE)
#' }
#'
#' @seealso [sonar_fix()] to use air for auto-fixing R code.
#' @export
install_air <- function(version = "latest", force = FALSE) {
  # Check if already installed
  air_bin <- Sys.which("air")
  if (air_bin != "" && nchar(air_bin) > 0L && !force) {
    cli::cli_inform(c(
      "v" = "air is already installed: {.path {air_bin}}",
      "i" = "Use {.arg force = TRUE} to reinstall."
    ))
    return(invisible(as.character(air_bin)))
  }

  # Determine platform
  sysname <- Sys.info()[["sysname"]]
  machine <- Sys.info()[["machine"]]

  os_map <- list(
    Linux = "linux",
    Darwin = "macos",
    Windows = "windows"
  )
  os <- os_map[[sysname]]
  if (is.null(os)) {
    cli::cli_abort("Unsupported operating system: {sysname}")
  }

  # Map architecture
  arch_map <- list(
    x86_64  = "x86_64",
    amd64   = "x86_64",
    aarch64 = "aarch64",
    arm64   = "aarch64"
  )
  arch <- arch_map[[machine]]
  if (is.null(arch)) {
    cli::cli_abort("Unsupported architecture: {machine}")
  }

  ext <- if (os == "windows") "zip" else "tar.gz"
  binary_name <- if (os == "windows") "air.exe" else "air"

  # Build download URL
  base_url <- "https://github.com/posit-dev/air/releases"
  if (version == "latest") {
    url <- paste0(base_url, "/latest/download/air-", os, "-", arch, ".", ext)
  } else {
    url <- paste0(base_url, "/download/", version, "/air-", os, "-", arch, ".", ext)
  }

  # Create temporary directory
  tmp_dir <- fs::path(tempdir(), paste0("air-install-", as.integer(Sys.time())))
  fs::dir_create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  dest_archive <- fs::path(tmp_dir, paste0("air.", ext))

  cli::cli_progress_step("Downloading air from {.url {url}}")

  tryCatch(
    utils::download.file(url, dest_archive, mode = "wb", quiet = TRUE),
    error = function(e) {
      cli::cli_abort(c(
        "x" = "Failed to download air.",
        "i" = "URL: {.url {url}}",
        "i" = "You can install air manually: {.url https://github.com/posit-dev/air}"
      ))
    }
  )

  # Extract archive
  cli::cli_progress_step("Extracting air...")
  if (ext == "zip") {
    utils::unzip(dest_archive, exdir = tmp_dir)
  } else {
    utils::untar(dest_archive, exdir = tmp_dir)
  }

  # Locate the extracted binary
  extracted_bin <- fs::dir_ls(tmp_dir, recurse = TRUE,
                               regexp = paste0(binary_name, "$"))

  if (length(extracted_bin) == 0L) {
    # If not found directly, take any file named air or air.exe
    all_files <- fs::dir_ls(tmp_dir, recurse = TRUE, type = "file")
    extracted_bin <- all_files[basename(all_files) == binary_name]
  }

  if (length(extracted_bin) == 0L) {
    cli::cli_abort("Could not find the air binary in the downloaded archive.")
  }

  extracted_bin <- extracted_bin[[1]]

  # Determine installation directory
  if (.Platform$OS.type == "windows") {
    install_dir <- fs::path(Sys.getenv("USERPROFILE"), "bin")
  } else {
    install_dir <- fs::path(Sys.getenv("HOME"), ".local", "bin")
  }

  fs::dir_create(install_dir)
  dest_bin <- fs::path(install_dir, binary_name)

  fs::file_copy(extracted_bin, dest_bin, overwrite = TRUE)

  # Make executable on Unix
  if (.Platform$OS.type != "windows") {
    Sys.chmod(dest_bin, "0755")
  }

  cli::cli_inform(c(
    "v" = "air installed to {.path {dest_bin}}",
    "i" = "Make sure {.path {install_dir}} is in your PATH."
  ))

  invisible(as.character(dest_bin))
}


# ---- S3 print method --------------------------------------------------------

#' Print an rsonar_fix Object
#'
#' @param x An `rsonar_fix` object returned by [sonar_fix()].
#' @param ... Additional arguments (ignored).
#' @return `x` invisibly.
#' @export
print.rsonar_fix <- function(x, ...) {
  mode <- if (x$dry_run) " (dry-run — no files modified)" else ""
  cli::cli_h2("rsonar Fix Report{mode}")

  cli::cli_inform(c(
    "i" = "Path    : {.path {x$path}}",
    "i" = "Time    : {format(x$timestamp, '%Y-%m-%d %H:%M')}",
    "i" = "Files   : {length(x$files_changed)} file(s) changed"
  ))

  if (length(x$files_changed) > 0L) {
    cli::cli_h3("Changed files")
    for (f in x$files_changed) {
      cli::cli_inform(c(" " = "{.path {f}}"))
    }
  } else if (!x$dry_run) {
    cli::cli_inform(c("v" = "All files are already properly formatted."))
  }

  if (!is.null(x$branch)) {
    cli::cli_inform(c(
      "i" = "Branch  : {.val {x$branch}}"
    ))
  }

  if (!is.null(x$mr_url) && nzchar(x$mr_url)) {
    cli::cli_inform(c(
      "i" = "MR/PR   : {.url {x$mr_url}}"
    ))
  }

  if (x$dry_run && length(x$files_changed) > 0L) {
    cli::cli_inform(c(
      "i" = "Run {.fn sonar_fix} without {.arg dry_run = TRUE} to apply fixes."
    ))
  }

  invisible(x)
}