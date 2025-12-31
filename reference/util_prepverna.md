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

## Examples

``` r
fl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
util_prepverna(fl)
#> # A tibble: 497 × 4
#>     Year Month  TNConc   TPConc
#>    <int> <int>   <dbl>    <dbl>
#>  1  1983     8 NA      NA      
#>  2  1983     9  0.0101  0.00123
#>  3  1983    10 NA      NA      
#>  4  1983    11  0.180   0.00337
#>  5  1983    12  0.150   0.00299
#>  6  1984     1  0.265   0.00445
#>  7  1984     2  0.174   0.00330
#>  8  1984     3  0.137   0.00283
#>  9  1984     4  0.324   0.00518
#> 10  1984     5  0.257   0.00434
#> # ℹ 487 more rows
```
