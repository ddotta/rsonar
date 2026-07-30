# Fix duplicate library() calls - remove duplicate library() statements

Scans a file for repeated
[`library()`](https://rdrr.io/r/base/library.html) calls loading the
same package and removes duplicate occurrences, keeping only the first
one.

## Usage

``` r
.fix_duplicate_libs(content)
```
