# Bay segment table of allocation assessment by entity and facility

Bay segment table of allocation assessment by entity and facility

## Usage

``` r
show_aaassess(aa_data, bay_seg, digits = 1, family = "Arial", txtsz = 11)
```

## Arguments

- aa_data:

  data frame returned by
  [`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
  called with `annavg = TRUE`

- bay_seg:

  integer bay segment identifier, one of `1` (Old Tampa Bay), `2`
  (Hillsborough Bay), `3` (Middle Tampa Bay), `4` (Lower Tampa Bay), or
  `55` (Remaining Lower Tampa Bay).

- digits:

  numeric indicating decimal precision for the Allocated Tons and
  Effective Load columns. Default `1`. Allocation % is always shown to
  two decimal places with a percent sign, independent of `digits`.

- family:

  chr string indicating font family for text labels

- txtsz:

  numeric indicating font size

## Value

A
[`flextable`](https://davidgohel.github.io/flextable/reference/flextable.html)
object with one row per facility/source nested under its owning entity,
and a bolded "Total" row for any entity with more than one
facility/source in `bay_seg`.

## Details

Rows are organized by **Entity**. An entity's block gathers every row
that applies to it in `bay_seg` regardless of `source` (e.g. an entity
with both IPS and Material Losses facilities gets one combined block and
one combined Total).

**Facility column**: The displayed `Facility` text combines `facname`
and `source`: IPS rows show `facname` as-is; DPS rows append
`" (end of pipe)"` or `" (reuse)"`; Material Losses rows append
`" (Material Losses)"`; MS4 rows (no `facname`) show `"MS4"`.

**Entity Total row**: a "unit" is either one shared group or one
standalone facility/entity row. An entity gets a bolded `"Total"` row
when it has more than one unit (regardless of how many display rows
those units span), summing `alloc_tons`/`eff_load_tons` once per unit.
Entities with exactly one unit (every MS4 row, and any entity with only
one facility) get no Total row. Allocation % is left blank on the Total
row.

## Examples

``` r
if (FALSE) { # \dontrun{
aa_data <- anlz_aa(c(2022, 2024), dps, ips, ml, nps, tbbase)
show_aaassess(aa_data, bay_seg = 2L)
} # }
```
