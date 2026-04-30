# Springs (SPR)

``` r

library(tbeploads)
```

Spring loads to Tampa Bay are estimated for three major springs that all
discharge to Hillsborough Bay (bay segment 2): Lithia Springs, Buckhorn
Springs, and Sulphur Springs. The
[`anlz_spr()`](https://tbep-tech.github.io/tbeploads/reference/anlz_spr.md)
function is used for these calculations.

## Input data

One required input file (TBW discharge workbook) is needed, plus
optional arguments for water quality and Sulphur Spring discharge.

**Discharge (Lithia and Buckhorn):** Daily flow records for Lithia and
Buckhorn springs are collected by Tampa Bay Water (TBW) and provided as
an Excel workbook with one sheet per device. Four device IDs are used:
3381 (Lithia Minor), 4586 (Lithia Major), 3388 (Buckhorn Upper), and
3649 (Buckhorn Lower). Lithia total flow is the sum of Minor and Major.
Buckhorn total flow is Lower minus Upper, because the two gauges bracket
the same stream reach. A copy of the 2022-2024 file is included with the
package and located using
[`system.file()`](https://rdrr.io/r/base/system.file.html):

``` r

tbwxlpth <- system.file('extdata/sprflow2224.xlsx', package = 'tbeploads')
```

**Spring water quality (TN and TP, local file):** Sample concentrations
(mg/L) for total nitrogen and total phosphorus can be supplied as a CSV
with one row per sample via the `wqpth` argument. These data are from
FDEP’s Impaired Waters Rule dataset available at
<https://publicfiles.dep.state.fl.us/dear/iwr/>. Annual means are
computed per spring before joining to the monthly flow estimates. A
spring-year is considered complete when its samples span all four
calendar quarters (Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec). Spring-years
that are entirely missing or that do not cover all four quarters are
filled by carrying forward the most recent complete year’s mean. For
this reason, the file should include data from years prior to the focal
reporting period (i.e., not just the current year) so that every spring
has at least one complete reference year available. If the file only
contains a single year of data that is itself incomplete for a spring,
concentrations for that spring will be `NA` and an error is returned.
The example 2022-2024 file included with the package is:

``` r

wqpth <- system.file('extdata/sprwq2224.csv', package = 'tbeploads')
```

**Spring water quality (TN and TP, API):** When `wqpth = NULL` (the
default), water quality data are retrieved automatically from two
external APIs via
[`util_spr_getwq()`](https://tbep-tech.github.io/tbeploads/reference/util_spr_getwq.md):

- **Lithia and Buckhorn** concentrations are obtained from the [Water
  Atlas API](https://dev.api.wateratlas.org)
  (`GET /api/samplingdata/stream`), using SWFWMD monitoring stations
  17805 (Lithia Main Spring, water body ID 4000510) and 18276 (Buckhorn
  Main Spring, water body ID 4000529) from the `WIN_21FLSWFD` data
  source. These are probably the same quarterly SWFWMD observations in
  the FDEP IWR file.
- **Sulphur** concentrations are retrieved via
  [`tbeptools::read_importepc()`](https://rdrr.io/pkg/tbeptools/man/read_importepc.html),
  which downloads the Environmental Protection Commission of
  Hillsborough County (EPC) monitoring spreadsheet and filters to
  station 174. This source provides monthly TN and TP observations.

**TSS concentrations:** When `wqpth` is supplied, TSS concentrations are
always assigned from a fixed lookup table derived from the historical
SAS-based loading model (SPRMOD2): 4.4 mg/L for Sulphur Springs and 4.0
mg/L for Lithia and Buckhorn. When `wqpth = NULL`, TSS values from the
API or EPC source are used where available (Sulphur Spring via EPC may
have periodic observations). Any spring-year combination with no
measured TSS falls back to the same fixed values.

**BOD concentrations:** BOD loads are returned as zero because BOD is
not measured at the springs.

**Sulphur Spring discharge (USGS):** Daily discharge for USGS station
02306000 is retrieved from the NWIS API via
[`util_nps_getusgsflow()`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md).
A data frame can also be passed to the `sulphurflow` argument to avoid a
repeat API call.

## Estimating spring loads

Calling
[`anlz_spr()`](https://tbep-tech.github.io/tbeploads/reference/anlz_spr.md)
with a local water quality file returns monthly loads for each spring.
The discharge record is linearly interpolated to fill any gaps before
monthly means are computed, since springs are assumed to have continuous
(non-zero) flow.

``` r

spr <- anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024))

head(spr)
#> # A tibble: 6 × 10
#>    Year Month source segment    spring tn_load tp_load tss_load bod_load hy_load
#>   <dbl> <dbl> <chr>  <chr>      <chr>    <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#> 1  2022     1 SPR    Hillsboro… Buckh…    1.75  0.0370     3.10        0   0.703
#> 2  2022     2 SPR    Hillsboro… Buckh…    2.01  0.0425     3.56        0   0.807
#> 3  2022     3 SPR    Hillsboro… Buckh…    1.86  0.0395     3.30        0   0.750
#> 4  2022     4 SPR    Hillsboro… Buckh…    1.84  0.0389     3.26        0   0.739
#> 5  2022     5 SPR    Hillsboro… Buckh…    1.47  0.0311     2.60        0   0.590
#> 6  2022     6 SPR    Hillsboro… Buckh…    1.66  0.0351     2.94        0   0.666
```

When `wqpth` is omitted, water quality is fetched automatically from the
Water Atlas API (Lithia, Buckhorn) and EPC via `tbeptools` (Sulphur):

``` r

# Requires internet access; water quality retrieved from APIs
spr_api <- anlz_spr(tbwxlpth = tbwxlpth, yrrng = c(2022, 2024))
```

Load columns are in tons/month and `hy_load` is in 1e6 m³/month.

## Spatial summary

The `summ` argument controls the level of spatial aggregation.

`summ = 'spring'` (default) returns one row per spring per time period.

`summ = 'basin'` sums loads within drainage basins. Lithia and Buckhorn
are both assigned to the Alafia River basin and Sulphur is assigned to
the Hillsborough River basin as shown with the `majbasin` column.

``` r

anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024),
         summ = 'basin', summtime = 'month')
#> # A tibble: 72 × 10
#>     Year Month source segment        majbasin tn_load  tp_load tss_load bod_load
#>    <dbl> <dbl> <chr>  <chr>          <chr>      <dbl>    <dbl>    <dbl>    <dbl>
#>  1  2022     1 SPR    Hillsborough … Alafia … 1.08e+1 0.297     19.2           0
#>  2  2022     1 SPR    Hillsborough … Hillsbo… 3.25e-1 0.135      7.97          0
#>  3  2022     2 SPR    Hillsborough … Alafia … 1.03e+1 0.279     18.1           0
#>  4  2022     2 SPR    Hillsborough … Hillsbo… 1.43e-1 0.0593     3.51          0
#>  5  2022     3 SPR    Hillsborough … Alafia … 8.75e+0 0.236     15.5           0
#>  6  2022     3 SPR    Hillsborough … Hillsbo… 1.94e-3 0.000804   0.0476        0
#>  7  2022     4 SPR    Hillsborough … Alafia … 9.47e+0 0.257     16.7           0
#>  8  2022     4 SPR    Hillsborough … Hillsbo… 2.42e-1 0.1000     5.92          0
#>  9  2022     5 SPR    Hillsborough … Alafia … 8.38e+0 0.229     14.8           0
#> 10  2022     5 SPR    Hillsborough … Hillsbo… 7.86e-2 0.0325     1.92          0
#> # ℹ 62 more rows
#> # ℹ 1 more variable: hy_load <dbl>
```

`summ = 'segment'` sums all three springs to the single bay segment
(segment 2, Hillsborough Bay).

``` r

anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024),
         summ = 'segment', summtime = 'month')
#> # A tibble: 36 × 9
#>     Year Month source segment          tn_load tp_load tss_load bod_load hy_load
#>    <dbl> <dbl> <chr>  <chr>              <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#>  1  2022     1 SPR    Hillsborough Bay   11.2    0.432     27.1        0    5.99
#>  2  2022     2 SPR    Hillsborough Bay   10.4    0.338     21.7        0    4.84
#>  3  2022     3 SPR    Hillsborough Bay    8.75   0.237     15.5        0    3.52
#>  4  2022     4 SPR    Hillsborough Bay    9.71   0.357     22.7        0    5.02
#>  5  2022     5 SPR    Hillsborough Bay    8.45   0.261     16.7        0    3.75
#>  6  2022     6 SPR    Hillsborough Bay    9.51   0.294     18.9        0    4.23
#>  7  2022     7 SPR    Hillsborough Bay   10.7    0.404     25.4        0    5.62
#>  8  2022     8 SPR    Hillsborough Bay   11.7    0.479     30.0        0    6.61
#>  9  2022     9 SPR    Hillsborough Bay   12.1    0.510     31.9        0    7.01
#> 10  2022    10 SPR    Hillsborough Bay   12.9    0.539     33.9        0    7.44
#> # ℹ 26 more rows
```

## Temporal summary

The `summtime` argument works across all three spatial levels. Setting
`summtime = 'year'` sums load columns over months.

``` r

# Annual segment totals
anlz_spr(tbwxlpth = tbwxlpth, wqpth = wqpth, yrrng = c(2022, 2024),
         summ = 'segment', summtime = 'year')
#> # A tibble: 3 × 8
#>    Year source segment          tn_load tp_load tss_load bod_load hy_load
#>   <dbl> <chr>  <chr>              <dbl>   <dbl>    <dbl>    <dbl>   <dbl>
#> 1  2022 SPR    Hillsborough Bay    132.    4.93     311.        0    68.9
#> 2  2023 SPR    Hillsborough Bay    123.    5.22     274.        0    61.0
#> 3  2024 SPR    Hillsborough Bay    133.    6.79     332.        0    73.3
```
