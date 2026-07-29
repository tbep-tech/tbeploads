# Simple feature polygons of soil data in the Tampa Bay Estuary Program boundary

Simple feature polygons of soil data in the Tampa Bay Estuary Program
boundary

## Usage

``` r
tbsoil
```

## Format

A [`sf`](https://r-spatial.github.io/sf/reference/sf.html) object

## Details

Used for estimating ungaged non-point source (NPS) loads. The data
includes the following columns.

- `hydgrp`: Character for the hydrologic group (A, B, C, D, etc.) of the
  soil

- `geometry`: The geometry column

Projection is NAD83(2011) / Florida West (ftUS), CRS 6443.

## Examples

``` r
if (FALSE) { # \dontrun{
usdasoil <- st_read('T:/05_GIS/TBEP/TBLOADS/USDA_SSURGO_CLIP_FIPS0902.shp')
tbsoil <- usdasoil |>
  select(hydgrp = SDV_Hydr_1) |>
  group_by(hydgrp) |>
  summarise() |>
  st_transform(crs = 6443)
save(tbsoil, file = 'data/tbsoil.RData', compress = 'xz')
} # }
```
