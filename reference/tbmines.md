# Simple feature polygons of NPDES-permitted phosphate mine boundaries in the Tampa Bay watershed

Simple feature polygons of NPDES-permitted phosphate mine boundaries in
the Tampa Bay watershed

## Usage

``` r
tbmines
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Used by
[`util_nps_tbbase`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)
to flag land under an active NPDES discharge permit so it can be
excluded from non-point source (NPS) load estimation (see
[`util_aa_npsfactors`](https://tbep-tech.github.io/tbeploads/reference/util_aa_npsfactors.md),
which excludes `CLUCSID = 22`). Without this exclusion, a permitted
facility's land area would be counted twice: once through the
land-use-based NPS model and again through its actual point-source
(IPS/DPS) discharge data. The data include the following columns.

- `Location`: Character for the mine name

- `Owner`: Character for the operating company

- `geometry`: The geometry column

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

Covers 14 Central Florida phosphate mine sites (13 operated by Mosaic, 1
by CF Industries).

## Examples

``` r
if (FALSE) { # \dontrun{
prj <- 6443

tbmines <- sf::st_read("./data-raw/gis/TB_mines_NPDES.shp") |>
  sf::st_make_valid() |>
  sf::st_transform(prj)

save(tbmines, file = 'data/tbmines.RData', compress = 'xz')
} # }
tbmines
#> Simple feature collection with 14 features and 2 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 523631.5 ymin: 1148412 xmax: 690205.5 ymax: 1395169
#> Projected CRS: NAD83(2011) / Florida West (ftUS)
#> First 10 features:
#>           Location  Owner                       geometry
#> 1       Fort Green Mosaic MULTIPOLYGON (((630893.4 11...
#> 2     Four Corners Mosaic MULTIPOLYGON (((598810.5 12...
#> 3        Green Bay Mosaic MULTIPOLYGON (((682420.8 12...
#> 4  Hookers Prairie Mosaic MULTIPOLYGON (((688453.1 12...
#> 5         Hopewell Mosaic MULTIPOLYGON (((622077.6 12...
#> 6        Kingsford Mosaic MULTIPOLYGON (((624298.7 12...
#> 7         Lonesome Mosaic MULTIPOLYGON (((613112 1238...
#> 8         Mulberry Mosaic MULTIPOLYGON (((675359.8 12...
#> 9        New Wales Mosaic MULTIPOLYGON (((643127.9 12...
#> 10         Nichols Mosaic MULTIPOLYGON (((648672.1 12...
```
