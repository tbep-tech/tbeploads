# Conservation land correction fractions for NPS/MS4 allocation assessment

Conservation land correction fractions for NPS/MS4 allocation assessment

## Usage

``` r
conserv_correction
```

## Format

A data frame with one row per unique bay segment, basin, entity, and
CLUCSID combination where conservation land is present:

- bay_seg:

  Integer bay segment identifier (1 = OTB, 2 = HB, 3 = MTB, 4 = LTB, 55
  = RALTB).

- basin:

  Character drainage basin identifier.

- entity:

  MS4 jurisdiction name.

- clucsid:

  Integer Coastal Land Use Classification System identifier.

- conserv_frac:

  Fraction of entity area x runoff-coefficient attributable to
  conservation land within that bay segment / basin / CLUCSID
  combination. Computed as conservation area x RC divided by total
  entity area x RC (conservation + non-conservation) for that group.

## Source

Derived from `data-raw/npsag_3_2224_25Sep25.sas7bdat`, the SAS NPS land
cover file. Built by `data-raw/conserv_correction.R`.

## Details

The tbeploads-built
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md) is
derived from routinely updated GIS sources (land use, soils,
jurisdictions) and does not include a conservation land spatial overlay.
The conservation layer was available only for prior SAS workflows and
cannot reproduced.

`conserv_correction` provides entity-specific fractions derived from the
SAS land cover file (`npsag_3_2224_25Sep25.sas7bdat`), which includes a
binary `conservation` column (0/1) indicating conservation land while
retaining the original MS4 jurisdiction in `entity`. Within
[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md),
each MS4 entity's disaggregated TN load for a given basin and CLUCSID is
scaled by `(1 - conserv_frac)` to remove the conservation land
contribution before hydrologic normalization.

Preprocessing matches
[`util_aa_npsfactors`](https://tbep-tech.github.io/tbeploads/reference/util_aa_npsfactors.md):
non-contributing drainage (`drnfeat = "NONCON"`) and water / tidal
CLUCSIDs (17, 21, 22) are excluded, compound hydrologic soil groups are
simplified, and nested basins are remapped. Only entity, basin, CLUCSID
combinations with `conserv_frac > 0` are retained.

## See also

[`anlz_aa`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md),
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md),
[`util_aa_npsfactors`](https://tbep-tech.github.io/tbeploads/reference/util_aa_npsfactors.md)
