# Upper Floridan Aquifer potentiometric surface raster, dry season 2022

Upper Floridan Aquifer potentiometric surface raster, dry season 2022

## Usage

``` r
contdry
```

## Format

A `PackedSpatRaster` (see
[`wrap`](https://rspatial.github.io/terra/reference/wrap.html))
representing a 1-mile resolution grid of potentiometric head (ft above
MSL) for the dry season. Unwrap with `terra::unwrap(contdry)` to obtain
a
[`SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).

## Details

Interpolated from Upper Floridan Aquifer potentiometric surface contour
lines (May 2022) downloaded from the FDEP / Florida Geological Survey
ArcGIS REST service using
[`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md).
The spatial extent covers the Tampa Bay watershed
([`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md))
buffered outward by 40 miles. Interpolation used inverse distance
weighting (IDW, 5-mile radius, power = 2) followed by five passes of a
3x3 focal mean gap fill. Projection is NAD83(2011) / Florida GDL Albers
(ftUS), CRS 6443.

Wet season equivalent is
[`contwet`](https://tbep-tech.github.io/tbeploads/reference/contwet.md).

## Examples

``` r
if (FALSE) { # \dontrun{
pot_dry <- util_gw_getcontour("dry", 2022)
contdry <- terra::wrap(pot_dry)
save(contdry, file = "data/contdry.RData", compress = "xz")
} # }
terra::unwrap(contdry)
#> class       : SpatRaster 
#> size        : 446, 416, 1  (nrow, ncol, nlyr)
#> resolution  : 5280, 5280  (x, y)
#> extent      : -932869.6, 1263610, 108335.4, 2463215  (xmin, xmax, ymin, ymax)
#> coord. ref. : NAD83(2011) / Florida West (ftUS) (EPSG:6443) 
#> source(s)   : memory
#> name        : focal_mean 
#> min value   :         10 
#> max value   :        120 
```
