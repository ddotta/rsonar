# Get files changed in working tree

Returns files modified (M) or untracked (?) relative to HEAD.

## Usage

``` r
.git_changed_files(path)
```

## Arguments

- path:

  Project root.

## Value

Character vector of changed file paths relative to `path`.
