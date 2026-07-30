# Understanding and Reducing Technical Debt

## What is technical debt?

**Technical debt** is the cost of additional work caused by shortcuts in
the code: quick fixes, untested code, poor naming, unnecessary
complexity. Like financial debt, it accumulates interest if not repaid.

`rsonar` quantifies this debt in **estimated remediation minutes**,
using the **SQALE** (Software Quality Assessment based on Lifecycle
Expectations) model used by SonarQube.

------------------------------------------------------------------------

## The SQALE Model in rsonar

### Debt calculation

The total debt is the sum of costs per category:

``` math
D_{total} = D_{lint\_err} + D_{lint\_warn} + D_{style} + D_{coverage} + D_{gp}
```

With default costs:

| Category                           | Default unit cost |
|------------------------------------|-------------------|
| Lint error (`error`)               | 30 min            |
| Lint warning (`warning`)           | 10 min            |
| Lint style violation               | 2 min             |
| Improperly formatted file (styler) | 5 min             |
| Goodpractice failure               | 20 min            |
| Missing coverage point             | 5 min/point       |

### SQALE rating calculation

The rating is computed from the **debt-to-base-effort ratio**:

``` math
ratio = \frac{D_{total}}{N_{files} \times 30 \text{ min}}
```

| Ratio  | Rating | Meaning            |
|--------|--------|--------------------|
| \< 5%  | **A**  | Excellent quality  |
| 5–10%  | **B**  | Good quality       |
| 10–20% | **C**  | Acceptable quality |
| 20–50% | **D**  | Poor quality       |
| \> 50% | **E**  | Critical           |

[`quality_score()`](https://ddotta.github.io/rsonar/reference/quality_score.md)
exposes the same debt ratio as an easy-to-read percentage for IDE usage:

``` math
score = 100 \times (1 - min(1, ratio))
```

------------------------------------------------------------------------

## Example analysis

``` r

library(rsonar)

res  <- sonar_analyse(".")
debt <- debt_index(res)
print(debt)

# Fast local score shown in IDE
quality_score(res)
```

    ── rsonar Technical Debt ───────────────────────────────────
    ℹ Estimated duration: 2.17h (130 min)
    ℹ SQALE rating: C

    ── Breakdown by category ────────────────────────────────────
                 category issues minutes
    1      Lint (errors)      2      60
    2     Lint (warnings)     4      40
    3     Best practices      1      20
    4          Coverage       2      10

------------------------------------------------------------------------

## Customizing costs

Default costs can be adjusted to match your organization’s context:

``` r

# Stricter costs for a critical project
debt <- debt_index(res,
  cost_lint_error     = 60,   # 1h per error
  cost_lint_warning   = 15,
  cost_style          = 10,
  cost_gp             = 30,
  coverage_target     = 90,   # Target: 90%
  cost_coverage_point = 8
)
```

------------------------------------------------------------------------

## Remediation strategy

### Prioritization: which files to fix first

The category breakdown above (`debt$breakdown`) tells you *what kind* of
debt dominates your project — but not *where* it lives. To know which
files to open first, use
[`sonar_hotspots()`](https://ddotta.github.io/rsonar/reference/sonar_hotspots.md),
which ranks files by their individual estimated remediation cost:

``` r

hotspots <- sonar_hotspots(res, n = 10)
print(hotspots)
```

    ── rsonar Hotspots — Files to Fix First ──────────────────────
    1. R/legacy_module.R — 145 min (2 error(s), 3 warning(s), 4 style lint(s), needs re-format, coverage 42%)
    2. R/utils.R — 60 min (0 error(s), 3 warning(s), 4 style lint(s))
    3. R/helpers.R — 20 min (0 error(s), 1 warning(s), 0 style lint(s))

This is the same logic as SonarQube’s “Code Smells” hotspots view:
instead of asking “how much debt do we have in total?”, it answers
“which single file, if fixed today, reduces the debt the most?” — a much
more actionable question when onboarding a new contributor or triaging a
legacy codebase.

[`sonar_hotspots()`](https://ddotta.github.io/rsonar/reference/sonar_hotspots.md)
accepts the same cost arguments as
[`debt_index()`](https://ddotta.github.io/rsonar/reference/debt_index.md),
so you can apply your organization’s custom weighting consistently
across both the global score and the per-file ranking:

``` r

sonar_hotspots(res,
  n = 5,
  cost_lint_error   = 60,
  cost_lint_warning = 15,
  cost_style        = 10
)
```

The ranking is also included automatically in the HTML report generated
by
[`sonar_report()`](https://ddotta.github.io/rsonar/reference/sonar_report.md),
right after the Technical Debt summary.

### Return on investment by category

The category breakdown remains useful to decide *what kind* of
remediation to invest in first — for example, prioritizing lint errors
(30 min each by default) over style violations (2 min each):

``` r

debt <- debt_index(res)

# Display categories with the most debt
breakdown <- debt$breakdown[order(-debt$breakdown$minutes), ]
print(breakdown)
```

Combine both views: use the category breakdown to decide *what* to fix
first (e.g. “errors before style”), and
[`sonar_hotspots()`](https://ddotta.github.io/rsonar/reference/sonar_hotspots.md)
to decide *where* — which files concentrate that category of debt.

### Progressive approach (legacy debt)

For an existing project with a lot of debt, adopt an incremental
approach:

``` r

# Week 1: fix lint errors (highest impact)
# Week 2: add tests to increase coverage
# Week 3: reformat the code (styler::style_dir)
# Week 4: address warnings and goodpractice

# Track debt evolution over time
debt_week_1  <- debt_index(res_before)$minutes
debt_week_4  <- debt_index(res_after)$minutes
reduction_pct <- round(100 * (1 - debt_week_4 / debt_week_1), 1)
cat("Debt reduction:", reduction_pct, "%\n")
```

------------------------------------------------------------------------

## Comparing analyses with sonar_diff()

Use
[`sonar_diff()`](https://ddotta.github.io/rsonar/reference/sonar_diff.md)
to see exactly what changed between two analysis runs:

``` r

baseline <- sonar_analyse(".")
# ... make improvements ...
current  <- sonar_analyse(".")
diff     <- sonar_diff(current, baseline)
print(diff)
```

This shows delta metrics, new issues introduced, and issues fixed.

------------------------------------------------------------------------

## Trend tracking in CI

### Using sonar_trend()

[`sonar_trend()`](https://ddotta.github.io/rsonar/reference/sonar_trend.md)
appends each analysis to a JSON history file, making it easy to monitor
quality evolution across builds:

``` r

res <- sonar_analyse(".")
sonar_trend(res, file = "rsonar-history.json")
```

In your `.gitlab-ci.yml`:

``` yaml
rsonar-report:
  stage: report
  when: always
  script:
    - |
      Rscript -e "
      library(rsonar)
      res <- sonar_analyse('.')
      sonar_trend(res)
      sonar_report(res, output='rsonar-report.html', open=FALSE)
      "
  artifacts:
    paths:
      - rsonar-report.html
      - rsonar-history.json
    expire_in: 4 weeks
```

### GitLab — rating as a metric

In your `.gitlab-ci.yml`, expose the rating as a metric:

``` yaml
rsonar-metrics:
  script:
    - |
      Rscript -e "
      library(rsonar)
      res  <- sonar_analyse('.')
      debt <- debt_index(res)
      cat('SQALE rating:', debt\$rating, '\n')
      cat('Debt minutes:', debt\$minutes, '\n')
      # Fail if rating is D or E
      if (debt\$rating %in% c('D', 'E'))
        stop('Insufficient SQALE rating: ', debt\$rating)
      "
```

------------------------------------------------------------------------

## Best practices for maintaining low debt

1.  **Configure `.lintr`** from the start of the project with
    [`use_rsonar_lintr()`](https://ddotta.github.io/rsonar/reference/use_rsonar_lintr.md)
2.  **Format systematically** before each commit:
    `styler::style_dir("R")`
3.  **Write tests alongside code**, not after
4.  **Block regressions** in CI with
    `quality_gate(fail_on_error = TRUE)`
5.  **Don’t accumulate commented code** — use Git history
6.  **Name clearly** functions and variables —
    `object_length_linter(30)`

> The best way to manage technical debt is not to accumulate it.
