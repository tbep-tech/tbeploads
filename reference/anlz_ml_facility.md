# Calculate material loss (ML) loads from raw facility data

Calculate material loss (ML) loads from raw facility data

## Usage

``` r
anlz_ml_facility(fls)
```

## Arguments

- fls:

  vector of file paths to raw facility data, one to many

## Value

data frame that is nearly identical to the input data except results are
shown as monthly load as the annual loss estimate divided by 12. This is
for consistency of reporting with other loading sources.

## Details

Input data should be one row per year per facility, where the row shows
the total tons per year of total nitrogen loss. Input files are often
created by hand based on reported annual tons of nitrogen shipped at
each facility. The material losses as tons/yr are estimated from the
tons shipped using an agreed upon loss rate. Values reported in the
example files represent the estimated loss as the total tons of N
shipped each year multiplied by 0.0023 and divided by 2000. The total N
shipped at a facility each year can be obtained using a simple
back-calculation (multiply by 2000, divide by 0.0023).

## See also

[`anlz_ml`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml.md)

## Examples

``` r
fls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_indml', full.names = TRUE)
anlz_ml_facility(fls)
#> # A tibble: 60 × 11
#>     Year Month entity  facility coastco source tn_load tp_load tss_load bod_load
#>    <int> <int> <chr>   <chr>    <chr>   <lgl>    <dbl> <lgl>   <lgl>    <lgl>   
#>  1  2017     1 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#>  2  2017     2 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#>  3  2017     3 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#>  4  2017     4 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#>  5  2017     5 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#>  6  2017     6 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#>  7  2017     7 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#>  8  2017     8 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#>  9  2017     9 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#> 10  2017    10 Kinder… Kinder … NA      NA      0.0155 NA      NA       NA      
#> # ℹ 50 more rows
#> # ℹ 1 more variable: hy_load <lgl>
```
