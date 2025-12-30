# Simple features polygon for the Tampa Bay Estuary Program boundary

Simple features polygon for the Tampa Bay Estuary Program boundary

## Usage

``` r
tbfullshed
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Used for estimating ungaged non-point source (NPS) loads. The data
includes the following columns.

- `Name`: Character for the layer name

- `Hectares`: Numeric value for area of the polygon

- `geometry`: The geometry column

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
if (FALSE) { # \dontrun{
prj <- 6443

tbfullshed <- sf::st_read("./data-raw/gis/TBEP_Watershed_Correct_Projection.shp") |>
  st_transform(prj) |>
  st_union(by_feature = T) |>
  st_buffer(dist = 0) |>
  dplyr::select(Name, Hectares)

save(tbfullshed, file = 'data/tbfullshed.RData', compress = 'xz')
} # }
tbfullshed
#> Simple feature collection with 1 feature and 2 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 381348.3 ymin: 1097757 xmax: 693950.9 ymax: 1481517
#> Projected CRS: NAD83(2011) / Florida West (ftUS)
#>                                 Name Hectares                       geometry
#> 1 Tampa Bay Estuary Program Boundary 685299.6 POLYGON ((555744.8 1479557,...
```
