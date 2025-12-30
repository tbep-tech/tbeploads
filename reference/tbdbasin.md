# Simple feature polygons major drainage basins in the Tampa Bay Estuary Program boundary

Simple feature polygons major drainage basins in the Tampa Bay Estuary
Program boundary

## Usage

``` r
tbdbasin
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Used for estimating ungaged non-point source (NPS) loads. The data
includes the following columns.

- `basin`: Numeric value for the basin

- `drnfeat`: Numeric for the drainage feature

- `geometry`: The geometry column

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
if (FALSE) { # \dontrun{
prj <- 6443

tbdbasin <- sf::st_read("./data-raw/gis/TBEP_dBasins_FIPS0902_Projection.shp") |>
  sf::st_transform(prj) |>
  sf::st_buffer(dist = 0) |>
  dplyr::group_by(NEWGAGE, DRNFEATURE) |>
  dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop") |>
  dplyr::select(
    basin = NEWGAGE,
    drnfeat = DRNFEATURE
  ) |>
  dplyr::arrange(basin, drnfeat)

save(tbdbasin, file = 'data/tbdbasin.RData', compress = 'xz')
} # }
tbdbasin
#> Simple feature collection with 132 features and 2 fields
#> Geometry type: GEOMETRY
#> Dimension:     XY
#> Bounding box:  xmin: 381348.3 ymin: 1097755 xmax: 693949.9 ymax: 1481515
#> Projected CRS: NAD83(2011) / Florida West (ftUS)
#> # A tibble: 132 × 3
#>    basin    drnfeat                                                     geometry
#>    <chr>    <chr>                                    <GEOMETRY [US_survey_foot]>
#>  1 02299950 DITCH   POLYGON ((603267.7 1178451, 603246.7 1178557, 603219.8 1178…
#>  2 02299950 DRAIN   POLYGON ((620102.1 1171285, 620084.7 1171134, 620081.8 1170…
#>  3 02299950 NONCON  POLYGON ((626704.5 1202576, 626732.7 1202559, 626756.9 1202…
#>  4 02299950 STREAM  MULTIPOLYGON (((587198.4 1157684, 587221.7 1157443, 587257.…
#>  5 02299950 NA      POLYGON ((627934.6 1195518, 627947.6 1195309, 627951.2 1194…
#>  6 02300500 DRAIN   POLYGON ((598235 1214563, 598144.2 1214483, 597923.9 121430…
#>  7 02300500 LAKE    POLYGON ((560013.1 1228160, 559909.3 1228042, 559721.3 1227…
#>  8 02300500 NONCON  MULTIPOLYGON (((559323.7 1194079, 559028.6 1193749, 558703.…
#>  9 02300500 OUTLET  POLYGON ((562640.4 1226255, 562646.6 1226142, 562619.6 1225…
#> 10 02300500 STREAM  MULTIPOLYGON (((568858.9 1207194, 568961.1 1207290, 569045.…
#> # ℹ 122 more rows
```
