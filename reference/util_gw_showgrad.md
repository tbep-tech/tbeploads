# Visualise the hydraulic gradient line for a bay segment

Visualise the hydraulic gradient line for a bay segment

## Usage

``` r
util_gw_showgrad(
  contours,
  seg,
  segs = tbsubshed,
  shoreline = tbsegdetail,
  north_segs = NULL
)
```

## Arguments

- contours:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of
  Upper Floridan Aquifer contour lines as returned by
  [`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md).

- seg:

  integer, bay segment number (1-7).

- segs:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of
  sub-watershed polygons. Defaults to
  [`tbsubshed`](https://tbep-tech.github.io/tbeploads/reference/tbsubshed.md).

- shoreline:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of bay
  segment polygons used to measure distance from the watershed high
  point to the bay. Defaults to
  [`tbsegdetail`](https://tbep-tech.github.io/tbeploads/reference/tbsegdetail.md).

- north_segs:

  named numeric vector of northward extension distances (in CRS units,
  US Survey Feet for EPSG 6443), in the same format accepted by
  [`util_gw_grad`](https://tbep-tech.github.io/tbeploads/reference/util_gw_grad.md).
  Default `NULL` (no extension).

## Value

A [`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Returns a `ggplot2` map showing, for the requested segment: the
subwatershed search area (optionally extended northward), all clipped
contour lines coloured by elevation, the maximum-elevation contour
highlighted in red, the representative high point used in the gradient
computation, and a dashed line to the nearest bay shoreline point. The
plot subtitle reports the elevation, straight-line distance (miles), and
computed gradient (ft/mile).

For segment 2 (Hillsborough Bay) the visualisation shows the single
max-contour approach rather than the weighted three-zone calculation
used in
[`util_gw_grad`](https://tbep-tech.github.io/tbeploads/reference/util_gw_grad.md).

## Examples

``` r
util_gw_showgrad(contdry, seg = 1, north_segs = c("1" = 150000))

util_gw_showgrad(contwet, seg = 3)
```
