# Utility function for non-point source (NPS) ungaged workflow to create land use and soil data

Utility function for non-point source (NPS) ungaged workflow to create
land use and soil data

## Usage

``` r
util_nps_landsoil(tbbase)
```

## Arguments

- tbbase:

  Input data frame returned from
  [`util_nps_tbbase`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)

## Value

A data frame summarizing land use and soil by bay segment, sub-basin,
drainage feature, CLUCSID, hydrologic group, and improved status.

## Examples

``` r
data(tbbase)
util_nps_landsoil(tbbase)
#> # A tibble: 2,290 × 7
#>    bay_seg basin    drnfeat clucsid hydgrp improved     area
#>      <dbl> <chr>    <chr>     <dbl> <chr>     <int>    <dbl>
#>  1       1 02304500 CON           1 A             1 0.0116  
#>  2       1 02304500 CON           2 A             1 0.0706  
#>  3       1 02304500 CON           4 A             1 0.0177  
#>  4       1 02304500 CON           7 A             1 0.0105  
#>  5       1 02304500 CON           8 A             0 0.0148  
#>  6       1 02304500 CON          15 A             0 0.0122  
#>  7       1 02304500 CON          20 A             0 0.00424 
#>  8       1 02304500 CON           9 A             0 0.00403 
#>  9       1 02304500 CON           5 A             1 0.000606
#> 10       1 02304500 CON          16 A             0 0.00257 
#> # ℹ 2,280 more rows
```
