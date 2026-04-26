# Upper Floridan Aquifer potentiometric surface contour lines, dry season 2022

Upper Floridan Aquifer potentiometric surface contour lines, dry season
2022

## Usage

``` r
contdry
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Contour lines representing the potentiometric surface of the Upper
Floridan Aquifer for the dry season (May 2022), clipped to the Tampa Bay
watershed
([`tbfullshed`](https://tbep-tech.github.io/tbeploads/reference/tbfullshed.md)).
Retrieved from the FDEP / Florida Geological Survey ArcGIS REST service.
The data includes the following columns.

- `CONTOUR`: Integer, potentiometric surface elevation in feet above
  mean sea level (range 10-100 ft for the Tampa Bay area)

- `MONTH_YEAR`: Character, survey date (`"May 2022"`)

- `geometry`: The geometry column (LINESTRING)

Dry season is represented by May observations. Wet season equivalent is
[`contwet`](https://tbep-tech.github.io/tbeploads/reference/contwet.md).

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
if (FALSE) { # \dontrun{
contdry <- util_gw_getcontour("dry", 2022)
save(contdry, file = "data/contdry.RData", compress = "xz")
} # }
contdry
#> Simple feature collection with 10 features and 2 fields
#> Geometry type: GEOMETRY
#> Dimension:     XY
#> Bounding box:  xmin: 429863.6 ymin: 1110802 xmax: 680696.3 ymax: 1479759
#> Projected CRS: NAD83(2011) / Florida West (ftUS)
#>    CONTOUR MONTH_YEAR                       geometry
#> 1       80   May 2022 MULTILINESTRING ((618103.4 ...
#> 2       70   May 2022 MULTILINESTRING ((606930.6 ...
#> 3       40   May 2022 MULTILINESTRING ((470444.8 ...
#> 4       50   May 2022 MULTILINESTRING ((470000.7 ...
#> 5       60   May 2022 LINESTRING (501635.4 140231...
#> 6       30   May 2022 LINESTRING (460833.8 139053...
#> 7       20   May 2022 LINESTRING (446484 1389331,...
#> 8       10   May 2022 MULTILINESTRING ((458262 11...
#> 11      90   May 2022 MULTILINESTRING ((669432.1 ...
#> 12     100   May 2022 MULTILINESTRING ((649538.1 ...
```
