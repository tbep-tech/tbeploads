# Industrial Point Source (IPS)

``` r
library(tbeploads)
```

The industrial point source (IPS) functions are designed to work with
raw entity data provided by partners and are similar in functionality to
the DPS functions. The core function is
[`anlz_ips_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips_facility.md)
that requires only a vector of file paths as input, where each path
points to a file with monthly parameter concentration (mg/L) and flow
data (million gallons per day). Loads are estimated as concentration
times flow. The file names must follow a specific convention, where
metadata for each entity is found in the
[`facilities`](https://tbep-tech.github.io/tbeploads/reference/facilities.md)
data object using information in the file name.

For convenience, four example files are included with the package. These
files represent actual entities and facilities, but the data have been
randomized. The paths to these files are used as input to the function.
As before, non-trivial data pre-processing and quality control is needed
for each file and those included in the package are the correct format.
The output is returned as tons per month for TN, TP, TSS, and BOD and
million cubic meters per month for flow (hy).

``` r
ipsfls <- list.files(system.file('extdata/', package = 'tbeploads'),
  pattern = 'ps_ind_', full.names = TRUE)
anlz_ips_facility(ipsfls)
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

The
[`anlz_ips()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips.md)
function uses
[`anlz_ips_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips_facility.md)
to summarize the IPS results by location as facility (combines outfall
data), entity (combines facility data), bay segment (combines entity
data), and as all (combines bay segment data). The results can also be
temporally summarized as monthly or annual totals. The location summary
is defined by the `summ` argument and the temporal summary is defined by
the `summtime` argument. The `fls` argument used by
[`anlz_ips_facility()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips_facility.md)
is also used by
[`anlz_ips()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ips.md).
The output is tons per month for TN, TP, TSS, and BOD and as million
cubic meters per month for flow (hy) if `summtime = 'month'` or tons per
year for TN, TP, TSS, and BOD and million cubic meters per year for flow
(hy) if `summtime = 'year'`.

``` r
# combine by entity and month
anlz_ips(ipsfls, summ = 'entity', summtime = 'month')
#> # A tibble: 60 × 10
#>     Year Month source entity   segment tn_load tp_load tss_load bod_load hy_load
#>    <int> <int> <chr>  <chr>    <chr>     <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#>  1  2020     1 IPS    Busch G… Hillsb…  0.0195 0.00253    0.443    0.850  0.0804
#>  2  2020     2 IPS    Busch G… Hillsb…  0.0306 0.00328    0.544    1.04   0.0987
#>  3  2020     3 IPS    Busch G… Hillsb…  0.0972 0.00925    1.39     2.68   0.253 
#>  4  2020     4 IPS    Busch G… Hillsb…  0.0398 0.0258     0.522    1.00   0.0946
#>  5  2020     5 IPS    Busch G… Hillsb…  0.0820 0.00514    0.506    0.971  0.0917
#>  6  2020     6 IPS    Busch G… Hillsb…  0.0112 0.00594    0.355    0.681  0.0644
#>  7  2020     7 IPS    Busch G… Hillsb…  0.0430 0.00413    0.506    0.971  0.0918
#>  8  2020     8 IPS    Busch G… Hillsb…  0.0167 0.00225    0.199    0.382  0.0361
#>  9  2020     9 IPS    Busch G… Hillsb…  0.0226 0.00307    0.332    0.638  0.0603
#> 10  2020    10 IPS    Busch G… Hillsb…  0.0187 0.0186     0.333    0.638  0.0603
#> # ℹ 50 more rows

# combine by bay segment and year
anlz_ips(ipsfls, summ = "segment", summtime = "year")
#> # A tibble: 5 × 8
#>    Year source segment          tn_load tp_load tss_load bod_load hy_load
#>   <int> <chr>  <chr>              <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#> 1  2017 IPS    Hillsborough Bay  0.215   0.0612   0           0    0.188 
#> 2  2018 IPS    Hillsborough Bay  0.168   0.0456   0           0    0.140 
#> 3  2019 IPS    Hillsborough Bay  0.0950  0.0226   0           0    0.0763
#> 4  2020 IPS    Hillsborough Bay  0.437   0.0858   6.11       11.7  1.11  
#> 5  2021 IPS    Hillsborough Bay  0.0305  0.0515   0.0662      0    0.0184
```
