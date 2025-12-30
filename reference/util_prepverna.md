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
#> # A tibble: 168 × 4
#>     Year Month TNConc   TPConc
#>    <int> <int>  <dbl>    <dbl>
#>  1  2011     1  0.163  0.00316
#>  2  2011     2  0.271  0.00453
#>  3  2011     3  0.116  0.00256
#>  4  2011     4  0.472  0.00706
#>  5  2011     5 NA     NA      
#>  6  2011     6  0.393  0.00606
#>  7  2011     7  0.214  0.00380
#>  8  2011     8  0.255  0.00432
#>  9  2011     9  0.166  0.00319
#> 10  2011    10  0.119  0.00260
#> # ℹ 158 more rows
```
