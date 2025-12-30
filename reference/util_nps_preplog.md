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
#> # A tibble: 69 × 145
#> # Groups:   bay_seg [8]
#>    bay_seg basin       C_C01A C_C01B  C_C01C C_C01D     C_C02A C_C02B   C_C02C
#>      <dbl> <chr>        <dbl>  <dbl>   <dbl>  <dbl>      <dbl>  <dbl>    <dbl>
#>  1       1 02304500    0.0116  NA    NA          NA    0.0706   NA     NA     
#>  2       1 02306647  207.       3.08  0.0772     NA  930.       40.7   NA     
#>  3       1 02307000 1123.      16.2   5.48       NA 1666.       33.9    7.89  
#>  4       1 02307359 1593.      29.1  13.9        NA  935.        6.59   0.0269
#>  5       1 205-2      NA       NA    NA          NA    0.00917  NA     NA     
#>  6       1 206-1     710.     125.   89.6        NA 1830.      193.   190.    
#>  7       1 206-2      NA       NA    NA          NA   NA        NA     NA     
#>  8       1 206-3C     NA       NA    NA          NA   NA        NA     NA     
#>  9       1 206-3W     NA       NA    NA          NA   NA        NA     NA     
#> 10       1 207-5      NA       NA    NA          NA    0.00142  NA     NA     
#> # ℹ 59 more rows
#> # ℹ 136 more variables: C_C02D <dbl>, C_C03A <dbl>, C_C03B <dbl>, C_C03C <dbl>,
#> #   C_C03D <dbl>, C_C04A <dbl>, C_C04B <dbl>, C_C04C <dbl>, C_C04D <dbl>,
#> #   C_C05A <dbl>, C_C05B <dbl>, C_C05C <dbl>, C_C05D <dbl>, C_C06A <dbl>,
#> #   C_C06B <dbl>, C_C06C <dbl>, C_C06D <dbl>, C_C07A <dbl>, C_C07B <dbl>,
#> #   C_C07C <dbl>, C_C07D <dbl>, C_C08A <dbl>, C_C08B <dbl>, C_C08C <dbl>,
#> #   C_C08D <dbl>, C_C09A <dbl>, C_C09B <dbl>, C_C09C <dbl>, C_C09D <dbl>, …
```
