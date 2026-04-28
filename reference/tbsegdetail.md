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
#> Bounding box:  xmin: 381504.4 ymin: 1119184 xmax: 572676.9 ymax: 1352651
#> Projected CRS: NAD83(2011) / Florida West (ftUS)
#>   bay_seg                       geometry
#> 1       1 MULTIPOLYGON (((463240 1274...
#> 2       2 MULTIPOLYGON (((520664.9 12...
#> 3       3 MULTIPOLYGON (((522979.7 12...
#> 4       4 MULTIPOLYGON (((463875.7 11...
#> 5       5 MULTIPOLYGON (((402858 1253...
#> 6       6 MULTIPOLYGON (((464946.2 11...
#> 7       7 MULTIPOLYGON (((448613.9 11...
#> 8      55 MULTIPOLYGON (((417285.3 12...
```
