# Calculate IPS loads from raw facility data

Calculate IPS loads from raw facility data

## Usage

``` r
anlz_ips_facility(fls)
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

## See also

[`anlz_dps`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md)

## Examples

``` r
fls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_ind_', full.names = TRUE)
anlz_ips_facility(fls)
#> # A tibble: 60 × 11
#>     Year Month entity  facility coastco source tn_load tp_load tss_load bod_load
#>    <int> <int> <chr>   <chr>    <chr>   <chr>    <dbl>   <dbl>    <dbl>    <dbl>
#>  1  2020     1 Busch … Busch G… 191a    D-002   0.0195 0.00253    0.443    0.850
#>  2  2020     2 Busch … Busch G… 191a    D-002   0.0306 0.00328    0.544    1.04 
#>  3  2020     3 Busch … Busch G… 191a    D-002   0.0972 0.00925    1.39     2.68 
#>  4  2020     4 Busch … Busch G… 191a    D-002   0.0398 0.0258     0.522    1.00 
#>  5  2020     5 Busch … Busch G… 191a    D-002   0.0820 0.00514    0.506    0.971
#>  6  2020     6 Busch … Busch G… 191a    D-002   0.0112 0.00594    0.355    0.681
#>  7  2020     7 Busch … Busch G… 191a    D-002   0.0430 0.00413    0.506    0.971
#>  8  2020     8 Busch … Busch G… 191a    D-002   0.0167 0.00225    0.199    0.382
#>  9  2020     9 Busch … Busch G… 191a    D-002   0.0226 0.00307    0.332    0.638
#> 10  2020    10 Busch … Busch G… 191a    D-002   0.0187 0.0186     0.333    0.638
#> # ℹ 50 more rows
#> # ℹ 1 more variable: hy_load <dbl>
```
