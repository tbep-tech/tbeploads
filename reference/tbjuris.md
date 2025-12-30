# Simple feature polygons of jurisdictional boundaries in the Tampa Bay Estuary Program boundary

Simple feature polygons of jurisdictional boundaries in the Tampa Bay
Estuary Program boundary

## Usage

``` r
tbjuris
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Used for estimating ungaged non-point source (NPS) loads. The data
includes the following columns.

- `entity`: Character for the entity name

- `geometry`: The geometry column

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
if (FALSE) { # \dontrun{
prj <- 6443

tbjuris <- sf::st_read("./data-raw/gis/TB_Juris.shp") |>
  sf::st_transform(prj) |>
  sf::st_buffer(dist = 0) |>
  dplyr::rename(entity = NAME_FINAL) |>
  dplyr::select(entity) |>
  dplyr::group_by(entity) |>
  dplyr::summarise()

save(tbjuris, file = 'data/tbjuris.RData', compress = 'xz')
} # }
tbjuris
#> Simple feature collection with 74 features and 1 field
#> Geometry type: GEOMETRY
#> Dimension:     XY
#> Bounding box:  xmin: 381349.4 ymin: 1097755 xmax: 693951.9 ymax: 1481515
#> Projected CRS: NAD83(2011) / Florida West (ftUS)
#> # A tibble: 74 × 2
#>    entity                                                               geometry
#>    <chr>                                             <GEOMETRY [US_survey_foot]>
#>  1 ALAFIA PRESERVE    POLYGON ((652034.3 1293169, 652031.9 1293260, 652031.6 12…
#>  2 BLOOMINGDALE       POLYGON ((544041.5 1294379, 544068.2 1294366, 544075.6 12…
#>  3 Bradenton          MULTIPOLYGON (((462950.6 1140510, 462886.7 1140573, 46288…
#>  4 CHEVAL WEST        POLYGON ((479833.5 1390574, 479962.7 1390572, 479975.5 13…
#>  5 CITY OF PLANT CITY POLYGON ((603842.9 1318081, 603842.8 1318081, 603842.8 13…
#>  6 CLEARWATER         MULTIPOLYGON (((405421.9 1309812, 405271.6 1309815, 40507…
#>  7 DADE CITY          MULTIPOLYGON (((597117.4 1452015, 597117.3 1451989, 59709…
#>  8 DONALDSON KNOLL    POLYGON ((652752.7 1292931, 652611.1 1292996, 652601.4 12…
#>  9 EAGLE RIDGE        POLYGON ((651135.6 1293395, 651322.4 1293150, 651350.5 12…
#> 10 GULFPORT           MULTIPOLYGON (((422576.3 1240322, 422578.4 1240320, 42260…
#> # ℹ 64 more rows
```
