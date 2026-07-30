# Fix boolean simplifications

Simplifies common boolean expression patterns:

- `if(x == TRUE)` → `if(x)`, `if(x == FALSE)` → `if(!x)`

- `x == TRUE` → `x`, `x == FALSE` → `!x` (general)

- `isTRUE(x) == TRUE` → `isTRUE(x)`

- `length(x) == 0` → `!length(x)`, `length(x) > 0` → `length(x)`

- `if(x == TRUE && y)` → `if(x && y)`

- `x == FALSE && ...` → `!x && ...`

## Usage

``` r
.fix_simplify(content)
```
