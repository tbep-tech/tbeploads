# Compute hydraulic gradient per bay segment from potentiometric surface raster

Compute hydraulic gradient per bay segment from potentiometric surface
raster

## Usage

``` r
util_gw_grad(
  pot_rast,
  season = c("dry", "wet"),
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

- segs:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of
  sub-watershed polygons. Defaults to
  [`tbsubshed`](https://tbep-tech.github.io/tbeploads/reference/tbsubshed.md).

- shoreline:

  [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object of bay
  segment polygons used to derive the bay water mask and measure
  distances. Defaults to
  [`tbsegdetail`](https://tbep-tech.github.io/tbeploads/reference/tbsegdetail.md).

- buf_segs:

  named numeric vector mapping bay segment IDs (as character strings) to
  omnidirectional buffer distances in US Survey Feet (CRS 6443). The
  subwatershed for each listed segment is buffered outward by the given
  distance and bay water is removed before the potentiometric high-point
  search. Listing a segment here also removes it from the default
  zero-gradient set so it is computed dynamically. When `NULL`,
  season-specific defaults are used (see Details).

## Value

A data frame with columns `bay_seg` (integer) and `grad` (numeric,
ft/mile; 0 for zero-gradient segments).

## Details

Computes the Floridan Aquifer hydraulic gradient \\I\\ (ft/mile) per bay
segment using the Darcy's Law framework of Zarbock et al. (1994):

\$\$I = \frac{\text{elevation (ft)}}{\text{distance to shoreline
(miles)}}\$\$

The max potentiometric head within the search area is located in the
interpolated raster and the distance is measured from the nearest
shoreline crossing along the bay centroid-to-head transect (see below).

**Zero-gradient segments (hardcoded):** The following segments always
receive a gradient of 0 based on the original SAS loading analysis
(Zarbock et al., 1994; GWld2224_SASCode.txt):

- Boca Ciega Bay (segments 5 and 55), both seasons: the urbanized
  coastal watershed has no meaningful Floridan Aquifer recharge directed
  toward the bay.

- Lower Tampa Bay (4), Terra Ceia Bay (6), Manatee River (7), dry season
  only: the potentiometric gradient is negligible during the dry season.
  These segments are computed dynamically in the wet season via the
  default `buf_segs`.

Any segment listed in `buf_segs` is removed from the zero set and
computed dynamically.

**Default buf_segs (calibrated against 2021 SAS reference values):**

- Dry season: `c("1" = 100000)` – Old Tampa Bay subwatershed buffered
  ~19 miles; captures the potentiometric high north/northeast of the
  standard watershed boundary.

- Wet season:
  `c("1" = 100000, "4" = 100000, "6" = 100000, "7" = 100000)` – adds
  LTB, TCB, and MR (each ~19 miles) to unlock wet-season computation for
  those segments.

Buffer distances were tuned to produce gradients within ~15\\ FDEP
potentiometric surface values used in the SAS analysis.

**Distance calculation:** Rather than measuring from the potentiometric
high to the nearest shoreline point (which can hit an extreme geographic
corner), the function draws a line from the bay segment centroid to the
max-head cell. The portion of that line inside the bay polygon is
subtracted from the total length, giving the distance from the shoreline
crossing point to the high point along a representative transect.

**Hillsborough Bay (segment 2):** Uses a three-zone weighted gradient
(Polk County 0.4, Pasco County 0.3, Alafia River 0.3) following the
original flow net analysis. Sub-zones are constructed from
[`tbdbasin`](https://tbep-tech.github.io/tbeploads/reference/tbdbasin.md)
drainage basins as in the original SAS code.

**Benchmark warning:** After computing gradients, each non-zero segment
is compared against the 2021 SAS reference values
(GWld2224_SASCode.txt). A warning is issued for any segment whose
computed gradient deviates by more than 50\\ reference, indicating a
potentially anomalous potentiometric surface or a need to revisit the
`buf_segs` configuration.

## References

Zarbock, H., A. Janicki, D. Wade, D. Heimbuch, and H. Wilson. 1994.
Estimates of Total Nitrogen, Total Phosphorus, and Total Suspended
Solids Loadings to Tampa Bay, Florida. Technical Publication \#04-94.
Prepared by Coastal Environmental, Inc. Prepared for Tampa Bay National
Estuary Program. St. Petersburg, FL.

## Examples

``` r
if (FALSE) { # \dontrun{
pot_dry <- util_gw_getcontour("dry", 2022)
util_gw_grad(pot_dry, season = "dry")

pot_wet <- util_gw_getcontour("wet", 2022)
util_gw_grad(pot_wet, season = "wet")
} # }
```
