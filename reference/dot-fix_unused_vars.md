# Fix unused variables - detect and remove assignments never read

Scans a file for variable assignments via `<-` or `=` and removes lines
where the assigned variable is never referenced elsewhere. Uses
conservative heuristics to avoid false positives:

- Only considers top-level assignments (not inside functions or control
  flow)

- Skips variables with names shorter than 3 chars

- Skips common names that may be used by other tools (e.g., `.`, `i`,
  `j`)

- Skips variables assigned from function calls (may have side effects)

- Skips lines containing `<<-` (super-assignment, visible elsewhere)

## Usage

``` r
.fix_unused_vars(content)
```
