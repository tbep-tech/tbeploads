# Utility function for non-point source (NPS) ungaged workflow to prepare land use and soil data for logistic regression

Utility function for non-point source (NPS) ungaged workflow to prepare
land use and soil data for logistic regression

## Usage

``` r
util_nps_preplog(tbbase)
```

## Arguments

- tbbase:

  Input data frame returned from
  [`util_nps_tbbase`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md).

## Value

A data frame with land use and soil areas in long format with bay
segment and basins in the rows.

## Examples

``` r
util_nps_preplog(tbbase)
#> # A tibble: 49 × 101
#> # Groups:   bay_seg [8]
#>    bay_seg basin  C_C01A C_C01B   C_C01C C_C01D   C_C02A   C_C02B C_C02C  C_C03A
#>      <dbl> <chr>   <dbl>  <dbl>    <dbl>  <dbl>    <dbl>    <dbl>  <dbl>   <dbl>
#>  1       1 02307…   1.81 NA     NA           NA  1.78    NA       NA     NA     
#>  2       1 02307…  29.7   0.339  0.178       NA  2.89    NA       NA      2.59  
#>  3       1 206-1    5.97  0.891 NA           NA  0.759    4.78e-1  1.02   4.51  
#>  4       1 206-3C  NA    NA     NA           NA NA       NA       NA     NA     
#>  5       1 206-3W  NA    NA     NA           NA NA       NA       NA     NA     
#>  6       1 LTARP…  29.8  NA     NA           NA  3.09    NA       NA      3.28  
#>  7       2 02300…  NA    NA     NA           NA NA       NA       NA     NA     
#>  8       2 02300…   5.03  2.58   0.00573     NA  0.00963  6.91e-4 NA      1.53  
#>  9       2 02301…  10.8   0.586  0.105       NA  1.47    NA        0.813  0.0355
#> 10       2 02301…   9.67 NA      0.687       NA NA       NA       NA     NA     
#> # ℹ 39 more rows
#> # ℹ 91 more variables: C_C03B <dbl>, C_C03C <dbl>, C_C04A <dbl>, C_C04B <dbl>,
#> #   C_C04C <dbl>, C_C05A <dbl>, C_C05B <dbl>, C_C05C <dbl>, C_C06A <dbl>,
#> #   C_C06B <dbl>, C_C06C <dbl>, C_C06D <dbl>, C_C07A <dbl>, C_C07B <dbl>,
#> #   C_C07C <dbl>, C_C07D <dbl>, C_C08A <dbl>, C_C08B <dbl>, C_C08C <dbl>,
#> #   C_C08D <dbl>, C_C09A <dbl>, C_C09B <dbl>, C_C09C <dbl>, C_C10A <dbl>,
#> #   C_C10B <dbl>, C_C10C <dbl>, C_C10D <dbl>, C_C11A <dbl>, C_C11B <dbl>, …
```
