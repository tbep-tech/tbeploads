# Calculate DPS reuse and end of pipe loads from raw facility data

Calculate DPS reuse and end of pipe loads from raw facility data

## Usage

``` r
anlz_dps_facility(fls)
```

## Arguments

- fls:

  vector of file paths to raw facility data, one to many

## Value

data frame with loading data for TP, TN, TSS, and BOD as tons per month
and hydro load as million cubic meters per month. Information for each
entity, facility, and outfall is retained.

## Details

Input data should include flow as million gallons per day, and conc as
mg/L. Steps include:

1.  Multiply flow by day in month to get million gallons per month

2.  Multiply flow by 3785.412 to get cubic meters per month

3.  Multiply conc by flow and divide by 1000 to get kg var per month

4.  Multiply m3 by 1000 to get L, then divide by 1e6 to convert mg to
    kg, same as dividing by 1000

5.  TN, TP, TSS, BOD dps reuse is multiplied by attenuation factor for
    land application (varies by location)

6.  Hydro load (m3 / mo) is also attenuated for the reuse, multiplied by
    0.6 (40% attenuation)

## See also

[`anlz_dps`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md)

## Examples

``` r
fls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_dom', full.names = TRUE)
anlz_dps_facility(fls)
#> # A tibble: 144 × 11
#>     Year Month entity  facility coastco source tn_load tp_load tss_load bod_load
#>    <int> <int> <chr>   <chr>    <chr>   <chr>    <dbl>   <dbl>    <dbl>    <dbl>
#>  1  2021     1 Clearw… City of… 387     D-001    0.862  6.04     0.452     1.14 
#>  2  2021     2 Clearw… City of… 387     D-001    1.37   1.15     0.553     2.87 
#>  3  2021     3 Clearw… City of… 387     D-001    1.70   0.575    0.982     3.31 
#>  4  2021     4 Clearw… City of… 387     D-001    0.344  0.0801   0.105     0.656
#>  5  2021     5 Clearw… City of… 387     D-001    1.09   0.460    0.603     2.23 
#>  6  2021     6 Clearw… City of… 387     D-001    0.641  0.435    0.248     0.588
#>  7  2021     7 Clearw… City of… 387     D-001    0.667  0.183    0.360     1.33 
#>  8  2021     8 Clearw… City of… 387     D-001    0.138  0.164    0.0601    0.327
#>  9  2021     9 Clearw… City of… 387     D-001    0.421  1.63     0.281     0.655
#> 10  2021    10 Clearw… City of… 387     D-001    1.15   0.217    0.563     0.666
#> # ℹ 134 more rows
#> # ℹ 1 more variable: hy_load <dbl>
```
