# tbeploads — Claude Code project instructions

## R CMD check: non-ASCII characters

Do **not** use literal non-ASCII characters (e.g. `→`, `–`, `×`, typographic
quotes) in:

- **roxygen comments** (`#'`) — they end up in `.Rd` files and trigger
  `Warning: found non-ASCII strings in documentation`.
- **Regular code comments** (`#`) — they trigger
  `Warning: non-ASCII characters in R source file`.

### Allowed alternatives

| Instead of | Use in roxygen | Use in code comments |
|------------|---------------|---------------------|
| `→` (right arrow) | `\u{2192}` (Rd unicode escape) | `->` |
| `–` (en-dash)     | `--` | `--` |
| `×` (multiply)    | `x` or `*` | `x` or `*` |
| `≥` / `≤`         | `>=` / `<=` | `>=` / `<=` |

The Rd unicode escape syntax is `\u{XXXX}` (4-digit hex) inside a roxygen
comment; it renders correctly in both HTML and PDF help.  Do **not** use the
R-string escape `\uXXXX` (without braces) — that is for character literals
inside R code, not Rd markup.
