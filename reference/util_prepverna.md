# Prep Verna Wellfield data for use in AD and NPS calculations

Prep Verna Wellfield data for use in AD and NPS calculations

## Usage

``` r
util_prepverna(fl, fillmis = T)
```

## Arguments

- fl:

  text string for the file path to the Verna Wellfield data

- fillmis:

  logical indicating whether to fill missing data with monthly means,
  see details

## Value

A data frame with total nitrogen and phosphorus estimates as mg/l for
each year and month of the input data

## Details

Raw data can be obtained from
<https://nadp.slh.wisc.edu/sites/ntn-FL41/> as monthly observations.
Total nitrogen and phosphorus concentrations are estimated from ammonium
and nitrate concentrations (mg/L) using the following relationships:

\$\$TN = NH_4^+ \* 0.78 + NO_3^- \* 0.23\$\$ \$\$TP = 0.01262 \* TN +
0.00110\$\$

The first equation corrects for the % of ions in ammonium and nitrate
that is N, and the second is a regression relationship between TBADS TN
and TP, applied to Verna.

Missing data (-9 values) can be filled using monthly means from the
previous five years where data exist for that month. If there are less
than five previous years of data for that month, the missing value is
not filled.

Years with incomplete seasonal data will be filled with NA values if
`fillmis = FALSE` or filled with monthly means if `fillmis = TRUE`.

## Examples

``` r
fl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
util_prepverna(fl)
#> # A tibble: 504 × 4
#>     Year Month  TNConc   TPConc
#>    <int> <int>   <dbl>    <dbl>
#>  1  1983     1 NA      NA      
#>  2  1983     2 NA      NA      
#>  3  1983     3 NA      NA      
#>  4  1983     4 NA      NA      
#>  5  1983     5 NA      NA      
#>  6  1983     6 NA      NA      
#>  7  1983     7 NA      NA      
#>  8  1983     8 NA      NA      
#>  9  1983     9  0.0101  0.00123
#> 10  1983    10 NA      NA      
#> # ℹ 494 more rows
```
