# Utility function to create non-point source (NPS) ungaged land use and soil runoff coefficients

Utility function to create non-point source (NPS) ungaged land use and
soil runoff coefficients

## Usage

``` r
util_nps_landsoilrc(tbbase, yrexp = c(2021:2023))
```

## Arguments

- tbbase:

  Data frame returned from
  [`util_nps_tbbase`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)
  containing land use and soil data.

- yrexp:

  Years to expand the data frame to include all months for each year.

## Value

A data frame with land use (CLUCSID) and soil runoff coefficients by
year and month.

## Examples

``` r
data(tbbase)

util_nps_landsoilrc(tbbase, yrexp = c(2021:2023))
#> # A tibble: 73,512 × 13
#>    bay_seg basin drnfeat clucsid hydgrp   area dry_rc wet_rc    mo    rc     rca
#>      <dbl> <chr> <chr>     <dbl> <chr>   <dbl>  <dbl>  <dbl> <int> <dbl>   <dbl>
#>  1       1 0230… CON           1 A      0.0116   0.15   0.25     1  0.15 0.00174
#>  2       1 0230… CON           1 A      0.0116   0.15   0.25     1  0.15 0.00174
#>  3       1 0230… CON           1 A      0.0116   0.15   0.25     1  0.15 0.00174
#>  4       1 0230… CON           1 A      0.0116   0.15   0.25     2  0.15 0.00174
#>  5       1 0230… CON           1 A      0.0116   0.15   0.25     2  0.15 0.00174
#>  6       1 0230… CON           1 A      0.0116   0.15   0.25     2  0.15 0.00174
#>  7       1 0230… CON           1 A      0.0116   0.15   0.25     3  0.15 0.00174
#>  8       1 0230… CON           1 A      0.0116   0.15   0.25     3  0.15 0.00174
#>  9       1 0230… CON           1 A      0.0116   0.15   0.25     3  0.15 0.00174
#> 10       1 0230… CON           1 A      0.0116   0.15   0.25     4  0.15 0.00174
#> # ℹ 73,502 more rows
#> # ℹ 2 more variables: tot_rca <dbl>, yr <int>
```
