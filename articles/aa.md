# Allocation Assessment

``` r

library(tbeploads)
```

The
[`anlz_aa()`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
function compares mean annual total nitrogen (TN) loads against the
allowable allocations established by the Tampa Bay Nitrogen Management
Consortium (TBNMC) as part of the 5-year Reasonable Assurance (RA)
assessment. Allocations are defined for four source categories:
non-point source / MS4 stormwater (NPS), industrial point source (IPS),
domestic point source (DPS), and material losses (ML). Each category
uses a different method for computing mean loads and, where applicable,
applies hydrologic normalization.

## Required inputs

[`anlz_aa()`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
takes six arguments: the year range, pre-computed load data for each
source, and the `tbbase` spatial lookup table:

``` r

anlz_aa(yrrng, dps_data, ips_data, ml_data, nps_data, tbbase)
```

`yrrng` is an integer vector of length 2 giving the first and last years
of the assessment period. The function internally expands this to a full
sequence using `seq(min, max)`. For example, assessing 2022 to 2024:

``` r

yrrng <- c(2022, 2024)
```

The four load inputs are computed using the corresponding `anlz_*`
functions described in the individual loading vignettes. Each is briefly
described below.

### DPS loads

DPS loads come from
[`anlz_dps_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps_facility.md).
The function requires a vector of file paths to entity data files
provided by TBNMC partners. See the [DPS
vignette](https://tbep-tech.github.io/tbeploads/articles/dps.md) for
full details on the required file format and processing steps.

``` r

fls_dps <- list.files(system.file("extdata/", package = "tbeploads"),
  pattern = "ps_dom_", full.names = TRUE)
dps <- anlz_dps_facility(fls_dps)
head(dps)
```

### IPS loads

IPS loads come from
[`anlz_ips_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips_facility.md).
The function requires a vector of file paths to industrial facility
discharge files. See the [IPS
vignette](https://tbep-tech.github.io/tbeploads/articles/ips.md) for
full details.

``` r

fls_ips <- list.files(system.file("extdata/", package = "tbeploads"),
  pattern = "ps_ind_", full.names = TRUE)
ips <- anlz_ips_facility(fls_ips)
head(ips)
```

### ML loads

Material loss loads come from
[`anlz_ml_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml_facility.md).
The function requires a vector of file paths to material loss data
files. See the [ML
vignette](https://tbep-tech.github.io/tbeploads/articles/ml.md) for full
details.

``` r

fls_ml <- list.files(system.file("extdata/", package = "tbeploads"),
  pattern = "ps_indml", full.names = TRUE)
ml <- anlz_ml_facility(fls_ml)
head(ml)
```

### NPS loads

NPS loads come from
[`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
called with `summ = "basin"` and `summtime = "year"`. This produces
annual basin-level TN and hydrologic loads that
[`anlz_aa()`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
disaggregates to individual MS4 entities. See the [NPS
vignette](https://tbep-tech.github.io/tbeploads/articles/nps.md) for
full details on the required inputs.

``` r

data(tbbase)
data(rain)
data(allwq)
data(allflo)

nps <- anlz_nps(
  yrrng    = c("2022-01-01", "2024-12-31"),
  tbbase   = tbbase,
  rain     = rain,
  allwq    = allwq,
  allflo   = allflo,
  vernafl  = system.file("extdata/verna-raw.csv", package = "tbeploads"),
  summ     = "basin",
  summtime = "year"
)
head(nps)
```

The NPS loads passed to
[`anlz_aa()`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
are not pre-corrected for point-source loads upstream of stream gauges
(unlike
[`anlz_nps_psremove()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_psremove.md));
for gaged basins,
[`anlz_aa()`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
removes the upstream point-source contribution internally before
disaggregating loads to MS4 entities (see below).

## Running the assessment

With all inputs prepared, the assessment is run as:

``` r

data(tbbase)
result <- anlz_aa(c(2022, 2024), dps, ips, ml, nps, tbbase)
head(result)
```

The function returns one row per entity (NPS/MS4) or entity/facility
(IPS, DPS, ML) per bay segment, with the following columns:

| Column | Description |
|----|----|
| `bay_seg` | Integer bay segment (1 = OTB, 2 = HB, 3 = MTB, 4 = LTB, 55 = RALTB) |
| `segment` | Bay segment name |
| `entity` | MS4 entity name or facility operator |
| `entity_full` | Full entity name (NPS rows only) |
| `facname` | Facility name (IPS, DPS, ML rows only) |
| `permit` | NPDES permit number (IPS rows only) |
| `source` | Allocation type (`"MS4"`, `"IPS"`, `"DPS - end of pipe"`, `"DPS - reuse"`, `"ML"`) |
| `alloc_pct` | Fractional TN allocation (0-1) |
| `alloc_tons` | Allowable TN load (tons/yr) |
| `eff_load_tons` | Mean hydrologically-normalized TN load (tons/yr); equals `load_tons` for DPS and ML, and for IPS facilities not flagged `hydro_affected` in `ps_allocations` |
| `load_tons` | Mean annual TN load without normalization (tons/yr) |
| `pass` | `TRUE` if `eff_load_tons <= alloc_tons`, `NA` when either value is missing |

Entities present in the computed loads but absent from the allocation
tables are retained in the output with `NA` allocation fields so that
unmatched entries are visible for troubleshooting.

## Source-specific methodology

### NPS/MS4

Gaged-basin TN loads are gauge-measured totals and so include any
industrial or domestic point-source discharge upstream of the gauge.
Before disaggregation,
[`anlz_aa()`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
subtracts the basin’s IPS and DPS TN loads from gaged-basin totals so
that only the true non-point-source contribution is assigned to MS4
entities. Ungaged-basin TN loads are already non-point-source only,
since the modeled estimate never includes point-source discharge, and
are left unchanged.

The NPS path disaggregates basin-level loads (after the point-source
removal above) to individual MS4 jurisdictions using land use and runoff
coefficient data from `tbbase`. The core disaggregation uses two factors
computed internally by
[`util_aa_npsfactors()`](https://tbep-tech.github.io/tbeploads/reference/util_aa_npsfactors.md):

1.  **`factor_tn`**: each CLUCSID’s share of basin TN load, proportional
    to EMC, area, and runoff coefficient relative to the basin total.
2.  **`factor_rc`**: each entity’s share of a CLUCSID’s load within a
    basin, proportional to entity area times runoff coefficient relative
    to the CLUCSID total.

Agricultural land use (category `"Agriculture"`) is attributed to the
aggregate entity `"All"` regardless of the underlying MS4 jurisdiction.

A conservation land correction is applied before summing across
CLUCSIDs. The `conserv_correction` dataset provides entity- and
CLUCSID-specific fractions of area times runoff coefficient attributable
to conservation land. These fractions are derived from a legacy land
cover file that includes a binary conservation land flag while retaining
the original MS4 jurisdiction for each spatial unit. Each entity’s
disaggregated TN load for a given basin and CLUCSID is scaled by
`(1 - conserv_frac)` to remove the conservation land contribution. The
`tbbase` file herein does not include a conservation land overlay
because the original spatial layer is unavailable for routine GIS
updates, so `conserv_correction` is stored as a separate stable dataset
and applied as a backend correction.

After disaggregation, entity loads and 1992-1994 baseline water volumes
from `hydro_baseline` are summed across basins to the bay segment level.
Corrections from `aa_corrections` (representing atmospheric deposition
and approved project TN adjustments from the 2007 RA analysis) are
subtracted before hydrologic normalization:

``` math
\text{eff\_tn} = (\text{tn\_entity} - \text{corr\_tons}) \times \frac{\text{mean\_h2o\_9294}}{\text{total\_h2o}}
```

`total_h2o` is the annual total basin water load for that basin, gated
by whether the basin is gaged (per `dbasing$gagetype`): for gaged
basins, NPS water is estimated from a stream gauge and so already
reflects any upstream IPS + DPS discharge, so `total_h2o` is the NPS
water alone (adding IPS/DPS water again would double-count it); for
ungaged basins, the modeled NPS-only water excludes point-source
discharge entirely, so IPS and DPS water are added to it to reconstruct
the true total. `mean_h2o_9294` is the 1992-1994 baseline total basin
water volume from `hydro_baseline`. Effective loads are averaged over
`yrrng` as `sum / length(yrrng)`, so missing years contribute zero
rather than being excluded.

Bay segments Terra Ceia Bay (6) and Manatee River (7) are merged into
segment 55 (Remaining Lower Tampa Bay) after disaggregation, consistent
with `hydro_baseline` and TBNMC reporting. Boca Ciega Bay (segment 5) is
excluded from the allocation framework.

### IPS

Raw facility loads are joined to facility metadata on entity + facility
name rather than coastal segment (`coastco`), since several distinct
NPDES permits share a single coastco. Monthly loads are summed to annual
totals per permit and bay segment, averaged over `yrrng`, and compared
against `ps_allocations`.

Hydrologic normalization is applied only to permits flagged
`hydro_affected` in `ps_allocations` (mostly Mosaic mining operations);
every other IPS facility uses its raw (unnormalized) load. For flagged
facilities:

``` math
\text{eff\_tn} = \text{tn\_load} \times \frac{\text{mean\_h2o\_9294}}{\text{basin\_total\_h2o}}
```

where `basin_total_h2o` is the same gaged/ungaged-gated basin water
quantity described in the NPS path above.

### DPS

Domestic point source loads require no hydrologic normalization. Monthly
loads from `dps_data` are summed to annual totals per facility and
averaged over `yrrng`. Boca Ciega Bay (bay_seg = 5) is excluded and bay
segments 6 and 7 are remapped to 55 before joining against
`dps_allocations` for the Remainder Lower Tampa Bay segment. The join
key is entity + facility name + bay segment + source type (end of pipe
or reuse).

### ML

Material loss loads require no hydrologic normalization. Monthly loads
are summed to annual totals per facility and averaged over `yrrng`.
Facilities with `ishared = FALSE` in `ml_allocations` are assessed
individually against their own allocation. Facilities with
`ishared = TRUE` (e.g., Mosaic facilities in Hillsborough Bay) have
their loads summed to an entity + bay segment total before comparison to
a single shared allocation.

## Supporting datasets

The following package datasets support the allocation assessment and are
used internally by
[`anlz_aa()`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md):

| Dataset | Description |
|----|----|
| `nps_allocations` | NPS/MS4 allowable allocations by entity and bay segment |
| `ps_allocations` | IPS allowable allocations by NPDES permit |
| `dps_allocations` | DPS allowable allocations by facility, bay segment, and source type |
| `ml_allocations` | ML allowable allocations by facility and bay segment |
| `hydro_baseline` | 1992-1994 mean annual basin water volumes (million m3/yr) |
| `aa_corrections` | AD and approved project TN corrections per entity and bay segment |
| `conserv_correction` | Conservation land area fractions per entity, basin, and CLUCSID |
