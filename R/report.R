#' Generate an HTML Quality Report
#'
#' Produces an interactive HTML report summarizing all results from
#' [sonar_analyse()]: consolidated metrics, lint issues with file navigation,
#' style violations, test coverage and technical debt.
#'
#' @param x An `rsonar_result` object returned by [sonar_analyse()].
#' @param output Path to the output HTML file. Default `"rsonar_report.html"`.
#' @param title Report title. Default `"rsonar Quality Report"`.
#' @param open Open the report in a browser after generation. Default
#'   `interactive()`.
#'
#' @return The path to the generated HTML file (invisibly).
#'
#' @examples
#' \dontrun{
#' res <- sonar_analyse(".")
#' sonar_report(res, output = "quality.html")
#' }
#'
#' @export
sonar_report <- function(
    x,
    output = "rsonar_report.html",
    title  = "rsonar Quality Report",
    open   = interactive()) {

  if (!inherits(x, "rsonar_result")) {
    cli::cli_abort("{.arg x} must be an {.cls rsonar_result} object.")
  }

  html <- .build_html_report(x, title = title)
  writeLines(html, output)

  cli::cli_inform(c("v" = "Report generated: {.path {output}}"))

  if (open) utils::browseURL(output)

  invisible(output)
}

# ---- Internal HTML builder -------------------------------------------------

.build_html_report <- function(x, title) {
  m    <- x$metrics
  debt <- x$debt
  quality_pct <- if (!is.null(debt)) {
    round(100 * (1 - min(1, as.numeric(debt$ratio))), 1)
  } else {
    NA_real_
  }

  # SQALE rating color
  rating_css <- c(A = "#1a7f37", B = "#0969da", C = "#bf8700",
                  D = "#cf222e", E = "#6e40c9")
  rating_col <- if (!is.null(debt)) rating_css[[debt$rating]] else "#666"

  # Coverage block
  cov_block <- if (!is.na(m$coverage_pct)) {
    pct <- m$coverage_pct
    bar_col <- if (pct >= 80) "#1a7f37" else if (pct >= 60) "#bf8700" else "#cf222e"
    glue::glue('
      <div class="metric-card">
        <div class="metric-label">Test Coverage</div>
        <div class="metric-value" style="color:{bar_col}">{pct}%</div>
        <div class="progress-bar">
          <div class="progress-fill" style="width:{pct}%;background:{bar_col}"></div>
        </div>
      </div>')
  } else {
    '<div class="metric-card"><div class="metric-label">Coverage</div><div class="metric-value">N/A</div></div>'
  }

  # Lint table
  lint_rows <- if (length(x$lint) > 0) {
    rows <- vapply(x$lint, function(issue) {
      sev_color <- switch(issue$type,
        error   = "#cf222e",
        warning = "#bf8700",
        style   = "#0969da",
        "#666"
      )
      glue::glue('
        <tr>
          <td><span class="badge" style="background:{sev_color}">{issue$type}</span></td>
          <td style="font-family:monospace;font-size:0.85em">{fs::path_rel(issue$filename, x$path)}</td>
          <td>{issue$line_number}</td>
          <td>{htmlEscape(issue$message)}</td>
          <td style="color:#666;font-size:0.8em">{issue$linter}</td>
        </tr>')
    }, character(1))
    paste(rows, collapse = "\n")
  } else {
    '<tr><td colspan="5" style="text-align:center;color:green">&#10003; No issues detected</td></tr>'
  }

  # Style table
  style_rows <- if (!is.null(x$style) && any(x$style$changed, na.rm = TRUE)) {
    bad <- x$style[!is.na(x$style$changed) & x$style$changed, ]
    rows <- vapply(bad$file, function(f) {
      glue::glue('<tr><td style="font-family:monospace">{fs::path_rel(f, x$path)}</td><td style="color:#cf222e">Non-compliant</td></tr>')
    }, character(1))
    paste(rows, collapse = "\n")
  } else {
    '<tr><td colspan="2" style="text-align:center;color:green">&#10003; All code is properly formatted</td></tr>'
  }

  # Debt table
  debt_rows <- if (!is.null(debt)) {
    rows <- vapply(seq_len(nrow(debt$breakdown)), function(i) {
      row <- debt$breakdown[i, ]
      pct_of_total <- if (debt$minutes > 0) round(100 * row$minutes / debt$minutes) else 0
      glue::glue('<tr><td>{row$category}</td><td>{row$issues}</td><td>{row$minutes} min</td><td>{pct_of_total}%</td></tr>')
    }, character(1))
    paste(rows, collapse = "\n")
  } else ""

  glue::glue('<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title}</title>
  <style>
    :root {{ --primary: #0969da; --bg: #f6f8fa; --card: #fff; --border: #d0d7de; }}
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: var(--bg); color: #24292f; line-height: 1.6; }}
    header {{ background: #24292f; color: #fff; padding: 1.5rem 2rem; }}
    header h1 {{ font-size: 1.5rem; }}
    header .meta {{ font-size: 0.85rem; opacity: 0.7; margin-top: 0.3rem; }}
    main {{ max-width: 1100px; margin: 2rem auto; padding: 0 1rem; }}
    .metrics-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
                     gap: 1rem; margin-bottom: 2rem; }}
    .metric-card {{ background: var(--card); border: 1px solid var(--border);
                   border-radius: 8px; padding: 1rem; text-align: center; }}
    .metric-label {{ font-size: 0.8rem; color: #57606a; text-transform: uppercase;
                     letter-spacing: 0.05em; }}
    .metric-value {{ font-size: 2rem; font-weight: 700; margin: 0.5rem 0; }}
    .progress-bar {{ background: #e8eaed; border-radius: 4px; height: 6px; }}
    .progress-fill {{ height: 100%; border-radius: 4px; transition: width 0.5s; }}
    .rating-badge {{ display: inline-block; padding: 0.4rem 1.2rem;
                     border-radius: 50px; color: #fff; font-size: 2rem;
                     font-weight: 900; background: {rating_col}; }}
    section {{ background: var(--card); border: 1px solid var(--border);
              border-radius: 8px; margin-bottom: 1.5rem; overflow: hidden; }}
    section h2 {{ padding: 1rem 1.5rem; border-bottom: 1px solid var(--border);
                 font-size: 1rem; background: #f6f8fa; }}
    table {{ width: 100%; border-collapse: collapse; font-size: 0.9rem; }}
    th, td {{ padding: 0.6rem 1rem; text-align: left; border-bottom: 1px solid var(--border); }}
    th {{ background: #f6f8fa; font-weight: 600; font-size: 0.8rem;
         text-transform: uppercase; color: #57606a; }}
    tr:last-child td {{ border-bottom: none; }}
    .badge {{ display: inline-block; padding: 0.15rem 0.5rem; border-radius: 4px;
              color: #fff; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; }}
    footer {{ text-align: center; color: #57606a; font-size: 0.8rem; padding: 2rem; }}
  </style>
</head>
<body>
  <header>
    <h1>&#128202; {title}</h1>
    <div class="meta">
      Project: {x$path} &nbsp;|&nbsp;
      R files: {m$n_files} &nbsp;|&nbsp;
      Analysis: {format(x$timestamp, "%Y-%m-%d %H:%M")}
    </div>
  </header>
  <main>

    <!-- Key metrics -->
    <div class="metrics-grid">
      <div class="metric-card">
        <div class="metric-label">SQALE Rating</div>
        <div style="margin:0.5rem 0"><span class="rating-badge">{if (!is.null(debt)) debt$rating else "?"}</span></div>
        <div class="metric-label">{if (!is.null(debt)) paste0(debt$hours, "h of debt") else ""}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Quality Score</div>
        <div class="metric-value" style="color:{if (!is.na(quality_pct) && quality_pct >= 80) "#1a7f37" else if (!is.na(quality_pct) && quality_pct >= 60) "#bf8700" else "#cf222e"}">{if (!is.na(quality_pct)) paste0(quality_pct, "%") else "N/A"}</div>
        <div class="metric-label">derived from debt ratio</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Lint Issues</div>
        <div class="metric-value" style="color:{if (m$n_lint_issues == 0) "#1a7f37" else "#cf222e"}">{m$n_lint_issues}</div>
        <div class="metric-label">{m$n_lint_errors} err. / {m$n_lint_warnings} warn.</div>
      </div>
      {cov_block}
      <div class="metric-card">
        <div class="metric-label">Style (styler)</div>
        <div class="metric-value" style="color:{if (m$n_style_issues == 0) "#1a7f37" else "#bf8700"}">{m$n_style_issues}</div>
        <div class="metric-label">non-compliant files</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Best Practices</div>
        <div class="metric-value" style="color:{if (!is.na(m$gp_fails) && m$gp_fails == 0) "#1a7f37" else "#bf8700"}">{if (!is.na(m$gp_fails)) m$gp_fails else "N/A"}</div>
        <div class="metric-label">goodpractice failures</div>
      </div>
    </div>

    <!-- Technical debt -->
    <section>
      <h2>&#9203; Technical Debt (SQALE model)</h2>
      <table>
        <thead><tr><th>Category</th><th>Issues</th><th>Estimated Cost</th><th>Share</th></tr></thead>
        <tbody>{debt_rows}</tbody>
      </table>
    </section>

    <!-- Static analysis -->
    <section>
      <h2>&#128270; Static Analysis — lintr ({m$n_lint_issues} issue(s))</h2>
      <table>
        <thead><tr><th>Severity</th><th>File</th><th>Line</th><th>Message</th><th>Rule</th></tr></thead>
        <tbody>{lint_rows}</tbody>
      </table>
    </section>

    <!-- Style -->
    <section>
      <h2>&#9998; Code Style — styler ({m$n_style_issues} non-compliant file(s))</h2>
      <table>
        <thead><tr><th>File</th><th>Status</th></tr></thead>
        <tbody>{style_rows}</tbody>
      </table>
    </section>

  </main>
  <footer>
    Generated by <strong>rsonar</strong> {utils::packageVersion("rsonar")} &nbsp;|&nbsp;
    <a href="https://github.com/ddotta/rsonar">GitHub</a>
  </footer>
</body>
</html>')
}

# Escape HTML characters in messages
htmlEscape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}
