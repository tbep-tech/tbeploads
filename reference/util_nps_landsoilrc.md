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
#> # A tibble: 33,516 × 13
#>    bay_seg basin    drnfeat clucsid hydgrp  area dry_rc wet_rc    mo    rc   rca
#>      <dbl> <chr>    <chr>     <dbl> <chr>  <dbl>  <dbl>  <dbl> <int> <dbl> <dbl>
#>  1       1 02307000 CON           8 A       15.2    0.1   0.18     1   0.1  1.52
#>  2       1 02307000 CON           8 A       15.2    0.1   0.18     1   0.1  1.52
#>  3       1 02307000 CON           8 A       15.2    0.1   0.18     1   0.1  1.52
#>  4       1 02307000 CON           8 A       15.2    0.1   0.18     2   0.1  1.52
#>  5       1 02307000 CON           8 A       15.2    0.1   0.18     2   0.1  1.52
#>  6       1 02307000 CON           8 A       15.2    0.1   0.18     2   0.1  1.52
#>  7       1 02307000 CON           8 A       15.2    0.1   0.18     3   0.1  1.52
#>  8       1 02307000 CON           8 A       15.2    0.1   0.18     3   0.1  1.52
#>  9       1 02307000 CON           8 A       15.2    0.1   0.18     3   0.1  1.52
#> 10       1 02307000 CON           8 A       15.2    0.1   0.18     4   0.1  1.52
#> # ℹ 33,506 more rows
#> # ℹ 2 more variables: tot_rca <dbl>, yr <int>
```
