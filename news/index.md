# Changelog

## tbeploads 1.0.1

- Added the `tbmines` dataset of NPDES-permitted mine boundaries.
  [`util_nps_tbbase()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)
  now uses it to reclassify land under an active NPDES permit to
  `CLUCSID = 22` so it can be excluded from NPS load estimates.
- `tbsoil` was rebuilt from the USDA SSURGO layer and now has a single
  `hydgrp` column for the hydrologic soil group.
- [`util_nps_tbbase()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)
  now assigns hydrologic group D to areas with no soil classification
  (typically open water). These areas were previously dropped from the
  base layer.
- [`util_nps_tbbase()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)
  now fills basin and jurisdiction area not covered by the land use
  layer (typically open bay or estuarine water) as Saltwater (FLUCCS
  5400, `CLUCSID = 17`). This area was previously dropped, which
  inflated the share of other land uses within a basin.
- `tbbase` was rebuilt with the changes above.
- [`anlz_aa()`](https://tbep-tech.github.io/tbeploads/reference/anlz_aa.md)
  now splits domestic point source load and water for Coastal subbasin
  580, which straddles Boca Ciega Bay and Boca Ciega Bay South. Only
  41.1% is assigned to segment 55, matching the original SAS workflow.
  The remaining 58.9% belongs to Boca Ciega Bay and is excluded.
- [`show_aaloads()`](https://tbep-tech.github.io/tbeploads/reference/show_aaloads.md)
  now includes Boca Ciega Bay South in segment 55 when summing
  atmospheric deposition, groundwater, and springs loads.
- [`show_aaloads()`](https://tbep-tech.github.io/tbeploads/reference/show_aaloads.md)
  now merges the year and Average cells across the member rows of
  Material Losses shared groups (e.g., Mosaic Big Bend, Riverview, and
  Tampa Marine). The merged cells show the combined group load,
  consistent with
  [`show_aaassess()`](https://tbep-tech.github.io/tbeploads/reference/show_aaassess.md).
  The group is counted once in Total Load.
- The Average column in
  [`show_aaloads()`](https://tbep-tech.github.io/tbeploads/reference/show_aaloads.md)
  is now bold.
- [`util_prepverna()`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md)
  has a new `mincrit` argument (default 75). Months with an NADP
  `Criteria1` or `Criteria3` completeness value below `mincrit` are
  treated as missing before gap filling, in addition to the raw `-9`
  values.
- [`util_spr_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_spr_getwq.md)
  has a new `raw` argument. Setting `raw = TRUE` returns the
  unaggregated observations instead of annual means.
- [`anlz_spr()`](https://tbep-tech.github.io/tbeploads/reference/anlz_spr.md)
  now accepts a CSV of annual output from
  [`util_spr_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_spr_getwq.md)
  for the `wqpth` argument, in addition to FDEP IWR sample data. The
  format is detected from the columns in the file.
- [`anlz_spr()`](https://tbep-tech.github.io/tbeploads/reference/anlz_spr.md)
  now averages duplicate Buckhorn flow records when pivoting and
  suppresses `readxl` warnings on import.
- Added a link to the allocation assessment vignette on the package
  website.
- The macOS R CMD check on GitHub Actions now installs XQuartz.

## tbeploads 1.0.0

- First release, full load estimate workflow
