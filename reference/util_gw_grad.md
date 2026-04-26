# Compute hydraulic gradient per bay segment from UFA potentiometric surface contours

Compute hydraulic gradient per bay segment from UFA potentiometric
surface contours

## Usage

``` r
util_gw_grad(contours, segs = tbsubshed, shoreline = tbsegdetail)
```

## Arguments

- contours:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of
  Upper Floridan Aquifer contour lines produced by
  [`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md).

- segs:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of
  sub-watershed polygons. Defaults to
  [`tbsubshed`](https://tbep-tech.github.io/tbeploads/reference/tbsubshed.md).

- shoreline:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of bay
  segment polygons used to measure distance from the watershed high
  point to the bay. Defaults to
  [`tbsegdetail`](https://tbep-tech.github.io/tbeploads/reference/tbsegdetail.md).

## Value

A data frame with columns:

- `bay_seg`: integer, bay segment number

- `grad`: numeric, hydraulic gradient (ft/mile); 0 for segments with no
  direct Floridan aquifer discharge

## Details

Computes the Floridan aquifer hydraulic gradient \\I\\ (ft/mile) for
each bay segment using Darcy's Law as applied in the Tampa Bay loading
model (Zarbock et al., 1994):

\$\$I = \frac{\text{elevation (ft)}}{\text{distance to shoreline
(miles)}}\$\$

where elevation is the maximum UFA potentiometric surface contour value
within the segment watershed, and distance is the straight-line distance
from that contour's representative point to the nearest bay shoreline.

The season (dry or wet) is inferred from the `MONTH_YEAR` field in
`contours` (`"May"` = dry, `"September"` = wet). Segments with no direct
Floridan aquifer discharge to the bay receive a gradient of 0:

- Dry season: segments 4, 5, 6, 7, 55

- Wet season: segments 5, 55

**Hillsborough Bay (segment 2):** Segment 2 uses a weighted average of
three sub-zone gradients following the original flow net analysis.
Sub-zones are constructed by unioning
[`tbdbasin`](https://tbep-tech.github.io/tbeploads/reference/tbdbasin.md)
drainage basins:

- Polk County drainage (weight 0.4): basins 02301000, 02301500

- Pasco County / Hillsborough River drainage (weight 0.3): basins
  02300700, 02301300, 02301750, TBYPASS

- Alafia River drainage (weight 0.3): basins 02301695, 02303000,
  02303330, 02304500, 204-2, 205-2, 206-2

## Examples

``` r
util_gw_grad(contdry)
#>   bay_seg     grad
#> 1       1 5.112199
#> 2       2 3.950250
#> 3       3 1.618941
#> 4       4 0.000000
#> 5       5 0.000000
#> 6       6 0.000000
#> 7       7 0.000000
#> 8      55 0.000000
util_gw_grad(contwet)
#>   bay_seg       grad
#> 1       1   5.732379
#> 2       2   5.228272
#> 3       3   2.573333
#> 4       4  11.385912
#> 5       5   0.000000
#> 6       6 119.253153
#> 7       7   2.347513
#> 8      55   0.000000
```
