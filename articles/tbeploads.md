# Getting started

## Installation

Install the package from
[r-universe](http://tbep-tech.r-universe.dev/ui/#builds) as follows. The
source code is available on
[GitHub](https://github.com/tbep-tech/tbeploads).

``` r
# Install tbeploads in R:
install.packages('tbeploads', repos = c('https://tbep-tech.r-universe.dev', 'https://cloud.r-project.org'))
```

Load the package in an R session after installation:

``` r
library(tbeploads)
```

## Usage

Load estimates are broadly defined as domestic point source (DPS),
industrial point source (IPS), material losses (ML), nonpoint source
(NPS), atmospheric deposition (AD), and groundwater sources and springs
(GW). The functions are built around these sources with unique inputs
for each.

### DPS

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

### IPS

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

### ML

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
to summarize the IPS results by location as facility, entity (combines
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

### AD

Loading from atmospheric deposition (AD) for bay segments in the Tampa
Bay watershed are calculated using rainfall data from weather stations
in the watershed and atmospheric concentration data from the Verna
Wellfield site. Rainfall data must be obtained using the
[`util_getrain()`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)
function before calculating loads. For convenience, daily rainfall data
from 2017 to 2023 at sites in the watershed are included with the
package in the
[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md)
object.

``` r
head(rain)
#> # A tibble: 6 × 6
#>   station date        Year Month   Day rainfall
#>     <dbl> <date>     <int> <dbl> <int>    <dbl>
#> 1     228 2017-01-01  2017     1     1     0   
#> 2     228 2017-01-02  2017     1     2     0   
#> 3     228 2017-01-03  2017     1     3     0   
#> 4     228 2017-01-04  2017     1     4     0   
#> 5     228 2017-01-05  2017     1     5     0.02
#> 6     228 2017-01-06  2017     1     6     0
```

The Verna Wellfield data must also be obtained from
<https://nadp.slh.wisc.edu/sites/ntn-FL41/> as monthly observations.
This file is also included with the package and can be found using
[`system.file()`](https://rdrr.io/r/base/system.file.html) as follows:

``` r
vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')
vernafl
#> [1] "/home/runner/work/_temp/Library/tbeploads/extdata/verna-raw.csv"
```

During load calculation, the Verna data are converted to total nitrogen
and total phosphorus from ammonium and nitrate concentration data using
the
[`util_prepverna()`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md)
function. Total nitrogen and phosphorus concentrations are estimated
from ammonium and nitrate concentrations (mg/L) using the following
relationships:

$$TN = NH_{4}^{+}*0.78 + NO_{3}^{-}*0.23$$

$$TP = 0.01262*TN + 0.00110$$

The first equation corrects for the % of ions in ammonium and nitrate
that are N, and the second is a regression relationship between TBADS TN
and TP, applied to Verna.

AD loads are estimated using the
[`anlz_ad()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ad.md)
function, where total hydrologic load by bay segment is calculated from
the rain data and total nitrogen and phosphorus load is calculated by
multiplying hydrologic load by the atmospheric deposition concentrations
from the Verna data. Total hydrologic load for each bay segment is
calculated using daily estimates of rainfall at NWIS NCDC sites in the
watershed. This is done as a weighted mean of rainfall at the measured
sites relative to grid locations in each bay segment. The weights are
based on distance of the grid cells from the closest site as inverse
distance squared. Total hydrologic load for a sub-watershed is then
estimated by converting inches/month to m3/month using the area of each
bay segment. The distance data and bay segment areas are contained in
the file included with the package.

``` r
head(ad_distance)
#>   segment    seg_x   seg_y matchsit  distance     invdist2     area
#> 1       1 344902.2 3080488      520 26000.117 1.479277e-09 23407.05
#> 2       1 344902.2 3080488      940 39711.285 6.341210e-10 23407.05
#> 3       1 344902.2 3080488      945 44691.735 5.006631e-10 23407.05
#> 4       1 344902.2 3080488     1632 22105.640 2.046416e-09 23407.05
#> 5       1 344902.2 3080488     2806  8649.245 1.336730e-08 23407.05
#> 6       1 344902.2 3080488     3986 47920.032 4.354776e-10 23407.05
```

The total nitrogen and phosphorus loads are then estimated for each bay
segment by multiplying the total hydrologic load by the total nitrogen
and phosphorus concentrations in the Verna data. The loading
calculations also include a wet/dry deposition conversion factor to
account for differences in loading during the rainy and dry seasons.

Using
[`anlz_ad()`](https://tbep-tech.github.io/tbeploads/reference/anlz_ad.md)
to estimate AD load is done as follows, where
[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md) is the
rain data and `vernafl` is the path to the Verna Wellfield data.

``` r
anlz_ad(rain, vernafl)
#> # A tibble: 672 × 7
#>     Year Month source segment        tn_load tp_load hy_load
#>    <int> <dbl> <chr>  <chr>            <dbl>   <dbl>   <dbl>
#>  1  2017     1 AD     Boca Ciega Bay   0.721  0.0140    1.98
#>  2  2017     2 AD     Boca Ciega Bay   0.945  0.0168    1.95
#>  3  2017     3 AD     Boca Ciega Bay   0.950  0.0181    2.48
#>  4  2017     4 AD     Boca Ciega Bay   3.05   0.0482    3.90
#>  5  2017     5 AD     Boca Ciega Bay   9.06   0.131     6.89
#>  6  2017     6 AD     Boca Ciega Bay   9.67   0.178    22.5 
#>  7  2017     7 AD     Boca Ciega Bay  10.8    0.189    26.2 
#>  8  2017     8 AD     Boca Ciega Bay   5.58   0.120    24.6 
#>  9  2017     9 AD     Boca Ciega Bay   2.14   0.0553   14.1 
#> 10  2017    10 AD     Boca Ciega Bay   2.03   0.0368    5.56
#> # ℹ 662 more rows
```

Results can be summarized by segment, baywide, monthly, or annually
using the `summ` and `summtime` arguments. By default, loads are
returned monthly for each segment. Note that Boca Ciega Bay and Boca
Ciega Bay South results are returned separately. Only Boca Ciega Bay
South is used when estimating total bay loads.

### NPS

Non-point source (NPS) estimates are obtained for gaged and ungaged
locations in the watershed, then combined for the final result. Skip to
the [final sub-section](#nps-final) to understand how to obtain all
estimates together. Separate approaches for gaged and ungaged estimates
are described first for documentation purposes.

#### Gaged locations

Gaged estimates are obtained using the
[`anlz_nps_gaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md)
function that retrieves flow and water quality data, then combines them
to calculate TN, TP, TSS, BOD, and hydrologic loads.

Required external flow data are Lake Manatee, Tampa Bypass, and Alafia
River Bell Shoals. These are not available from the USGS API and must be
obtained from the contacts listed in
[`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md).
USGS flow data are obtained from an API for stations 02299950, 02300042,
02300500, 02300700, 02301000, 02301300, 02301500, 02301750, 02303000,
02303330, 02304500, 02306647, 02307000, 02307359, and 02307498. A
preprocessed USGS flow data frame can be provided to the `usgsflow`
argument. The
[`usgsflow`](https://tbep-tech.github.io/tbeploads/reference/usgsflow.md)
data object is provided with the package to avoid re-downloading the
data. Similarly, all flow data can be provided to the `allflo` argument.
The
[`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
data object included with the package has both external and USGS flow
data.

Water Quality data are obtained from the FDEP WIN database API,
tbeptools, or local files as described in
[`util_nps_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md).
Chosen stations are ER2 and UM2 for Manatee County and station 06-06 for
Pinellas County. Environmental Protection Commission (EPC) of
Hillsborough County stations retained are 105, 113, 114, 132, 141, 138,
142, and 147. Manatee or Pinellas County data can be imported from local
files using the `mancopth` and `pincopth` arguments, respectively. If
these are not provided, the function will attempt to retrieve data from
the FDEP WIN database using `read_importwqwin()` from tbeptools. The EPC
data are retrieved using `read_importepc()` from tbeptools. The
[`allwq`](https://tbep-tech.github.io/tbeploads/reference/allwq.md) data
object included with the package has external data and USGS flow data
and can used with the `allwq` argument.

The function assumes that the water quality data are in mg/L and flow
data are in cfs. Missing water quality data are filled with previous
five year averages for the end months, then linearly interpolated using
[`util_nps_fillmiswq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_fillmiswq.md).

Water quality and flow inputs to
[`anlz_nps_gaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md)
can be provided numerous ways:

1.  Manatee and Pinellas County water quality data provided as local
    files and EPC data automatically retrieved from the API
2.  All water quality data provided locally using a single object with
    the `allwq` argument (see the
    [`allwq`](https://tbep-tech.github.io/tbeploads/reference/allwq.md)
    dataset for the format, created using
    [`util_nps_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md))
3.  Flow data provided using local files for Lake Manatee, Bell Shoals,
    and Tampa Bypass, USGS data retrieved automatically from the API
4.  Flow data provided using local files for Lake Manatee, Bell Shoals,
    and Tampa Bypass, USGS data provided locally using the `usgsflow`
    argument (see the
    [`usgsflow`](https://tbep-tech.github.io/tbeploads/reference/usgsflow.md)
    dataset for the format, created using
    [`util_nps_getusgsflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md))
5.  All flow data provided locally using the `allflo` argument (see the
    [`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
    dataset for the format, created using
    [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)).

In all cases, input data can retrieved from APIs with the exception of
flow data for Lake Manatee, Bell Shoals, and Tampa Bypass (see the help
file for
[`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md)
for how to get these data). The following example uses combined water
quality and flow data included with the package for convenience.

``` r
# external files included with the package
data(allwq)
data(allflo)

# get gaged NPS loads
nps_gaged <- anlz_nps_gaged(yrrng = c('2021-01-01', '2023-12-31'), allwq = allwq, allflo = allflo)
#> Estimating gaged NPS loads...

head(nps_gaged)
#> # A tibble: 6 × 13
#>   basin      yr    mo tn_mgl tp_mgl tss_mgl bod_mgl   flow h2oload tnload tpload
#>   <chr>   <dbl> <dbl>  <dbl>  <dbl>   <dbl>   <dbl>  <dbl>   <dbl>  <dbl>  <dbl>
#> 1 023005…  2021     1  0.862  0.222      NA      NA 4.71e9  4.71e6  4063.  1046.
#> 2 023005…  2021     2  1.13   0.358      NA      NA 9.10e9  9.10e6 10280.  3257.
#> 3 023005…  2021     3  0.941  0.327      NA      NA 4.62e9  4.62e6  4351.  1512.
#> 4 023005…  2021     4  0.964  0.44       NA      NA 8.04e9  8.04e6  7755.  3540.
#> 5 023005…  2021     5  0.334  0.286      NA      NA 2.07e9  2.07e6   692.   593.
#> 6 023005…  2021     6  0.871  0.341      NA      NA 4.12e9  4.12e6  3585.  1403.
#> # ℹ 2 more variables: tssload <dbl>, bodload <dbl>
```

In all use cases for the function, a data frame is returned with columns
for basin, year, month, TN in mg/L, TP in mg/L, TSS in mg/L, BOD in
mg/L, flow in liters/month, hydrologic load in m3/month, TN load in
kg/month, TP load in kg/month, TSS load in kg/month, and BOD load in
kg/month.

#### Ungaged locations

Ungaged (unmonitored basins) estimates are obtained using
[`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md).
The approach combines spatial land use data, rainfall patterns,
hydrologic modeling, and empirical relationships to estimate monthly
nutrient and sediment loads. The function requires combined spatial data
for bay segment, basin, entity jurisdiction, land use data, and soils
(obtained with
[`util_nps_tbbase()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)),
rainfall data (obtained with
[`util_getrain()`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)),
and flow data (obtained with
[`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)).

The first step is updating the combined spatial data if any of the input
datasets have changed. The required inputs are land use
([`tblu2023`](https://tbep-tech.github.io/tbeploads/reference/tblu2023.md)),
soil data
([`tbsoil`](https://tbep-tech.github.io/tbeploads/reference/tbsoil.md)),
jurisdiction
([`tbjuris`](https://tbep-tech.github.io/tbeploads/reference/tbjuris.md)),
and sub-basin data
([`tbsubshed`](https://tbep-tech.github.io/tbeploads/reference/tbsubshed.md)).
The function
[`util_nps_tbbase()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_tbbase.md)
combines these datasets into a single spatial object that is used for
ungaged load estimation using
[`util_nps_union()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_union.md).
The function requires GDAL to be installed and accessible in the system
PATH, or the path to GDAL binaries can be provided using the `gdal_path`
argument.

Land use and soil data can be updated using the
[`util_nps_getswfwmd()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getswfwmd.md)
function. These data are also stored internally with the package for
easy retrieval, as are the remaining datasets.

``` r
tblu2023 <- util_nps_getswfwmd('lulc2023')
tbsoil <- util_nps_getswfwmd('soil')
```

Then, the combined layer,
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md),
can be created (takes an hour or two).

``` r
data(tbsubshed)
data(tbjuris)
data(tblu2023)
data(tbsoil)
tbbase <- util_nps_tbbase(tbsubshed, tbjuris, tblu2023, tbsoil, gdal_path = "C:/OSGeo4W/bin", chunk_size = 1000)
```

The
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md)
data object is also included with the package for convenience.

``` r
head(tbbase)
#> # A tibble: 6 × 9
#>   bay_seg basin    drnfeat entity     FLUCCSCODE CLUCSID IMPROVED hydgrp area_ha
#>     <dbl> <chr>    <chr>   <chr>           <dbl>   <dbl>    <int> <chr>    <dbl>
#> 1       1 02304500 LAKE    HILLSBORO…       1100       1        1 A      0.00253
#> 2       1 02304500 LAKE    HILLSBORO…       1100       1        1 A/D    0.00653
#> 3       1 02304500 LAKE    HILLSBORO…       1200       2        1 A      0.0321 
#> 4       1 02304500 LAKE    HILLSBORO…       1200       2        1 A/D    0.0126 
#> 5       1 02304500 LAKE    HILLSBORO…       1400       4        1 A      0.00969
#> 6       1 02304500 LAKE    HILLSBORO…       1400       4        1 A/D    0.00779
```

Next, rainfall data must be obtained for the watershed. These data can
be obtained using the
[`util_getrain()`](https://tbep-tech.github.io/tbeploads/reference/util_getrain.md)
function. The function retrieves daily rainfall data from NWIS NCDC
stations in the watershed and returns a data frame with daily rainfall
totals for each station. These data are always provided to the
[`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md)
using the `rain` argument and not downloaded automatically to reduce
execution time. The
[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md) data
object included with the package is provided for convenience.

Flow data are also required to estimate ungaged loads. This is the same
dataset used to estimate gaged loads. These data can be obtained using
the
[`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)
function. The function retrieves flow data from USGS stations in the
watershed and also uses external flow data for Lake Manatee, Tampa
Bypass, and Bell Shoals (see the help file for
[`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md)
for how to retrieve these data). A preprocessed USGS flow data frame can
be provided to the `usgsflow` argument. The
[`usgsflow`](https://tbep-tech.github.io/tbeploads/reference/usgsflow.md)
data object is provided with the package to avoid re-downloading the
data. Similarly, all flow data can be provided to the `allflo` argument.
The
[`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
data object included with the package has both external and USGS flow
data.

Once the required data are prepared, ungaged loads can be estimated
using
[`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md).
The following describes the general methods for how the ungaged loads
are estimated in four steps.

##### 1. Data Preparation

Using the inptus described above, the first step processes land use data
for logistic regression modeling and calculates inverse
distance-weighted rainfall data for each sub-basin. This ensures that
each basin receives rainfall estimates that account for spatial
variability across the watershed based on the proximity and influence of
nearby rain gauges.

##### 2. Flow Estimation

A logistic regression model predicts monthly streamflow in ungaged
basins using several key variables:

- **Rainfall variables**: Current month rainfall plus 2-month lagged
  rainfall to capture antecedent moisture conditions
- **Land use percentages**: Proportions of urban, agriculture, wetlands,
  and forest cover within each basin
- **Seasonal patterns**: Separate treatment for wet season
  (July-October) and dry season (November-June)
- **Urban development intensity**: Basins are classified into Group A
  (\<19% urban) or Group B (≥19% urban)
- **Hydrologic soil characteristics**: Soil group properties that
  influence infiltration and runoff

##### 3. Runoff Coefficient Application

Land use and soil-specific runoff coefficients are applied to distribute
the predicted basin flows across different landscape types within each
basin.

##### 4. Load Calculation

Pollutant loads are estimated using Event Mean Concentrations (EMCs) for
different land use categories, calculating:

- Total Nitrogen (TN) loads
- Total Phosphorus (TP) loads  
- Total Suspended Solids (TSS) loads
- Biochemical Oxygen Demand (BOD) loads
- Stormwater-specific loads (with different EMCs for certain categories)

The fundamental equation for pollutant load estimation is:

**Load = Flow × EMC × Unit Conversions**

Where EMCs (Event Mean Concentrations) represent the average pollutant
concentrations in stormwater runoff for different land use types. EMCs
vary by land use category (CLUCSID) based on empirical studies of
stormwater quality. Special handling is applied for water bodies and
certain wetland types (CLUCSIDs 18, 20), which are assigned zero
stormwater loads since these areas do not generate surface runoff in the
same manner as terrestrial land uses.

All together, the above can be implemented as follows. Flow inputs (as
cubic feet per second) to
[`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md)
can be provided numerous ways:

1.  Flow data provided using local files for Lake Manatee, Bell Shoals,
    and Tampa Bypass, USGS data retrieved automatically from the API
2.  Flow data provided using local files for Lake Manatee, Bell Shoals,
    and Tampa Bypass, USGS data provided locally using the `usgsflow`
    argument (see the
    [`usgsflow`](https://tbep-tech.github.io/tbeploads/reference/usgsflow.md)
    dataset for the format, created using
    [`util_nps_getusgsflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md))
3.  All flow data provided locally using the `allflo` argument (see the
    [`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
    dataset for the format, created using
    [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)).

In all cases, input data can retrieved from APIs with the exception of
flow data for Lake Manatee, Bell Shoals, and Tampa Bypass (see the help
file for
[`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md)
for how to get these data). The following example uses combined flow
data included with the package for convenience. See above for how to
create the
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md)
and [`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md)
data objects if updated data are needed.

``` r
# required inputs
data(tbbase)
data(rain)
data(allflo)

nps_ungaged <- anlz_nps_ungaged(yrrng = c('2021-01-01', '2023-12-31'), tbbase = tbbase, rain = rain, 
                                allflo = allflo)
#> Prepping rain data...
#> Estimating ungaged NPS loads...

head(nps_ungaged)
#> # A tibble: 6 × 12
#>   bay_seg basin     yr    mo clucsid h2oload tnload tpload tssload bodload  area
#>     <dbl> <chr>  <dbl> <dbl>   <dbl>   <dbl>  <dbl>  <dbl>   <dbl>   <dbl> <dbl>
#> 1       1 02306…  2021     1       1   7660.   14.6   2.40    137.    33.7  210.
#> 2       1 02306…  2021     1       2  59331.  133.   20.2    2156.   439.   971.
#> 3       1 02306…  2021     1       3 108248.  225.   39.9    6911.  1191.  1267.
#> 4       1 02306…  2021     1       4  81834.  159.   22.9    6765.  1408.   481.
#> 5       1 02306…  2021     1       5  58983.   96.6  15.8    5540.   566.   371.
#> 6       1 02306…  2021     1       7  27440.   32.4   4.12    549.   225.   281.
#> # ℹ 1 more variable: bas_area <dbl>
```

#### Combined gaged and ungaged loads

Refer to the prior sections for details on how the separate loads for
gaged and ungaged portions of the wateshed are calculated. The
[`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
function described below can be used to combine all steps. The function
estimates non-point source (NPS) loads for Tampa Bay by combining gaged
and ungaged NPS loads. Gaged loads are estimated using flow and water
quality data. Ungaged loads are estimated using rainfall, flow, event
mean concentration, land use, and soils data. The function also
incorporates atmospheric concentration data from the Verna Wellfield
site.

Pre-processed inputs for
[`tbbase`](https://tbep-tech.github.io/tbeploads/reference/tbbase.md),
[`rain`](https://tbep-tech.github.io/tbeploads/reference/rain.md),
[`allwq`](https://tbep-tech.github.io/tbeploads/reference/allwq.md), and
[`allflo`](https://tbep-tech.github.io/tbeploads/reference/allflo.md)
are used. See the help file for
[`util_prepverna()`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md)
for how to obtain the file for atmosopheric concentration data. See
above for how to recreate these files if updated data are needed.

``` r
data(tbbase)
data(rain)
data(allwq)
data(allflo)
vernafl <- system.file('extdata/verna-raw.csv', package = 'tbeploads')

nps <- anlz_nps(yrrng = c('2021-01-01', '2023-12-31'), tbbase = tbbase, rain = rain, 
                vernafl = vernafl, allwq = allwq, allflo = allflo)
#> Estimating ungaged NPS loads...
#> Estimating gaged NPS loads...
#> Combining atmospheric data with ungaged NPS loads...
#> Combining ungaged and gaged NPS loads, estimating final...

head(nps)
#> # A tibble: 6 × 10
#>    Year Month source segment     basin tn_load tp_load tss_load bod_load hy_load
#>   <dbl> <dbl> <chr>  <chr>       <chr>   <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#> 1  2021     1 NPS    Boca Ciega… 207-5    2.43   0.398     80.8    14.5   1.22e6
#> 2  2021     2 NPS    Boca Ciega… 207-5    1.66   0.272     55.3     9.94  8.34e5
#> 3  2021     3 NPS    Boca Ciega… 207-5    1.37   0.225     45.6     8.21  6.89e5
#> 4  2021     4 NPS    Boca Ciega… 207-5    1.58   0.259     52.6     9.46  7.94e5
#> 5  2021     5 NPS    Boca Ciega… 207-5    1.20   0.197     40.1     7.20  6.04e5
#> 6  2021     6 NPS    Boca Ciega… 207-5    2.66   0.435     88.4    15.9   1.33e6
```

Unlike the individual gaged and ungaged functions,
[`anlz_nps()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps.md)
returns loading results in tons per month or year depending on the
summary arguments. Hydrologic load is returned as million cubic meters
per month or year.

The following functions are used internally and are provided here for
reference on the components used in the calculations. Not all are used
depending on the inputs provided.

- [`anlz_nps_ungaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md):
  Estimates ungaged NPS loads.
- [`anlz_nps_gaged()`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md):
  Estimates gaged NPS loads.
- [`util_nps_fillmiswq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_fillmiswq.md):
  Fills missing water quality data with linear interpolation.
- [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md):
  Gets flow estimates for NPS gaged and ungaged calculations.
- [`util_nps_getusgsflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md):
  Gets USGS flow data for NPS calculations, used in
  [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md).
- [`util_nps_getextflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md):
  Gets external flow data (Lake Manatee, Tampa Bypass, and Bell Shoals),
  used in
  [`util_nps_getflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md).
- [`util_nps_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getwq.md):
  Gets water quality data for NPS gaged calculations.
- [`util_nps_preprain()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_preprain.md):
  Prepares and formats rainfall data.
- [`util_nps_preplog()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_preplog.md):
  Prepares land use data for logistic regression modeling.
- [`util_nps_segment()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_segment.md):
  Assigns basins to bay segments.
- [`util_prepverna()`](https://tbep-tech.github.io/tbeploads/reference/util_prepverna.md):
  Prepares and fills missing data with five-year means for the Verna
  Wellfield site data.

Results can be summarized by basin, segment, baywide, monthly, or
annually using the `summ` and `summtime` arguments. By default, loads
are returned monthly for each basin. Note that Boca Ciega Bay and Boca
Ciega Bay South results are returned separately. Only Boca Ciega Bay
South is used when estimating total bay loads.

Loads by land use type (using CLUCSID) can also be returned if
`aslu = TRUE`. These results only apply to ungaged loading estimates.

``` r
npslu <- anlz_nps(yrrng = c('2021-01-01', '2023-12-31'), tbbase = tbbase, rain = rain, 
                allwq = allwq, allflo = allflo, vernafl = vernafl, aslu = TRUE)
#> Estimating ungaged NPS loads...
#> Combining atmospheric data with ungaged NPS loads...
#> Summarizing ungaged NPS loads by land use...
                
head(npslu)
#> # A tibble: 6 × 11
#>    Year Month source segment       basin lu    tn_load tp_load tss_load bod_load
#>   <dbl> <dbl> <chr>  <chr>         <chr> <chr>   <dbl>   <dbl>    <dbl>    <dbl>
#> 1  2021     1 NPS    Boca Ciega B… 207-5 Barr… 7.11e-5 5.74e-7 0.000631  8.32e-5
#> 2  2021     2 NPS    Boca Ciega B… 207-5 Barr… 4.86e-5 3.92e-7 0.000431  5.69e-5
#> 3  2021     3 NPS    Boca Ciega B… 207-5 Barr… 4.02e-5 3.24e-7 0.000356  4.70e-5
#> 4  2021     4 NPS    Boca Ciega B… 207-5 Barr… 4.63e-5 3.73e-7 0.000411  5.41e-5
#> 5  2021     5 NPS    Boca Ciega B… 207-5 Barr… 3.52e-5 2.84e-7 0.000313  4.12e-5
#> 6  2021     6 NPS    Boca Ciega B… 207-5 Barr… 7.78e-5 6.27e-7 0.000690  9.10e-5
#> # ℹ 1 more variable: hy_load <dbl>
```
