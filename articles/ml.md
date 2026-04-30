# Material Losses (ML)

``` r

library(tbeploads)
```

Material losses (ML) are estimates of nutrient loads to the bay
primarily from fertilizer shipping activities at ports. Historically,
loadings from material losses were much higher than at present. Only a
few entities report material losses, typically as a total for the year
and only for total nitrogen. The material losses as tons/yr are
estimated from the tons shipped using an agreed upon loss rate. Values
reported in the example files represent the estimated loss as the total
tons of N shipped each year multiplied by 0.0023 and divided by 2000.
The total N shipped at a facility each year can be obtained using a
simple back-calculation (multiply by 2000, divide by 0.0023).

The core function is
[`anlz_ml_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml_facility.md)
that requires only a vector of file paths as input, where each file
should be one row per year per facility, where the row shows the total
tons per year of total nitrogen loss. The file names must follow a
specific convention, where metadata for each entity is found in the
[`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
data object using information in the file name.

For convenience, four example files are included with the package. These
files represent actual entities and facilities, but the data have been
randomized. The paths to these files are used as input to the function.
The output is nearly identical to the input data since no load
calculations are used, except results are shown as monthly load as the
annual loss divided by 12. Additional empty columns (e.g., TP load, TSS
load, etc.) are also returned for consistency of reporting with other
loading sources.

``` r

mlfls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_indml', full.names = TRUE)
anlz_ml_facility(mlfls)
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

The
[`anlz_ml()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml.md)
function uses
[`anlz_ml_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml_facility.md)
to summarize the ML results by location as facility, entity (combines
facility data), bay segment (combines entity data), and as all (combines
bay segment data). The results can also be temporally summarized as
monthly or annual totals. The location summary is defined by the `summ`
argument and the temporal summary is defined by the `summtime` argument.
The `fls` argument used by
[`anlz_ml_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml_facility.md)
is also used by
[`anlz_ml()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ml.md).
The output is tons per month of TN if `summtime = 'month'` or tons per
year of TN if `summtime = 'year'`. Columns for TP, TSS, BOD, and
hydrologic load are also returned with zero load for consistency with
other point source load calculation functions. Material loss loads are
often combined with IPS loads for reporting.

``` r

# combine by entity and month
anlz_ml(mlfls, summ = 'entity', summtime = 'month')
#> # A tibble: 60 × 10
#>     Year Month source entity segment   tn_load tp_load tss_load bod_load hy_load
#>    <int> <int> <chr>  <chr>  <chr>       <dbl>   <int>    <int>    <int>   <int>
#>  1  2020     1 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  2  2020     2 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  3  2020     3 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  4  2020     4 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  5  2020     5 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  6  2020     6 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  7  2020     7 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  8  2020     8 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#>  9  2020     9 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#> 10  2020    10 ML     CSX    Hillsbor…  0.0743       0        0        0       0
#> # ℹ 50 more rows

# combine by bay segment and year
anlz_ml(mlfls, summ = "segment", summtime = "year")
#> # A tibble: 5 × 8
#>    Year source segment          tn_load tp_load tss_load bod_load hy_load
#>   <int> <chr>  <chr>              <dbl>   <int>    <int>    <int>   <int>
#> 1  2017 ML     Hillsborough Bay  0.186        0        0        0       0
#> 2  2018 ML     Hillsborough Bay  0.188        0        0        0       0
#> 3  2019 ML     Hillsborough Bay  0.0224       0        0        0       0
#> 4  2020 ML     Hillsborough Bay  0.892        0        0        0       0
#> 5  2021 ML     Hillsborough Bay  0.989        0        0        0       0
```
