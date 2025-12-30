# Event Mean Concentration (EMC) data for CLUCSID in Tampa Bay

Event Mean Concentration (EMC) data for CLUCSID in Tampa Bay

## Usage

``` r
emc
```

## Format

A `data.frame`

## Details

Used for non-point source (NPS) ungaged estimates summaries.

Values are grouped by CLUCSID and include mean TN, TP, TSS, and BOD.

See "data-raw/emc.R" for creation.

## Examples

``` r
emc
#> # A tibble: 22 × 7
#>    clucsid `_TYPE_` `_FREQ_` mean_tn mean_tp mean_tss mean_bod
#>      <dbl>    <dbl>    <dbl>   <dbl>   <dbl>    <dbl>    <dbl>
#>  1       1        0        7    1.90   0.313     17.9     4.4 
#>  2       2        0        3    2.23   0.341     36.3     7.4 
#>  3       3        0       13    2.08   0.369     63.8    11   
#>  4       4        0        3    1.95   0.28      82.7    17.2 
#>  5       5        0        4    1.64   0.267     93.9     9.6 
#>  6       6        0        1    1.18   0.15      50       9.6 
#>  7       7        0        1    1.18   0.15      20       8.2 
#>  8       8        0        1    1.24   0.01      11       1.45
#>  9       9        0        1    1.24   0.01      11       1.45
#> 10      10        0        1    2.66   0.81       8.6     5.1 
#> # ℹ 12 more rows
```
