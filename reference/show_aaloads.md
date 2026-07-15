# Bay segment table of TN loads by year

Bay segment table of TN loads by year

## Usage

``` r
show_aaloads(
  aa_data,
  bay_seg,
  gw_data,
  spr_data,
  ad_data,
  yrrng = NULL,
  digits = 1,
  family = "Arial",
  txtsz = 11
)
```

## Arguments

- aa_data:

  data frame returned by
  [`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
  called with `annavg = FALSE`; must contain `year`, `seg_h2o_total`,
  and `seg_conserv_tn` columns.

- bay_seg:

  integer bay segment identifier, one of `1L` (Old Tampa Bay), `2L`
  (Hillsborough Bay), `3L` (Middle Tampa Bay), `4L` (Lower Tampa Bay),
  or `55L` (Remaining Lower Tampa Bay).

- gw_data:

  data frame returned by
  [`anlz_gw`](https://tbep-tech.github.io/tbeploads/reference/anlz_gw.md)
  called with `summtime = 'year'`.

- spr_data:

  data frame returned by
  [`anlz_spr`](https://tbep-tech.github.io/tbeploads/reference/anlz_spr.md)
  called with `summ = 'segment'` and `summtime = 'year'`.

- ad_data:

  data frame returned by
  [`anlz_ad`](https://tbep-tech.github.io/tbeploads/reference/anlz_ad.md)
  called with `summ = 'segment'` and `summtime = 'year'`.

- yrrng:

  optional integer vector of length 2 restricting the displayed years to
  a subset of those already present in `aa_data`. Default `NULL` shows
  all years present.

- digits:

  numeric indicating decimal precision for the year columns. Default
  `1`.

- family:

  chr string indicating font family for text labels

- txtsz:

  numeric indicating font size

## Value

A
[`flextable`](https://davidgohel.github.io/flextable/reference/flextable.html)
object with one row per entity/facility in `bay_seg`, grouped into
bolded sections, and one column per year.

## Details

Rows are grouped into sections using `aa_data`'s own `source` column
rather than replicating the TBNMC partner's combined "Point Sources"
grouping: `"MS4"` (`source` of `"MS4"` or `"Nonpoint Source/MS4"`),
`"IPS"`, `"DPS - end of pipe"`, `"DPS - reuse"`, `"ML"`, and
`"Nonpoint Source"` (the `"All"` (FDACS) and `"Non-MS4/Ag NPS"`
aggregate rows from `aa_data`, plus two rows built from
`gw_data`/`spr_data`/ `ad_data` - see below; other unmatched
`source = NA` rows in `aa_data` are negligible land-use slivers dropped
by
[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
at its 0.01 tons/yr threshold in most years but not all, and are
excluded here rather than shown as a spurious partial row). Each
facility/entity keeps its own row, even for `ishared` shared-allocation
groups (see
[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)).
Row labels combine the owning entity with the facility name
(`"Mosaic - Riverview"`), except when the facility name already
identifies its owner (`"Mosaic - Bartow"`, `"City of Lakeland"`), to
avoid duplicating it; an uninformative `"Point Source - "` prefix on
some `facname` values (`"Point Source - Hopewell"`) is stripped first so
it doesn't end up duplicated in the combined label either.

**Atmospheric Deposition and Other (Groundwater, Springs,
Conservation)**: `gw_data`, `spr_data`, and `ad_data` key on a `segment`
name column rather than `bay_seg`; they are mapped to `bay_seg` the same
way
[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
does internally (Terra Ceia Bay and Manatee River summed into segment
55; Boca Ciega Bay variants dropped, consistent with the allocation
framework's existing exclusion) and filtered to the requested `bay_seg`.
`ad_data`'s `tn_load` becomes the `"Atmospheric Deposition"` row.
`gw_data`'s and `spr_data`'s `tn_load` (`spr_data` only has rows for
Hillsborough Bay - other segments get `0` from it) plus `aa_data`'s
`seg_conserv_tn` (TN removed by the conservation-land correction already
computed inside
[`anlz_aa()`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md),
exposed as a segment total rather than sourced separately) become the
`"Other (Groundwater, Springs, Conservation)"` row. Both are zero-filled
for years with no matching input, same as facility/entity rows.

A facility/entity with a real allocation but no load data for a given
year (or any year at all) is `NA` in `aa_data` by design (see
[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md));
here it displays as `0` rather than blank.

Values shown are always `load_tons` (raw, unnormalized loads), never
`eff_load_tons` - per direct communication with the TBNMC partner, their
draft annual loading tables report unnormalized loads even for
facilities that are hydrologically normalized in the 3-year assessment
table.

A bolded `"Total Load"` row sums every displayed row for each year
(including the AD and Other rows). A bolded `"Normalized Load"` row
below it applies one hydrologic-normalization ratio to the whole
segment's Total Load:

\$\$ \text{Normalized Load} = \text{Total Load} \times
\frac{\text{baseline\\h2o}}{\text{seg\\h2o\\total} +
\text{gw\\hy\\load} + \text{spr\\hy\\load} + \text{ad\\hy\\load}} \$\$

where the denominator is `aa_data`'s `seg_h2o_total` (NPS+IPS+DPS
combined) plus `gw_data`/`spr_data`/`ad_data`'s own `hy_load`, and
`baseline_h2o` is a hardcoded 1992-1994 baseline hydrologic load
(million m3/yr) per bay segment, supplied directly in this function (not
derived from
[`hydro_baseline`](https://tbep-tech.github.io/tbeploads/reference/hydro_baseline.md),
which only covers NPS+IPS+DPS water):

|                                |                   |
|--------------------------------|-------------------|
| **bay\\seg**                   | **baseline\\h2o** |
| 1 (Old Tampa Bay)              | 449.44            |
| 2 (Hillsborough Bay)           | 895.62            |
| 3 (Middle Tampa Bay)           | 645.25            |
| 4 (Lower Tampa Bay)            | 361.19            |
| 55 (Remaining Lower Tampa Bay) | 422.709           |

These were extracted directly from the "Normalized Load" cell formula
(`=C6*<baseline>/<total_h2o>`, e.g. `=C6*895.62/1060.477` for
Hillsborough Bay 2022) in the TBNMC partner's draft annual loading
workbooks (`data-raw/misc/draftload/*.xlsx` in `tbeploadsproc`), by
unzipping each `.xlsx` and reading the formula (not just the computed
value) out of the underlying sheet XML - not the "TMDL" figure in each
sheet's title (e.g. "HILLSBOROUGH BAY: TMDL 1451"), which is a different
quantity (the TN mass threshold used for pass/fail comparison, unrelated
to this hydrologic ratio). This whole-segment-ratio approach (rather
than summing each entity's own `eff_load_tons`) was validated against
real 2022-2024 Hillsborough Bay data before these values were found: it
reproduced a nearly constant implied baseline across all three years,
unlike per-entity-based alternatives that varied by 3-4x year to year -
and with the real value now in hand (895.62), the same formula's
`"Other (Groundwater, Springs, Conservation)"` breakdown in that
workbook (`=20.726327+133.700005+65.7377066` for 2022) confirms the
`seg_conserv_tn` figure exposed by
[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
independently (65.4 tons computed here vs. 65.74 tons in the workbook
for that year).

An additional `"Average"` column, appended after the year columns, gives
each row's own mean across the displayed years (a row-wise average, not
a column summary); it is not computed for `"Normalized Load"`
differently than any other row.

This is a first-pass approximation of the TBNMC partner's draft annual
loading workbooks - exact reproduction of RP's reported numbers is not
guaranteed, only a close approximation.

## Examples

``` r
if (FALSE) { # \dontrun{
aa_data <- anlz_aa(c(2022, 2024), dps, ips, ml, nps, tbbase, annavg = FALSE)
gw_data <- anlz_gw(contdry, contwet, yrrng = c(2022, 2024), summtime = 'year')
spr_data <- anlz_spr(tbwxlpth, wqpth, yrrng = c(2022, 2024),
  summ = 'segment', summtime = 'year')
ad_data <- anlz_ad(rain, vernafl, summ = 'segment', summtime = 'year')
show_aaloads(aa_data, bay_seg = 2L, gw_data, spr_data, ad_data)
} # }
```
