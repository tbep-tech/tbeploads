# Allocation assessment for DPS, IPS, and NPS/MS4 entities

Allocation assessment for DPS, IPS, and NPS/MS4 entities

## Usage

``` r
anlz_aa(yrrng, dps_data, ips_data, nps_data, tbbase, corrections)
```

## Arguments

- yrrng:

  Integer vector of years to include, e.g., `2022:2024`.

- dps_data:

  Data frame from
  [`anlz_dps_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps_facility.md).
  Required columns: `Year`, `Month`, `entity`, `facility`, `coastco`,
  `tn_load`.

- ips_data:

  Data frame from
  [`anlz_ips_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips_facility.md).
  Required columns: `Year`, `Month`, `entity`, `facility`, `coastco`,
  `tn_load`.

- nps_data:

  Data frame from
  [`anlz_nps`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
  called with `summ = 'basin'` and `summtime = 'year'`. Required
  columns: `Year`, `source`, `segment`, `basin`, `tn_load`, `hy_load`.

- tbbase:

  data frame containing polygon areas for the combined data layer of bay
  segment, basin, jurisdiction, land use data, and soils, see details

- corrections:

  Data frame with columns `bay_seg`, `entity`, `ad_tons`, and
  `project_tons`. Use
  [`aa_corrections`](https://tbep-tech.github.io/tbeploads/reference/aa_corrections.md)
  as a zero-row placeholder when actual corrections are not yet
  available.

## Value

A data frame with one row per entity (NPS/MS4) or facility (IPS) per bay
segment:

- bay_seg:

  Integer bay segment identifier

- segment:

  Bay segment name

- entity:

  MS4 entity name or IPS operator name

- entity_full:

  Full entity name from
  [`nps_allocations`](https://tbep-tech.github.io/tbeploads/reference/nps_allocations.md)
  (NPS rows only)

- facname:

  Facility name (IPS rows only)

- permit:

  NPDES permit number (IPS rows only)

- source:

  Allocation type: `"MS4"`, `"Nonpoint Source/MS4"`, `"IPS"`,
  `"DPS - end of pipe"`, or `"DPS - reuse"`

- alloc_pct:

  Fractional TN allocation (0-1)

- alloc_tons:

  Allocation in TN tons per year

- eff_load_tons:

  Mean hydrologically-normalized TN load (tons/yr), averaged over
  `yrrng`

- pass:

  Logical: `eff_load_tons <= alloc_tons`; `NA` when allocation or
  effective load is missing

## Details

Entities present in the computed loads but absent from the allocation
tables are retained in the output with `NA` allocation fields so that
unmatched entries are visible for troubleshooting.

**DPS path**

DPS facility TN loads require no hydrologic normalization. Monthly loads
from `dps_data` are summed to annual totals per facility, averaged over
`yrrng`, and compared directly against the
[`dps_allocations`](https://tbep-tech.github.io/tbeploads/reference/dps_allocations.md)
table. The join key is `entity + facname + bay\_seg + source`, where
`source` distinguishes direct surface water discharge
(`"DPS - end of pipe"`) from reclaimed water reuse (`"DPS - reuse"`).
Bay segment 5 (Boca Ciega Bay) is excluded and bayseg 6/7 are remapped
to 55.

**IPS path**

Annual IPS facility TN loads are normalized using the ratio:

\$\$ \text{eff\\tn} = \text{tn\\load} \times
\frac{\text{mean\\h2o\\9294}}{\text{basin\\nps\\h2o}} \$\$

where `basin\_nps\_h2o` is the annual NPS water load from `nps_data` for
the same basin and year. Effective loads are summed across basins per
permit per bay segment, then averaged over `yrrng`.

**NPS/MS4 path**

Basin-level NPS loads from `nps_data` are disaggregated to individual
MS4 entities using the output (created internally) from
[`util_aa_npsfactors`](https://tbep-tech.github.io/tbeploads/reference/util_aa_npsfactors.md)
that combines
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md),
[`rcclucsid`](https://tbep-tech.github.io/tbeploads/reference/rcclucsid.md),
and [`emc`](https://tbep-tech.github.io/tbeploads/reference/emc.md)
into:

1.  `factor_tn` distributes basin TN load among land use classes.

2.  `factor_rc` distributes each land use class's load among entities
    proportional to area × runoff coefficient.

Agricultural land use (category `"Agriculture"`) is attributed to the
aggregate entity `"All"` regardless of the underlying MS4 jurisdiction.

After disaggregation, loads and 1992-1994 baseline water volumes are
summed across basins to the segment level. TN corrections (`ad_tons` +
`project_tons`) are subtracted before hydrologic normalization:

\$\$ \text{eff\\tn} = (\text{tn\\entity} - \text{corr\\tons}) \times
\frac{\text{mean\\h2o\\9294}}{\text{h2o\\entity}} \$\$

Bay segments Terra Ceia Bay (6) and Manatee River (7) are merged into
segment 55 (Remaining Lower Tampa Bay) after disaggregation, consistent
with the
[`hydro_baseline`](https://tbep-tech.github.io/tbeploads/reference/hydro_baseline.md)
encoding and TBNMC reporting. Boca Ciega Bay (segment 5) is excluded
from the allocation framework.

## Examples

``` r
if (FALSE) { # \dontrun{
nps <- anlz_nps(
  yrrng  = c("2022-01-01", "2024-12-31"),
  tbbase = tbbase,
  rain   = rain,
  allwq  = allwq,
  allflo = allflo,
  vernafl = system.file("extdata/verna-raw.csv", package = "tbeploads"),
  summ     = "basin",
  summtime = "year"
)
fls_ips <- list.files(system.file("extdata/", package = "tbeploads"),
  pattern = "ps_ind_", full.names = TRUE)
fls_dps <- list.files(system.file("extdata/", package = "tbeploads"),
  pattern = "ps_dom_", full.names = TRUE)
ips <- anlz_ips_facility(fls_ips)
dps <- anlz_dps_facility(fls_dps)
anlz_aa(2022:2024, dps, ips, nps, tbbase, aa_corrections)
} # }
```
