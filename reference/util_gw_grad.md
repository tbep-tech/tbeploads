# Compute hydraulic gradient per bay segment from UFA potentiometric surface contours

Compute hydraulic gradient per bay segment from UFA potentiometric
surface contours

## Usage

``` r
util_gw_grad(
  contours,
  segs = tbsubshed,
  shoreline = tbsegdetail,
  north_segs = NULL,
  buf_segs = NULL
)
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

- north_segs:

  named numeric vector mapping bay segment IDs to northward extension
  distances (in CRS units, US Survey Feet for EPSG 6443). Segments
  listed here have a rectangular extension appended to the north side of
  their sub-watershed polygon before the contour clipping step, allowing
  the high-point search to reach potentiometric highs that lie north of
  the standard subwatershed boundary. Use this for segments such as Old
  Tampa Bay (segment 1) where the high point is north of the
  subwatershed. Names must be coercible to the integer bay segment IDs
  in `segs`. The `contours` passed to this function must already cover
  the extended area — pass the same distance (or larger) as `north_dist`
  in
  [`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md).
  Default `NULL` (no extension).

- buf_segs:

  named numeric vector mapping bay segment IDs to omnidirectional buffer
  distances (in CRS units, US Survey Feet for EPSG 6443). Segments
  listed here have their sub-watershed polygon buffered outward by the
  given distance, and then all bay water (`shoreline`) is removed from
  that buffer with
  [`st_difference`](https://r-spatial.github.io/sf/reference/geos_binary_ops.html)
  before contour clipping. This allows the high-point search to extend
  beyond the subwatershed onto surrounding land without accidentally
  capturing potentiometric contours that pass under the open bay.
  Segments listed in `buf_segs` are removed from the default
  zero-gradient set and computed dynamically. Use this for segments such
  as Lower Tampa Bay (4), Terra Ceia Bay (6), and Manatee River (7)
  whose wet-season high points lie outside the subwatershed. The
  `contours` passed to this function must already cover the buffered
  area — pass an equivalent or larger value as `north_dist` in
  [`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md)
  if the buffer extends north of the watershed. Default `NULL` (no
  buffering).

## Value

A data frame with columns:

- `bay_seg`: integer, bay segment number

- `grad`: numeric, hydraulic gradient (ft/mile); 0 for segments with no
  reliably computable Floridan aquifer gradient

## Details

Computes the Floridan aquifer hydraulic gradient \\I\\ (ft/mile) for
each bay segment using Darcy's Law as applied in the Tampa Bay loading
model (Zarbock et al., 1994):

\$\$I = \frac{\text{elevation (ft)}}{\text{distance to shoreline
(miles)}}\$\$

where elevation is the maximum UFA potentiometric surface contour value
within the (optionally extended) segment watershed, and distance is the
straight-line distance from that contour's representative point to the
nearest bay shoreline.

The season (dry or wet) is inferred from the `MONTH_YEAR` field in
`contours` (`"May"` = dry, `"September"` = wet). Segments with no
reliably computable Floridan aquifer gradient receive a value of 0:

- Dry season: segments 4, 5, 6, 7, 55

- Wet season: segments 4, 5, 6, 7, 55 — Lower Tampa Bay, Terra Ceia Bay,
  and Manatee River are included by default because the subwatershed
  geometry does not reliably capture the correct potentiometric high
  point. Supply `buf_segs` for any of these segments to compute them
  dynamically using a buffered, bay-clipped search area instead.

**Search area expansion:** Two mechanisms are available and may be
combined across different segments:

- `north_segs`: appends a rectangular extension to the north face of the
  subwatershed bounding box. Best for segments (e.g., OTB) whose high
  point lies directly north of the subwatershed.

- `buf_segs`: omnidirectional buffer with bay water removed. Best for
  segments (e.g., LTB, TCB, MR) whose high point lies east or southeast
  of the subwatershed. Removing the bay polygon prevents the algorithm
  from matching potentiometric contours that pass under open water.

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
#> 1       1 3.985806
#> 2       2 2.989021
#> 3       3 1.463759
#> 4       4 0.000000
#> 5       5 0.000000
#> 6       6 0.000000
#> 7       7 0.000000
#> 8      55 0.000000
util_gw_grad(contwet)
#>   bay_seg     grad
#> 1       1 4.330350
#> 2       2 3.982828
#> 3       3 2.341348
#> 4       4 0.000000
#> 5       5 0.000000
#> 6       6 0.000000
#> 7       7 0.000000
#> 8      55 0.000000
```
