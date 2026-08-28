# ============================================================================
# Internal utilities
# ============================================================================

#' Run a function with a hard time limit
#'
#' Runs `fun()` with a hard timeout. On Unix-like systems it forks a child
#' process (via `parallel::mcparallel()`) and kills it if it exceeds `timeout`,
#' which reliably interrupts code that blocks in native code (e.g. `styler`
#' on malformed files). On Windows, where forking is not available, it falls
#' back to [base::setTimeLimit()] as a best effort.
#'
#' @param fun A function returning the value to compute.
#' @param timeout Number of seconds before giving up. Use `Inf` to disable
#'   the timeout.
#'
#' @return The value returned by `fun()`. Throws an error when the timeout is
#'   reached.
#' @keywords internal
#' @noRd
.run_with_timeout <- function(fun, timeout) {
  if (!is.finite(timeout)) {
    return(fun())
  }

  if (.Platform$OS.type == "windows") {
    setTimeLimit(elapsed = timeout, transient = TRUE)
    on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
    return(fun())
  }

  job <- tryCatch(
    parallel::mcparallel(fun(), silent = TRUE),
    error = function(e) NULL
  )

  # If forking is unavailable for any reason, fall back to the best-effort
  # in-process timeout.
  if (is.null(job)) {
    setTimeLimit(elapsed = timeout, transient = TRUE)
    on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
    return(fun())
  }

  res <- parallel::mccollect(job, wait = FALSE, timeout = timeout)

  if (is.null(res) || length(res) == 0L) {
    try(tools::pskill(job$pid, tools::SIGKILL), silent = TRUE)
    suppressWarnings(parallel::mccollect(job, wait = FALSE))
    stop("reached elapsed time limit", call. = FALSE)
  }

  result <- res[[1]]

  # mcparallel wraps the child evaluation in try(), so a function that errors
  # returns a "try-error" value instead of throwing in the parent. Re-throw it
  # so callers keep their usual tryCatch() behaviour.
  if (inherits(result, "try-error")) {
    cond <- attr(result, "condition", exact = TRUE)
    if (inherits(cond, "condition")) {
      stop(cond, call. = FALSE)
    }
    stop(as.character(result), call. = FALSE)
  }

  result
}
