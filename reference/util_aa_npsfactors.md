# Create NPS disaggregation factors for allocation assessment

Create NPS disaggregation factors for allocation assessment

## Usage

``` r
util_aa_npsfactors(tbbase, rcclucsid, emc)
```

## Arguments

- tbbase:

  Data frame returned from
  [`util_nps_tbbase`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)
  containing land use, soils, and jurisdiction data. Must include
  columns `bay_seg`, `basin`, `drnfeat`, `entity`, `CLUCSID`, `hydgrp`,
  and `area_ha`.

- rcclucsid:

  Data frame of runoff coefficients by land use class and hydrologic
  soil group. See
  [`rcclucsid`](https://tbep-tech.github.io/tbeploads/reference/rcclucsid.md).

- emc:

  Data frame of event mean concentrations by land use class. Must
  include columns `clucsid` and `mean_tn`. See
  [`emc`](https://tbep-tech.github.io/tbeploads/reference/emc.md).

## Value

A named list with two elements:

- rc:

  Data frame of RC factors: `bay_seg`, `basin`, `entity`, `category`,
  `clucsid`, `factor_rc`. `factor_rc` is each entity's fractional share
  of the weighted area × runoff coefficient within each basin × CLUCSID
  combination. Sums to 1 across all entities for each basin × CLUCSID.

- tn:

  Data frame of TN factors: `bay_seg`, `basin`, `clucsid`, `factor_tn`.
  `factor_tn` is each CLUCSID's fractional share of basin TN load,
  weighted by area × event mean TN concentration. Sums to 1 across all
  CLUCSIDs for each basin.

## Details

These factors are used by `anlz_aa` to disaggregate basin-level NPS
loads to individual MS4 jurisdictions (entities).

Two factors are required because the disaggregation is a two-step
process matching the original SAS workflow:

- TN factor (`factor_tn`):

  Distributes total basin TN load among land use classes. Based on area
  × event mean TN concentration per CLUCSID. Jurisdiction is not
  required, sums to basin total.

- RC factor (`factor_rc`):

  Distributes each land use class's TN and water loads among MS4
  entities based on each entity's share of that land use type's weighted
  runoff (area × runoff coefficient). Jurisdiction is required here,
  i.e., `tbbase` includes the entity overlay.

Annual runoff coefficient: `rc = (dry_rc * 8 + wet_rc * 4) / 12`.

Basin remapping matches the SAS preprocessing: nested basins 02303000
and 02303330 are assigned to 02304500; 02301000 and 02301300 to
02301500; 02299950 to LMANATEE; basin 206-5 is assigned to bay_seg 55.
Basin 02307359 is excluded entirely.

Non-contributing drainage features (`drnfeat == "NONCON"`) and
water/tidal CLUCSIDs (17, 21, 22) are excluded from both factors.

Compound hydrologic soil groups (e.g., `"A/D"`) are simplified to their
primary group (`"A"`) before joining runoff coefficients.

These factors are specific to a land use layer and should be rebuilt
whenever the underlying `tbbase` changes.

## Examples

``` r
data(tbbase)
data(rcclucsid)
data(emc)
nps_factors <- util_aa_npsfactors(tbbase, rcclucsid, emc)
```
