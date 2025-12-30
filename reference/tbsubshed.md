# Simple feature polygons of sub-watersheds in the Tampa Bay Estuary Program boundary

Simple feature polygons of sub-watersheds in the Tampa Bay Estuary
Program boundary

## Usage

``` r
tbsubshed
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Used for estimating ungaged non-point source (NPS) loads. The data
includes bay segment as follows:

- 1: Old Tampa Bay

- 2: Hillsborough Bay

- 3: Middle Tampa Bay

- 4: Lower Tampa Bay

- 5: Boca Ciega Bay

- 6: Terra Ceia Bay

- 7: Manatee River

- 55: Boca Ciega Bay South

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
if (FALSE) { # \dontrun{
prj <- 6443

tbsubshed <- sf::st_read("./data-raw/gis/TBEP_Major_Basins_NAD1983_SP_FIPS0902_FT.shp") |>
  sf::st_transform(prj) |>
  sf::st_buffer(dist = 0) |>
  dplyr::mutate(
    bay_seg = dplyr::case_when(
      BASINNAME %in% c('Coastal Old Tampa Bay') ~ 1,
      BASINNAME %in% c('Alafia River', 'Coastal Hillsborough Bay', 'Hillsborough River') ~ 2,
      BASINNAME %in% c('Coastal Middle Tampa Bay', 'Little Manatee River') ~ 3,
      BASINNAME %in% c('Coastal Lower Tampa Bay') ~ 4,
      BASINNAME %in% c('Upper Boca Ciega Bay') ~ 5,
      BASINNAME %in% c('Coastal Terra Ceia Bay') ~ 6,
      BASINNAME %in% c('Manatee River') ~ 7,
      BASINNAME %in% c('Lower Boca Ciega Bay') ~ 55,
    )
  ) |>
  dplyr::group_by(bay_seg) |>
  dplyr::summarise(geometry = sf::st_union(geometry), .groups = "drop")

save(tbsubshed, file = 'data/tbsubshed.RData', compress = 'xz')
} # }
tbsubshed
#> Simple feature collection with 8 features and 1 field
#> Geometry type: GEOMETRY
#> Dimension:     XY
#> Bounding box:  xmin: 381348.3 ymin: 1097757 xmax: 693950.9 ymax: 1481517
#> Projected CRS: NAD83(2011) / Florida West (ftUS)
#> # A tibble: 8 × 2
#>   bay_seg                                                               geometry
#>     <dbl>                                            <GEOMETRY [US_survey_foot]>
#> 1       1 POLYGON ((506523.9 1405144, 506454.2 1404720, 506354.5 1404468, 50629…
#> 2       2 MULTIPOLYGON (((524479.8 1255139, 524563.4 1255069, 524690.7 1254949,…
#> 3       3 POLYGON ((581648.5 1246621, 581840.9 1246592, 582177.7 1246565, 58253…
#> 4       4 POLYGON ((478073.1 1204586, 478139.1 1204203, 478463.3 1204213, 47877…
#> 5       5 POLYGON ((402910.1 1310326, 403023.7 1310274, 403634.1 1310286, 40394…
#> 6       6 POLYGON ((479305 1181065, 479429.3 1181013, 479749.6 1181022, 480089.…
#> 7       7 POLYGON ((622142 1204059, 622318.4 1203957, 622453.3 1203836, 622578.…
#> 8      55 POLYGON ((439165.8 1253522, 439306.5 1253395, 439301.6 1253184, 43926…
```
