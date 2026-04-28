# Simple feature polygons of Tampa Bay segments with shoreline detail

Simple feature polygons of Tampa Bay segments with shoreline detail

## Usage

``` r
tbsegdetail
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Detailed shoreline polygons for the major bay segments, including a
North/South split for Boca Ciega Bay. Note that the Boca Ciega Bay
segment is only the northern portion. The data includes the following
columns.

Layer was clipped to retain only the main open-water bay areas,
excluding tidal rivers and creek arms. The clipping mask is available in
`data-raw/tbsegdetail_clip_mask.RData` for reproducibility. See
`data-raw/tbsegdetail_clip.R` for the clipping workflow.

- `bay_seg`: Integer, numeric segment identifier matching

- `geometry`: The geometry column

Bay segments included:

- 1: Old Tampa Bay

- 2: Hillsborough Bay

- 3: Middle Tampa Bay

- 4: Lower Tampa Bay

- 5: Boca Ciega Bay (North)

- 6: Terra Ceia Bay

- 7: Manatee River

- 55: Boca Ciega Bay South

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
tbsegdetail
#> Simple feature collection with 8 features and 1 field
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 386545.7 ymin: 1150354 xmax: 531885 ymax: 1347037
#> Projected CRS: NAD83(2011) / Florida West (ftUS)
#>   bay_seg                       geometry
#> 1       1 MULTIPOLYGON (((483392.2 12...
#> 2       2 MULTIPOLYGON (((520177.4 12...
#> 3       3 MULTIPOLYGON (((522897.1 12...
#> 4       4 MULTIPOLYGON (((460639.5 11...
#> 5       5 MULTIPOLYGON (((411615.9 12...
#> 6       6 MULTIPOLYGON (((451284.1 11...
#> 7       7 MULTIPOLYGON (((448694.9 11...
#> 8      55 MULTIPOLYGON (((417777.9 11...
```
