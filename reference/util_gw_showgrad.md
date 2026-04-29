# Visualise the hydraulic gradient for a bay segment

Visualise the hydraulic gradient for a bay segment

## Usage

``` r
util_gw_showgrad(
  pot_rast,
  season = c("dry", "wet"),
  seg,
  segs = tbsubshed,
  shoreline = tbsegdetail,
  buf_segs = NULL
)
```

## Arguments

- pot_rast:

  [`SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  (or `PackedSpatRaster`) of Upper Floridan Aquifer potentiometric head
  (ft above MSL) as returned by
  [`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md),
  or the package datasets
  [`contdry`](https://tbep-tech.github.io/tbeploads/reference/contdry.md)
  /
  [`contwet`](https://tbep-tech.github.io/tbeploads/reference/contwet.md).

- season:

  character, `"dry"` or `"wet"`.

- seg:

  integer, bay segment number (1-7).

- segs:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of
  sub-watershed polygons. Defaults to
  [`tbsubshed`](https://tbep-tech.github.io/tbeploads/reference/tbsubshed.md).

- shoreline:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of bay
  segment polygons. Defaults to
  [`tbsegdetail`](https://tbep-tech.github.io/tbeploads/reference/tbsegdetail.md).

- buf_segs:

  named numeric vector of buffer distances (US Survey Feet) in the same
  format accepted by
  [`util_gw_grad`](https://tbep-tech.github.io/tbeploads/reference/util_gw_grad.md).
  When `NULL`, season-specific defaults are used (see
  [`util_gw_grad`](https://tbep-tech.github.io/tbeploads/reference/util_gw_grad.md)
  for details).

## Value

A [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Returns a `ggplot2` map for the requested segment showing:

- The potentiometric surface (ft) within the search area, coloured by
  head value.

- The search area boundary (light yellow).

- All bay segments (grey background) and the target segment (blue).

- A dotted line from the bay centroid to the max-head land cell (showing
  the full transect used in the distance calculation).

- A dashed line for the land portion of that transect (the actual
  gradient distance).

- The max-head point (red dot).

The subtitle reports max head (ft), distance (miles), and gradient
(ft/mi). See
[`util_gw_grad`](https://tbep-tech.github.io/tbeploads/reference/util_gw_grad.md)
for the distance calculation methodology.

## Examples

``` r
if (FALSE) { # \dontrun{
contdry <- util_gw_getcontour("dry", 2022)
} # }
util_gw_showgrad(contdry, season = "dry", seg = 1)

util_gw_showgrad(contdry, season = "dry", seg = 3)
#> Warning: Raster pixels are placed at uneven horizontal intervals and will be shifted
#> ℹ Consider using `geom_tile()` instead.
#> Warning: Raster pixels are placed at uneven horizontal intervals and will be shifted
#> ℹ Consider using `geom_tile()` instead.


if (FALSE) { # \dontrun{
contwet <- util_gw_getcontour("wet", 2022)
} # }
util_gw_showgrad(contwet, season = "wet", seg = 4)

util_gw_showgrad(contwet, season = "wet", seg = 7)
```
