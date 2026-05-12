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
#> # A tibble: 1,014 × 7
#>    bay_seg basin    drnfeat clucsid hydgrp improved    area
#>      <dbl> <chr>    <chr>     <dbl> <chr>     <int>   <dbl>
#>  1       1 02307000 CON           8 A             0 15.2   
#>  2       1 02307000 CON           8 B             0  0.488 
#>  3       1 02307000 CON          15 A             0 94.1   
#>  4       1 02307000 CON          15 B             0  6.88  
#>  5       1 02307000 CON           7 A             1  0.540 
#>  6       1 02307000 CON           7 B             1  0.0408
#>  7       1 02307000 CON           1 A             1  1.81  
#>  8       1 02307000 CON          18 A             0 35.1   
#>  9       1 02307000 CON          20 A             0 26.6   
#> 10       1 02307000 CON          10 A             1  0.0109
#> # ℹ 1,004 more rows
```
