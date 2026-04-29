# Upper Floridan Aquifer potentiometric surface raster, wet season 2022

Upper Floridan Aquifer potentiometric surface raster, wet season 2022

## Usage

``` r
contwet
```

## Format

A `PackedSpatRaster` (see
[`wrap`](https://rspatial.github.io/terra/reference/wrap.html))
representing a 1-mile resolution grid of potentiometric head (ft above
MSL) for the wet season. Unwrap with `terra::unwrap(contwet)` to obtain
a
[`SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

Interpolated from Upper Floridan Aquifer potentiometric surface contour
lines (September 2022) downloaded from the FDEP / Florida Geological
Survey ArcGIS REST service using
[`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md).
The spatial extent covers the Tampa Bay watershed
([`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md))
buffered outward by 40 miles. Interpolation used inverse distance
weighting (IDW, 5-mile radius, power = 2) followed by five passes of a
3x3 focal mean gap fill. Projection is NAD83(2011) / Florida GDL Albers
(ftUS), CRS 6443.

Dry season equivalent is
[`contdry`](https://tbep-tech.github.io/tbeploads/reference/contdry.md).

## Examples

``` r
if (FALSE) { # \dontrun{
pot_wet <- util_gw_getcontour("wet", 2022)
contwet <- terra::wrap(pot_wet)
save(contwet, file = "data/contwet.RData", compress = "xz")
} # }
terra::unwrap(contwet)
#> class       : SpatRaster 
#> size        : 415, 420, 1  (nrow, ncol, nlyr)
#> resolution  : 5280, 5280  (x, y)
#> extent      : -927768.1, 1289832, 268821.5, 2460022  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83(2011) / Florida West (ftUS) (EPSG:6443) 
#> source(s)   : memory
#> name        : focal_mean 
#> min value   :         10 
#> max value   :        130 
```
