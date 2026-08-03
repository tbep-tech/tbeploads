# Create unioned base layer for non-point source (NPS) ungaged load estimation in the Tampa Bay watershed

Create unioned base layer for non-point source (NPS) ungaged load
estimation in the Tampa Bay watershed

## Usage

``` r
util_nps_tbbase(
  tblu,
  tbsoil,
  gdal_path = NULL,
  chunk_size = NULL,
  cast = FALSE,
  verbose = TRUE
)
```

## Arguments

- tblu:

  sf object of land use/land cover in the Tampa Bay watershed, currently
  `link{tblu2023}`

- tbsoil:

  sf object `link{tbsoil}` of soil data in the Tampa Bay watershed

- gdal_path:

  Character string specifying the path to GDAL binaries (e.g.,
  "C:/OSGeo4W/bin"). If NULL (default), assumes GDAL is in system PATH.

- chunk_size:

  Integer. For large datasets, process in chunks of this many features.
  Set to NULL (default) to process all at once. This applies only to the
  final union with the soils data.

- cast:

  Logical. If TRUE, will cast multipolygon geometries to polygons before
  processing. Default is FALSE, which keeps multipolygons as is (usually
  faster).

- verbose:

  Logical. If TRUE, will print progress messages. Default is TRUE.

## Value

A summarized data frame containing the union of all inputs showing major
bay segment, sub-basin (basin), drainage feature (drnfeat), jurisdiction
(entity), land use/land cover (FLUCCSCODE), CLUCSID, IMPROVED,
hydrologic group (hydgrp), and area in hectares. These represent all
relevant spatial combinations in the Tampa Bay watershed. Land falling
under an active NPDES discharge permit (see
[`tbmines`](https://tbep-tech.github.io/tbeploads/reference/tbmines.md))
is reclassified to `CLUCSID = 22`, overriding any FLUCCS-based category,
so it can be excluded from NPS load estimation in
[`util_aa_npsfactors`](https://tbep-tech.github.io/tbeploads/reference/util_aa_npsfactors.md).
Areas with no soil classification in
[`tbsoil`](https://tbep-tech.github.io/tbeploads/reference/tbsoil.md)
(`hydgrp` is `NA`, typically open water) are assigned `hydgrp = "D"` and
retained rather than dropped. Basin/jurisdiction area not covered by
`tblu` (also typically open bay/estuarine water) is likewise retained,
assigned FLUCCS code 5400 (`CLUCSID = 17`, Saltwater) rather than
dropped.

## Details

Relies heavily on
[`util_nps_union`](https://tbep-tech.github.io/tbeploads/reference/util_nps_union.md)
to perform the union operations efficiently using GDAL/OGR. All input
must have the CRS of NAD83(2011) / Florida West (ftUS), EPSG:6443.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load required data
data(tblu2023)
data(tbsoil)
result <- util_nps_tbbase(tblu2023, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)
} # }
```
