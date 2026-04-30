# Domestic Point Source (DPS)

``` r

library(tbeploads)
```

The domestic point source (DPS) functions are designed to work with raw
entity data provided by partners. The core function is
[`anlz_dps_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps_facility.md)
that requires only a vector of file paths as input, where each path
points to a file with monthly parameter concentration (mg/L) and flow
data (million gallons per day). The data also describe whether the
observations are end of pipe (direct inflow to the bay) or reuse
(applied to the land), with each defined by outfall Ids typically noted
as D-001, D-002, etc. and R-001, R-002, etc, respectively. Both are
estimated as concentration times flow, whereas reuse includes an
attenuation factor for land application depending on location. The file
names must follow a specific convention, where metadata for each entity
is found in the
[`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
data object using information in the file name.

For convenience, four example files are included with the package. These
files represent actual entities and facilities, but the data have been
randomized. The paths to these files are used as input to the function.
Non-trivial data pre-processing and quality control is needed for each
file and those included in the package are the correct format. The
output is returned as tons per month for TN, TP, TSS, and BOD and
million cubic meters per month for flow (hy).

``` r

dpsfls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_dom', full.names = TRUE)
anlz_dps_facility(dpsfls)
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

The
[`anlz_dps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md)
function uses
[`anlz_dps_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps_facility.md)
to summarize the DPS results by location as facility (combines outfall
data), entity (combines facility data), bay segment (combines entity
data), and as all (combines bay segment data). The results can also be
temporally summarized as monthly or annual totals. The location summary
is defined by the `summ` argument and the temporal summary is defined by
the `summtime` argument. The `fls` argument used by
[`anlz_dps_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps_facility.md)
is also used by
[`anlz_dps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_dps.md).
The output is tons per month for TN, TP, TSS, and BOD and as million
cubic meters per month for flow (hy) if `summtime = 'month'` or tons per
year for TN, TP, TSS, and BOD and million cubic meters per year for flow
(hy) if `summtime = 'year'`.

``` r

# combine by entity and month
anlz_dps(dpsfls, summ = 'entity', summtime = 'month')
#> # A tibble: 108 × 10
#>     Year Month source   entity segment tn_load tp_load tss_load bod_load hy_load
#>    <int> <int> <chr>    <chr>  <chr>     <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#>  1  2021     1 DPS - e… Clear… Old Ta…  0.862  6.04     0.452    1.14     0.663 
#>  2  2021     1 DPS - r… Clear… Old Ta…  0.102  0.00852  0.00844  0.0473   0.165 
#>  3  2021     2 DPS - e… Clear… Old Ta…  1.37   1.15     0.553    2.87     0.948 
#>  4  2021     2 DPS - r… Clear… Old Ta…  0.210  0.0416   0.0169   0.0244   0.319 
#>  5  2021     3 DPS - e… Clear… Old Ta…  1.70   0.575    0.982    3.31     1.83  
#>  6  2021     3 DPS - r… Clear… Old Ta…  0.261  0.0439   0.0194   0.0554   0.417 
#>  7  2021     4 DPS - e… Clear… Old Ta…  0.344  0.0801   0.105    0.656    0.194 
#>  8  2021     4 DPS - r… Clear… Old Ta…  0.0472 0.00602  0.00245  0.00499  0.0563
#>  9  2021     5 DPS - e… Clear… Old Ta…  1.09   0.460    0.603    2.23     0.874 
#> 10  2021     5 DPS - r… Clear… Old Ta…  0.0354 0.00281  0.00298  0.00885  0.0729
#> # ℹ 98 more rows

# combine by bay segment and year
anlz_dps(dpsfls, summ = "segment", summtime = "year")
#> # A tibble: 9 × 8
#>    Year source            segment      tn_load tp_load tss_load bod_load hy_load
#>   <int> <chr>             <chr>          <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#> 1  2017 DPS - end of pipe Hillsboroug…   0.891 1.20e-1  2.90e-1  6.92e-1 5.25e-1
#> 2  2017 DPS - reuse       Hillsboroug… 464.    2.94e+1  5.10e+1  1.70e+2 1.10e+3
#> 3  2018 DPS - end of pipe Hillsboroug… 102.    1.49e+1  3.58e+1  8.24e+1 6.43e+1
#> 4  2018 DPS - reuse       Hillsboroug…  28.6   8.80e-1  1.82e+0  4.88e+0 3.95e+1
#> 5  2019 DPS - end of pipe Hillsboroug…  14.4   1.63e+0  2.92e+0  9.17e+0 6.55e+0
#> 6  2019 DPS - reuse       Hillsboroug…   4.21  8.47e-2  1.33e-1  5.20e-1 3.82e+0
#> 7  2021 DPS - reuse       Hillsboroug…   2.90  1.61e-9  1.61e-9  1.61e-9 1.76e+0
#> 8  2021 DPS - end of pipe Old Tampa B…   8.62  1.11e+1  4.34e+0  1.43e+1 7.35e+0
#> 9  2021 DPS - reuse       Old Tampa B…   1.48  2.35e-1  1.19e-1  7.17e-1 2.39e+0
```
