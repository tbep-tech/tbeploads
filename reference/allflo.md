# Data frame of all flow data used in [`anlz_nps_gaged`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md) and [`anlz_nps_ungaged`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md)

Data frame of all flow data used in
[`anlz_nps_gaged`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_gaged.md)
and
[`anlz_nps_ungaged`](https://tbep-tech.github.io/tbeploads/reference/anlz_nps_ungaged.md)

## Usage

``` r
allflo
```

## Format

A `data.frame` of monthly mean daily flow data for select basins

## Details

Monthly flow data at select stations used for estimating non-point
source gaged and ungaged loads. Created using the
[`util_nps_getflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)
function. Includes data from the USGS API using
[`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md)
and from external sources using
[`util_nps_getextflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md).
The data frame contains the following columns:

- `basin`: Character string for the basin or gauge location

- `yr`: Year of the observation

- `mo`: Month of the observation

- `flow_cfs`: Numeric value for the average daily flow in cubic feet per
  second (cfs)

## See also

[`util_nps_getusgsflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getusgsflow.md),
[`util_nps_getextflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getextflow.md),
[`util_nps_getflow`](https://tbep-tech.github.io/tbeploads/reference/util_nps_getflow.md)

## Examples

``` r
allflo
#> # A tibble: 612 × 4
#>    basin       yr    mo flow_cfs
#>    <chr>    <dbl> <dbl>    <dbl>
#>  1 02299950  2021     1     18.7
#>  2 02299950  2021     2     41.9
#>  3 02299950  2021     3     17.1
#>  4 02299950  2021     4     73.7
#>  5 02299950  2021     5      6.8
#>  6 02299950  2021     6     18.7
#>  7 02299950  2021     7    362. 
#>  8 02299950  2021     8    132. 
#>  9 02299950  2021     9    317. 
#> 10 02299950  2021    10     64.7
#> # ℹ 602 more rows
```
