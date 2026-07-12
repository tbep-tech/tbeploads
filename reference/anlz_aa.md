# Allocation assessment for DPS, IPS, and NPS/MS4 entities

Allocation assessment for DPS, IPS, and NPS/MS4 entities

## Usage

``` r
anlz_aa(yrrng, dps_data, ips_data, ml_data, nps_data, tbbase, verbose = FALSE)
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
  For gaged basins these are gauge-measured totals that include upstream
  point-source discharge; `anlz_aa` removes the IPS/DPS contribution
  from `tn_load` internally before disaggregating to MS4 entities (see
  Details).

- tbbase:

  data frame containing polygon areas for the combined data layer of bay
  segment, basin, jurisdiction, land use data, and soils, see details

- verbose:

  logical, if `TRUE` print a message reporting negligible unmatched
  NPS/MS4 entities dropped from the output (see Details). Default
  `FALSE`.

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
unmatched entries are visible for troubleshooting, with one exception:
unmatched NPS/MS4 entities with a mean annual load under 0.01 tons/yr
are dropped, since these are negligible land-use polygon artifacts (e.g.
land in
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md)
not attributed to any jurisdiction, or a jurisdiction's boundary
crossing into an adjacent basin/segment where it has no allocation)
rather than real troubleshooting signal. When `verbose = TRUE`, a
message reports what was dropped and why.

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
averaged over `yrrng`. Hydrologic normalization is applied only to IPS
facilities flagged `hydro_affected` in
[`ps_allocations`](https://tbep-tech.github.io/tbeploads/reference/ps_allocations.md)
(mostly Mosaic mining operations); all other facilities use their raw
(unnormalized) load. For `hydro_affected` permits:

\$\$ \text{eff\\tn} = \text{tn\\load} \times
\frac{\text{mean\\h2o\\9294}}{\text{basin\\total\\h2o}} \$\$

where `basin\_total\_h2o` is the annual total basin water load for the
same basin and year, computed differently depending on whether the basin
is gaged (per
[`dbasing`](https://tbep-tech.github.io/tbeploads/reference/dbasing.md)):
for gaged basins, NPS water is estimated from a stream gauge and so
already reflects any upstream IPS + DPS discharge, so
`basin\_total\_h2o` is the NPS water alone (adding IPS/DPS water again
would double-count it); for ungaged basins, the modeled NPS-only water
excludes point-source discharge entirely, so IPS and DPS water are added
to it to reconstruct the true total. All other IPS facilities, and any
facility with no `ps_allocations` match, use the raw (unnormalized)
load.

Permits with a real
[`ps_allocations`](https://tbep-tech.github.io/tbeploads/reference/ps_allocations.md)
entry but no current `ips_data` (permanently closed facilities) still
receive their known `bay_seg` from `facilities` where available, so they
appear in the output with `NA` loads but a real bay segment rather than
`NA` throughout.

**ML path**

Material loss TN loads require no hydrologic normalization. Monthly
loads from `ml_data` are summed to annual totals per facility, averaged
over `yrrng`, and compared against the
[`ml_allocations`](https://tbep-tech.github.io/tbeploads/reference/ml_allocations.md)
table. Facilities with `ishared = FALSE` are assessed individually on
entity + facname + bay segment. Facilities with `ishared = TRUE` (the
three Mosaic facilities in Hillsborough Bay, and Kinder Morgan Port
Sutton + Tampaplex, also in Hillsborough Bay) have their loads summed to
an entity + bay segment total before comparison to the single shared
allocation.

**NPS/MS4 path**

Gaged-basin TN loads in `nps_data` are gauge-measured totals and so
include any upstream IPS + DPS discharge in that basin. Before
disaggregation, `anlz_aa` subtracts the basin's IPS and DPS TN loads
from gaged-basin `tn_load` so that only the true non-point-source
contribution is assigned to MS4 entities. Ungaged-basin `tn_load` is
already NPS-only (the modeled estimate never includes point-source
discharge) and is left unchanged. Basin-level NPS loads
(post-correction) are disaggregated to individual MS4 entities using the
output (created internally) from
[`util_aa_npsfactors`](https://tbep-tech.github.io/tbeploads/reference/util_aa_npsfactors.md)
that combines
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md),
[`rcclucsid`](https://tbep-tech.github.io/tbeploads/reference/rcclucsid.md),
and [`emc`](https://tbep-tech.github.io/tbeploads/reference/emc.md)
into:

1.  `factor_tn` distributes basin TN load among land use classes.

2.  `factor_rc` distributes each land use class's load among entities
    proportional to area × runoff coefficient.

Before summing across CLUCSIDs, each entity's disaggregated TN load is
scaled by `(1 - conserv\_frac)` using
[`conserv_correction`](https://tbep-tech.github.io/tbeploads/reference/conserv_correction.md),
which provides entity- and CLUCSID-specific fractions of area times
runoff coefficient attributable to conservation land. This removes the
conservation land contribution that is absent from the tbeploads-built
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md),
and is applied using the true underlying MS4 jurisdiction since
conservation land can occur within Agriculture-classified parcels too.

Only after this correction is agricultural land use (category
`"Agriculture"`) attributed to the aggregate entity `"All"` regardless
of the underlying MS4 jurisdiction. Land under a Municipal Separate
storm sewer Generic Permit (entities `"MSGP COT"` and `"MSGP PINELLAS"`
in
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md))
is not part of any individually-tracked MS4 jurisdiction and is
aggregated the same way to entity `"Non-MS4/Ag NPS"`, matching the row
label used in the TBNMC draft loading tables. `"PORT MANATEE"`'s
footprint spans both Middle Tampa Bay (`bay_seg` 3) and Lower Tampa Bay
(`bay_seg` 4), so it also folds into this aggregate in both segments;
Lower Tampa Bay has no other MSGP entities, so Port Manatee is its sole
contributor.

After disaggregation, loads and 1992-1994 baseline water volumes are
summed across basins to the segment level. TN corrections from
[`aa_corrections`](https://tbep-tech.github.io/tbeploads/reference/aa_corrections.md)
(`ad_tons` + `project_tons`) are subtracted before hydrologic
normalization:

\$\$ \text{eff\\tn} = (\text{tn\\entity} - \text{corr\\tons}) \times
\frac{\text{mean\\h2o\\9294}}{\text{total\\h2o}} \$\$

`total_h2o` is the same gaged/ungaged-gated basin water quantity
described in the IPS path below (NPS water alone for gaged basins; NPS +
IPS + DPS for ungaged basins).

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
