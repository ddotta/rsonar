#' Copy a Reference .lintr File into a Project
#'
#' Copies the default `.lintr` configuration file recommended by
#' `rsonar` into the target directory. This file enables linters equivalent
#' to the most common SonarQube rules for R.
#'
#' @param path Target directory. Default: current directory.
#' @param overwrite Overwrite if a `.lintr` file already exists. Default `FALSE`.
#'
#' @return The path to the created `.lintr` file (invisibly).
#'
#' @examples
#' \dontrun{
#' use_rsonar_lintr()
#' }
#'
#' @export
use_rsonar_lintr <- function(path = ".", overwrite = FALSE) {
  dest <- fs::path(path, ".lintr")
  if (fs::file_exists(dest) && !overwrite) {
    cli::cli_inform(c("i" = "A {.path .lintr} file already exists. Use {.arg overwrite = TRUE} to overwrite it."))
    return(invisible(dest))
  }

  template <- fs::path_package("rsonar", "templates", "default.lintr")
  fs::file_copy(template, dest, overwrite = overwrite)
  cli::cli_inform(c("v" = "{.path .lintr} file created in {.path {path}}"))
  invisible(dest)
}

#' Copy a CI Pipeline Template into a Project
#'
#' Copies a pre-configured pipeline template for rsonar.
#'
#' @param type CI type: `"gitlab"` or `"github"`. Default `"gitlab"`.
#' @param path Project root directory. Default `.`.
#' @param overwrite Overwrite if the file already exists. Default `FALSE`.
#'
#' @return The path to the created file (invisibly).
#'
#' @examples
#' \dontrun{
#' use_rsonar_ci("gitlab")
#' use_rsonar_ci("github")
#' }
#'
#' @export
use_rsonar_ci <- function(type = c("gitlab", "github"), path = ".", overwrite = FALSE) {
  type <- match.arg(type)

  if (type == "gitlab") {
    template <- fs::path_package("rsonar", "templates", "ci", "gitlab-rsonar.yml")
    dest     <- fs::path(path, ".gitlab-ci.yml")
  } else {
    template <- fs::path_package("rsonar", "templates", "ci", "github-rsonar.yml")
    dest_dir <- fs::path(path, ".github", "workflows")
    fs::dir_create(dest_dir)
    dest <- fs::path(dest_dir, "rsonar.yml")
  }

  if (fs::file_exists(dest) && !overwrite) {
    cli::cli_inform(c("i" = "{.path {dest}} already exists. Use {.arg overwrite = TRUE}."))
    return(invisible(dest))
  }

  fs::file_copy(template, dest, overwrite = overwrite)
  cli::cli_inform(c("v" = "{type} pipeline created: {.path {dest}}"))
  invisible(dest)
}
