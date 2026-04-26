# Upper Floridan Aquifer potentiometric surface contour lines, wet season 2022

Upper Floridan Aquifer potentiometric surface contour lines, wet season
2022

## Usage

``` r
contwet
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Contour lines representing the potentiometric surface of the Upper
Floridan Aquifer for the wet season (September 2022), clipped to the
Tampa Bay watershed
([`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md)).
Retrieved from the FDEP / Florida Geological Survey ArcGIS REST service.
The data includes the following columns.

- `CONTOUR`: Integer, potentiometric surface elevation in feet above
  mean sea level (range 10-110 ft for the Tampa Bay area)

- `MONTH_YEAR`: Character, survey date (`"September 2022"`)

- `geometry`: The geometry column (LINESTRING)

Wet season is represented by September observations. Dry season
equivalent is
[`contdry`](https://tbep-tech.github.io/tbeploads/reference/contdry.md).

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
if (FALSE) { # \dontrun{
contwet <- util_gw_getcontour("wet", 2022)
save(contwet, file = "data/contwet.RData", compress = "xz")
} # }
contwet
#> Simple feature collection with 11 features and 2 fields
#> Geometry type: GEOMETRY
#> Dimension:     XY
#> Bounding box:  xmin: 423782.9 ymin: 1139044 xmax: 679565.2 ymax: 1479154
#> Projected CRS: NAD83(2011) / Florida West (ftUS)
#> First 10 features:
#>    CONTOUR     MONTH_YEAR                       geometry
#> 1       10 September 2022 LINESTRING (425066.5 139014...
#> 2       20 September 2022 LINESTRING (438618.8 138589...
#> 3       30 September 2022 LINESTRING (451265.7 139192...
#> 4       40 September 2022 MULTILINESTRING ((465097.9 ...
#> 5       50 September 2022 MULTILINESTRING ((638039.9 ...
#> 6       60 September 2022 LINESTRING (656841.9 123798...
#> 7       70 September 2022 MULTILINESTRING ((528316.6 ...
#> 8       80 September 2022 MULTILINESTRING ((620996.8 ...
#> 9       90 September 2022 MULTILINESTRING ((635256.9 ...
#> 10     100 September 2022 MULTILINESTRING ((663110.6 ...
```
