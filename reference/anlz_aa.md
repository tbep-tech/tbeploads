# Allocation assessment for DPS, IPS, and NPS/MS4 entities

Allocation assessment for DPS, IPS, and NPS/MS4 entities

## Usage

``` r
anlz_aa(yrrng, dps_data, ips_data, ml_data, nps_data, tbbase)
```

## Arguments

- yrrng:

  Integer vector of length 2, start and end year, e.g., `c(2022, 2024)`.

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

- ml_data:

  Data frame from
  [`anlz_ml_facility`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml_facility.md).
  Required columns: `Year`, `Month`, `entity`, `facility`, `tn_load`.

- nps_data:

  Data frame from
  [`anlz_nps`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
  called with `summ = 'basin'` and `summtime = 'year'`. Required
  columns: `Year`, `source`, `segment`, `basin`, `tn_load`, `hy_load`.
  TN loads represent NPS contributions only and are not corrected for
  point-source loads.

- tbbase:

  data frame containing polygon areas for the combined data layer of bay
  segment, basin, jurisdiction, land use data, and soils, see details

## Value

A data frame with one row per entity (NPS/MS4) or facility (IPS) per bay
segment:

- bay_seg:

  Integer bay segment identifier

- segment:

  Bay segment name

- entity:

  MS4 entity name or facility operator

- entity_full:

  Full entity name from
  [`nps_allocations`](https://tbep-tech.github.io/tbeploads/reference/nps_allocations.md)
  (NPS rows only)

- facname:

  Facility name (IPS, DPS, and non-shared ML rows)

- permit:

  NPDES permit number (IPS rows only)

- source:

  Allocation type: `"MS4"`, `"Nonpoint Source/MS4"`, `"IPS"`,
  `"DPS - end of pipe"`, `"DPS - reuse"`, or `"ML"`

- alloc_pct:

  Fractional TN allocation (0-1)

- alloc_tons:

  Allocation in TN tons per year

- eff_load_tons:

  Mean hydrologically-normalized TN load (tons/yr), averaged over
  `yrrng`; equals `load_tons` for DPS and ML (no normalization applied)
  and for IPS facilities not flagged `hydro_affected` in
  [`ps_allocations`](https://tbep-tech.github.io/tbeploads/reference/ps_allocations.md).
  NPS/MS4 rows and `hydro_affected` IPS facilities are normalized

- load_tons:

  Mean annual TN load (tons/yr) without hydrologic normalization,
  averaged over `yrrng`

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

Raw facility loads are joined to facility metadata on `entity + facname`
(not `coastco`), since several distinct permits share a single coastco.
Monthly loads are summed to annual totals per permit per bay segment and
averaged over `yrrng`, matching RP's own draft TN-loading tables, which
apply hydrologic normalization to only a subset of IPS facilities
(mostly Mosaic mining operations, flagged via the `hydro_affected`
column added to
[`ps_allocations`](https://tbep-tech.github.io/tbeploads/reference/ps_allocations.md))
and leave the rest unnormalized. For `hydro_affected` permits:

\$\$ \text{eff\\tn} = \text{tn\\load} \times
\frac{\text{mean\\h2o\\9294}}{\text{basin\\total\\h2o}} \$\$

where `basin\_total\_h2o` is the annual total water load (NPS + DPS +
IPS) for the same basin and year, matching the SAS `ratio1\_2224`
denominator. All other IPS facilities, and any facility with no
`ps_allocations` match, use the raw (unnormalized) load.

**ML path**

Material loss TN loads require no hydrologic normalization. Monthly
loads from `ml_data` are summed to annual totals per facility, averaged
over `yrrng`, and compared against the
[`ml_allocations`](https://tbep-tech.github.io/tbeploads/reference/ml_allocations.md)
table. Facilities with `ishared = FALSE` are assessed individually on
entity + facname + bay segment. Facilities with `ishared = TRUE`
(currently the three Mosaic facilities in Hillsborough Bay) have their
loads summed to an entity + bay segment total before comparison to the
single shared allocation.

**NPS/MS4 path**

TN loads in `nps_data` are NPS-only; no point-source correction is
applied to the input loads. Basin-level NPS loads are disaggregated to
individual MS4 entities using the output (created internally) from
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

Before summing across CLUCSIDs, each entity's disaggregated TN load is
scaled by `(1 - conserv\_frac)` using
[`conserv_correction`](https://tbep-tech.github.io/tbeploads/reference/conserv_correction.md),
which provides entity- and CLUCSID-specific fractions of area times
runoff coefficient attributable to conservation land. This removes the
conservation land contribution that is absent from the tbeploads-built
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md).

After disaggregation, loads and 1992-1994 baseline water volumes are
summed across basins to the segment level. TN corrections from
[`aa_corrections`](https://tbep-tech.github.io/tbeploads/reference/aa_corrections.md)
(`ad_tons` + `project_tons`) are subtracted before hydrologic
normalization:

\$\$ \text{eff\\tn} = (\text{tn\\entity} - \text{corr\\tons}) \times
\frac{\text{mean\\h2o\\9294}}{\text{total\\h2o}} \$\$

Bay segments Terra Ceia Bay (6) and Manatee River (7) are merged into
segment 55 (Remaining Lower Tampa Bay) after disaggregation, consistent
with the
[`hydro_baseline`](https://tbep-tech.github.io/tbeploads/reference/hydro_baseline.md)
encoding and TBNMC reporting. Boca Ciega Bay (segment 5) is excluded
from the allocation framework.

## Examples

``` r
if (FALSE) { # \dontrun{
fls_dps <- list.files(system.file("extdata/", package = "tbeploads"),
  pattern = "ps_dom_", full.names = TRUE)
dps <- anlz_dps_facility(fls_dps)
fls_ips <- list.files(system.file("extdata/", package = "tbeploads"),
  pattern = "ps_ind_", full.names = TRUE)
ips <- anlz_ips_facility(fls_ips)
fls_ml <- list.files(system.file("extdata/", package = "tbeploads"),
  pattern = "ps_indml", full.names = TRUE)
ml <- anlz_ml_facility(fls_ml)
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

anlz_aa(c(2022, 2024), dps, ips, ml, nps, tbbase)
} # }
```
